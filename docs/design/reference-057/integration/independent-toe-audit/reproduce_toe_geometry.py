#!/usr/bin/env python3
"""Reproduce a historical real boot-floor failure from original GLB and trace.

This is a new, independent mathematical execution. It does not run Godot,
change a game source, or claim that the historical pre-fix trace is current.
"""
from __future__ import annotations

import argparse
import collections
import datetime
import hashlib
import json
import math
from pathlib import Path
import struct

import numpy as np


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--glb", required=True, type=Path)
    parser.add_argument("--trace", required=True, type=Path)
    args = parser.parse_args()

    raw = args.glb.read_bytes()
    json_size, _ = struct.unpack_from("<II", raw, 12)
    document = json.loads(raw[20:20 + json_size])
    binary_offset = 20 + json_size
    binary_size, _ = struct.unpack_from("<II", raw, binary_offset)
    binary = raw[binary_offset + 8:binary_offset + 8 + binary_size]
    nodes = document["nodes"]

    def array(index: int) -> np.ndarray:
        accessor = document["accessors"][index]
        view = document["bufferViews"][accessor["bufferView"]]
        components = {"MAT4": 16, "VEC4": 4, "VEC3": 3, "VEC2": 2, "SCALAR": 1}[accessor["type"]]
        dtype = np.dtype({5126: "<f4", 5125: "<u4", 5123: "<u2", 5121: "u1"}[accessor["componentType"]])
        return np.ndarray(
            (accessor["count"], components), dtype=dtype, buffer=binary,
            offset=view.get("byteOffset", 0) + accessor.get("byteOffset", 0),
            strides=(view.get("byteStride", components * dtype.itemsize), dtype.itemsize),
        ).copy()

    line = next(
        value for value in args.trace.read_text().splitlines()
        if value.startswith("NATIVE_WALK_WORST guardian_0 ")
    )
    historical = json.loads(line.split(" ", 2)[2])
    poses = {}
    for name, record in historical["source_named_poses"].items():
        transform = np.eye(4)
        transform[:3, :3] = np.array([record["basis_x"], record["basis_y"], record["basis_z"]]).T
        transform[:3, 3] = record["origin"]
        poses[name] = transform

    source_height_m = 1.810080
    guardian_height_m = 4.6
    uniform_scale = guardian_height_m / source_height_m
    probe_count = 0
    influence_vertex_counts = collections.Counter()
    records = []
    excluded_missing_pose = []
    for node in nodes:
        if "mesh" not in node or "Feet" not in node.get("name", ""):
            continue
        assert not any(name in node for name in ("matrix", "translation", "rotation", "scale")), "Boot mesh has original identity node transform"
        skin = document["skins"][node["skin"]]
        joints = skin["joints"]
        inverse_binds = array(skin["inverseBindMatrices"]).reshape(-1, 4, 4).transpose(0, 2, 1)
        for slot, primitive in enumerate(document["meshes"][node["mesh"]]["primitives"]):
            attributes = primitive["attributes"]
            positions = array(attributes["POSITION"])
            ids = array(attributes["JOINTS_0"])
            weights = array(attributes["WEIGHTS_0"])
            used = np.unique(array(primitive["indices"]))
            probes = used[positions[used, 1] < .055]
            for index in probes:
                probe_count += 1
                vertex = np.r_[positions[index], 1.]
                influences = []
                point = np.zeros(4)
                missing_pose = []
                for joint, weight in zip(ids[index], weights[index]):
                    if weight <= 0:
                        continue
                    name = nodes[joints[joint]]["name"]
                    influence_vertex_counts[name] += 1
                    if name not in poses:
                        missing_pose.append(name)
                        continue
                    local = inverse_binds[joint] @ vertex
                    contribution = poses[name] @ local * weight
                    point += contribution
                    influences.append({
                        "bone": name, "weight": float(weight),
                        "joint_local": local[:3].tolist(),
                        "source_y_contribution": float(contribution[1]),
                    })
                if missing_pose:
                    excluded_missing_pose.append({"original_glb_vertex": int(index), "bones": missing_pose})
                    continue
                if not any(value["bone"].endswith("_l") for value in influences):
                    continue
                world_y = (point[1] + historical["motion_y"]) * uniform_scale
                records.append({
                    "mesh_node": node["name"], "slot": slot,
                    "original_glb_vertex": int(index), "rest_position": positions[index].tolist(),
                    "source_y": float(point[1]), "world_y": float(world_y),
                    "influences": influences,
                })
    records.sort(key=lambda value: value["world_y"])
    lowest = records[0]
    assert lowest["original_glb_vertex"] == 177
    assert len(lowest["influences"]) == 1 and lowest["influences"][0]["bone"] == "ball_l" and lowest["influences"][0]["weight"] == 1.0
    discrepancy = abs(lowest["world_y"] - historical["min_loaded_world_y"])
    assert discrepancy < 1e-8

    ball_node = next(index for index, node in enumerate(nodes) if node.get("name") == "ball_l")
    ball_parent = next(index for index, node in enumerate(nodes) if ball_node in node.get("children", []))
    assert nodes[ball_parent]["name"] == "foot_l"
    current_ball_local = np.linalg.inv(poses["foot_l"]) @ poses["ball_l"]

    def quaternion_basis(quaternion: list[float]) -> np.ndarray:
        x, y, z, w = quaternion
        return np.array([
            [1 - 2 * (y*y + z*z), 2 * (x*y - z*w), 2 * (x*z + y*w)],
            [2 * (x*y + z*w), 1 - 2 * (x*x + z*z), 2 * (y*z - x*w)],
            [2 * (x*z - y*w), 2 * (y*z + x*w), 1 - 2 * (x*x + y*y)],
        ])

    original_ball_local = np.eye(4)
    original_ball_local[:3, :3] = quaternion_basis(nodes[ball_node]["rotation"])
    original_ball_local[:3, 3] = nodes[ball_node]["translation"]
    original_ball_rest_world = poses["foot_l"] @ original_ball_local
    counterfactual_minima = []
    for record in records:
        source_y = 0.0
        for influence in record["influences"]:
            pose = original_ball_rest_world if influence["bone"] == "ball_l" else poses[influence["bone"]]
            source_y += float((pose @ np.r_[influence["joint_local"], 1.])[1]) * influence["weight"]
        counterfactual_minima.append((source_y + historical["motion_y"]) * uniform_scale)

    walk = next(animation for animation in document["animations"] if animation["name"] == "Walk_Loop")
    toe_curves = []
    for channel in walk["channels"]:
        name = nodes[channel["target"]["node"]]["name"]
        if not name.startswith("ball") or channel["target"]["path"] != "rotation":
            continue
        sampler = walk["samplers"][channel["sampler"]]
        values = array(sampler["output"])
        times = array(sampler["input"]).ravel()
        rest_rotation = np.array(nodes[channel["target"]["node"]]["rotation"])
        rest_rotation /= np.linalg.norm(rest_rotation)
        rotations = values / np.linalg.norm(values, axis=1)[:, None]
        angles = 2 * np.arccos(np.clip(np.abs(rotations @ rest_rotation), 0, 1))
        maximum = int(np.argmax(angles))
        selected = []
        for target in (.6333333, .8333333):
            index = int(np.argmin(abs(times - target)))
            selected.append({"original_key_time": float(times[index]), "rest_delta_degrees": math.degrees(float(angles[index])), "original_xyzw": values[index].tolist()})
        toe_curves.append({
            "bone": name, "keys": len(times), "interpolation": sampler.get("interpolation", "LINEAR"),
            "largest_rest_delta_degrees": math.degrees(float(angles[maximum])),
            "largest_delta_key_time": float(times[maximum]), "selected_original_keys": selected,
        })

    print(json.dumps({
        "schema": 1, "analysis_executed_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "scope": "New independent mathematical reproduction of historical pre-toe-lock Engine trace; no Godot invocation and no current post-fix runtime claim",
        "inputs": {
            "original_glb": {"path": str(args.glb.resolve()), "sha256": sha256(args.glb)},
            "historical_engine_trace": {"path": str(args.trace.resolve()), "sha256": sha256(args.trace)},
            "reproduction_script": {"path": str(Path(__file__).resolve()), "sha256": sha256(Path(__file__))},
        },
        "historical_trace_frame": historical["frame"], "historical_trace_gait_phase": historical["gait_phase"],
        "historical_trace_world_min_y": historical["min_loaded_world_y"],
        "guardian_height_m": guardian_height_m, "original_source_height_m": source_height_m,
        "uniform_scale": uniform_scale, "historical_motion_y": historical["motion_y"],
        "source_indexed_boot_probes": probe_count,
        "nonzero_influence_vertex_counts": dict(influence_vertex_counts),
        "excluded_probes_with_unlogged_root_pose": excluded_missing_pose,
        "lowest_five_original_left_boot_vertices": records[:5],
        "worst_vertex_reproduction_absolute_error_m": discrepancy,
        "ball_l_current_local_at_historical_worst_frame": current_ball_local.tolist(),
        "ball_l_original_rest_local": original_ball_local.tolist(),
        "maximum_component_difference_current_ball_local_vs_rest": float(np.abs(current_ball_local - original_ball_local).max()),
        "counterfactual_same_fixed_foot_and_calf_with_ball_rest_local_min_y": min(counterfactual_minima),
        "original_walk_toe_rotation_curves": toe_curves,
        "interpretation": "A fixed foot transform does not fix 100%-ball-weighted toe sole vertices while original Walk_Loop continues to animate ball_l locally; preserve actual touchdown toe orientation only for the planted support side. This calculation does not fabricate the touchdown event or replace a post-fix runtime test.",
    }, indent=2))


if __name__ == "__main__":
    main()
