import bpy,json,argparse,sys
from pathlib import Path
parser=argparse.ArgumentParser(description='Create an editable conversion of the verified native65 GLB; not original artist source.')
parser.add_argument('--glb',type=Path,required=True)
parser.add_argument('--output-root',type=Path,required=True)
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
root=args.output_root.resolve();root.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(args.glb.resolve()))
armatures=[o for o in bpy.data.objects if o.type=='ARMATURE']
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
assert len(armatures)==1 and len(armatures[0].data.bones)==65
print("IMPORTED MESHES:",[(o.name,len(o.data.polygons)) for o in meshes])
meshes=[o for o in meshes if o.name in ["Eyebrows","Eyes","Nyra_Authored_Head","Nyra_Female_Peasant_Arms","Nyra_Female_Peasant_Body","Nyra_Female_Peasant_Feet","Nyra_Female_Peasant_Legs","Nyra_Hair_Buns"]]
assert len(meshes)==8
for mesh in meshes:
 assert all(all(abs(c)<100 for c in v.co) for v in mesh.data.vertices)
note=bpy.data.texts.new('SOURCE-AND-LICENSE.txt')
note.write('Editable conversion of the real Emberfall native65 GLB. Original authored geometry/maps: Quaternius, CC0 1.0. Not an original artist Blender source or a high-poly/bake source. Manufactured modular head and complete Female Peasant outfit, silver buns hair. Paid Source packages were not acquired. Runtime staff is attached separately by source_avatar_rig.gd. See assets/models/nyra052/README.md. Blender may represent bone axes differently from the original glTF; use the preserved original native65 GLB/assembly pipeline for verified game export.\n')
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(root/'nyra052-editable-conversion.blend'))
(root/'editable-conversion.json').write_text(json.dumps({'source':'assets/models/nyra052/arcanist.glb','meshes':len(meshes),'bones':len(armatures[0].data.bones),'packed':True,'original_artist_blend':False},indent=2))
