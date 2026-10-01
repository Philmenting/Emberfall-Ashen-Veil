"use strict";

const assert = require("node:assert/strict");
const { createHash } = require("node:crypto");
const fs = require("node:fs");
const vm = require("node:vm");

let nowSeconds = 1_800_000_000;
let secureSeedSerial = 0;
const database = new Map();
const rpc = {};

class TestDate extends Date {
	static now() { return nowSeconds * 1000; }
}

const nk = {
	secureRandomBytes(count) {
		secureSeedSerial += 1;
		const bytes = new Uint8Array(count);
		for (let index = 0; index < count; index += 1) bytes[index] = (secureSeedSerial * 31 + index * 17) & 255;
		return bytes.buffer;
	},
	sha256Hash(value) { return createHash("sha256").update(value, "utf8").digest("hex"); },
	storageRead(requests) {
		return requests.flatMap((request) => {
			const row = database.get(storageKey(request.userId, request.collection, request.key));
			return row ? [{ value: structuredClone(row.value), version: row.version }] : [];
		});
	},
	storageWrite(requests) {
		const acknowledgements = [];
		for (const request of requests) {
			const key = storageKey(request.userId, request.collection, request.key);
			const current = database.get(key);
			const conditional = request.version && request.version !== "*";
			if (conditional && (!current || request.version !== current.version)) throw new Error("Storage version conflict.");
			const version = String(current ? Number(current.version) + 1 : 1);
			database.set(key, { value: structuredClone(request.value), version, permissionRead: request.permissionRead, permissionWrite: request.permissionWrite });
			acknowledgements.push({ version });
		}
		return acknowledgements;
	},
};

function storageKey(userId, collection, key) { return `${userId}:${collection}:${key}`; }

const context = vm.createContext({ Date: TestDate, JSON, Math, Object, Array, String, Number, isFinite, Error, console, nk });
vm.runInContext(fs.readFileSync("server/modules/emberfall.js", "utf8"), context);
context.InitModule({}, { info() {} }, nk, { registerRpc(id, fn) { rpc[id] = fn; } });

function call(id, userId, payload = {}) {
	assert.equal(typeof rpc[id], "function", `${id} is registered`);
	return JSON.parse(rpc[id]({ userId }, {}, nk, JSON.stringify(payload)));
}

const initial = call("emberfall_progression_sync", "alpha");
assert.equal(initial.ok, true);
assert.equal(initial.profile.schema, 1);
assert.equal(initial.profile.gold, 600);
assert.equal(initial.profile.highest_floor, 1);
assert.equal(Object.keys(initial.profile.equipment).length, 6);
assert.equal(initial.settlement.runs, 0);

const stored = database.get(storageKey("alpha", "emberfall", "server_progression"));
assert.equal(stored.permissionRead, 1);
assert.equal(stored.permissionWrite, 0, "clients receive owner-read/server-write storage permissions");

const attemptedInjection = call("emberfall_progression_sync", "alpha", { gold: 2_000_000_000, wins: 999999, farm_floor: 999999, elapsed_seconds: 86400, success: true, rarity: "LEGENDARY" });
assert.equal(attemptedInjection.profile.gold, 600, "sync ignores client supplied currency and progression");
assert.equal(attemptedInjection.profile.highest_floor, 1, "sync ignores client supplied floor unlocks");
assert.equal(attemptedInjection.settlement.runs, 0, "sync ignores client supplied time, outcome, and drop quality");

const lockedFloor = call("emberfall_progression_farm", "alpha", { farm_floor: 2, farm_enabled: true });
assert.equal(lockedFloor.ok, false, "future floor selection is rejected");
assert.equal(lockedFloor.profile.farm_floor, 1);

const classChange = call("emberfall_progression_class", "alpha", { class_name: "Arcanist" });
assert.equal(classChange.ok, true);
assert.equal(classChange.profile.class_name, "Arcanist", "server accepts a class choice from its allowlist");
assert.equal(call("emberfall_progression_class", "alpha", { class_name: "Hacker" }).ok, false);

call("emberfall_progression_farm", "alpha", { farm_floor: 1, farm_enabled: false });
nowSeconds += 3600;
const paused = call("emberfall_progression_sync", "alpha");
assert.equal(paused.settlement.runs, 0, "server farming toggle stops offline rewards");
assert.equal(paused.profile.gold, 600);

call("emberfall_progression_farm", "alpha", { farm_floor: 1, farm_enabled: true });
nowSeconds += 3600;
const randomSeedsBeforeSettlement = secureSeedSerial;
const settled = call("emberfall_progression_sync", "alpha");
assert.ok(settled.settlement.runs > 0, "server simulates time-based AFK runs");
assert.equal(secureSeedSerial - randomSeedsBeforeSettlement, settled.settlement.runs, "each settled run uses a fresh server-provided random seed");
assert.equal(settled.settlement.runs, settled.settlement.wins + settled.settlement.fails);
assert.equal(settled.settlement.elapsed_seconds, 3600);
assert.ok(settled.profile.gold >= 600 + settled.settlement.gold);
assert.ok(settled.profile.run_count >= settled.settlement.runs);
assert.ok(settled.profile.inventory.length <= 20, "server enforces the bag limit");
for (const item of settled.profile.inventory) {
	assert.ok(["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"].includes(item.quality));
	assert.ok(["Weapon", "Helmet", "Chest", "Gloves", "Boots", "Amulet"].includes(item.slot));
}

assert.equal(settled.profile.inventory.length, 20, "server fills but never exceeds the bag limit during offline rewards");
const candidate = settled.profile.inventory[0];
const displaced = settled.profile.equipment[candidate.slot];
const equipped = call("emberfall_progression_equip", "alpha", { item_id: candidate.id });
assert.equal(equipped.ok, true, "server equips an item it owns");
assert.equal(equipped.profile.equipment[candidate.slot].id, candidate.id);
assert.ok(equipped.profile.inventory.some((item) => item.id === displaced.id), "server returns the replaced item to the bag");

const goldBeforeSale = equipped.profile.gold;
const sold = call("emberfall_progression_sell", "alpha", { item_id: displaced.id });
assert.equal(sold.ok, true, "server sells an item it owns");
assert.equal(sold.profile.gold, goldBeforeSale + displaced.sell, "server chooses the sale value");
assert.equal(call("emberfall_progression_sell", "alpha", { item_id: "forged-item" }).ok, false, "server rejects an item that is not owned");

const temperBefore = sold.profile.equipment.Weapon;
const tempered = call("emberfall_progression_temper", "alpha", { slot: "Weapon" });
assert.equal(tempered.ok, true, "server tempers equipped gear after validating Gold");
assert.equal(tempered.profile.equipment.Weapon.power, temperBefore.power + 10);

const pointsBefore = tempered.profile.attribute_points;
const allocated = call("emberfall_progression_allocate", "alpha", { attribute: "Intellect", amount: 1000000 });
assert.equal(allocated.ok, true, "server allocates an available attribute point");
assert.equal(allocated.profile.attributes.Intellect, 1);
assert.equal(allocated.profile.attribute_points, pointsBefore - 1, "extra client-supplied amounts are ignored");

const replay = call("emberfall_progression_sync", "alpha");
assert.equal(replay.settlement.runs, 0, "replaying the same claim cannot award AFK runs twice");
assert.equal(secureSeedSerial, randomSeedsBeforeSettlement + settled.settlement.runs, "a replay with no elapsed time does not reroll rewards");
assert.equal(replay.profile.gold, allocated.profile.gold, "refresh does not revert validated server actions");

nowSeconds += 7 * 24 * 3600;
const capped = call("emberfall_progression_sync", "alpha");
assert.equal(capped.settlement.elapsed_seconds, 24 * 3600, "offline time is capped at 24 hours");
assert.ok(capped.settlement.runs <= Math.floor((24 * 3600 + 120) / 45));

const stranger = call("emberfall_progression_sync", "beta");
assert.equal(stranger.profile.gold, 600, "each authenticated account gets its own server profile");
assert.equal(stranger.profile.run_count, 0);

console.log("PROGRESSION RUNTIME: server-owned profile, bounded AFK settlement, allowlists, inventory and replay protection passed.");
