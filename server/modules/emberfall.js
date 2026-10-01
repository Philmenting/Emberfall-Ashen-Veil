// Emberfall server-owned progression prototype for Nakama's JavaScript runtime.
// This file intentionally uses ES5 syntax because Nakama executes it in Goja.

var PROFILE_COLLECTION = "emberfall";
var PROFILE_KEY = "server_progression";
var PROFILE_SCHEMA = 1;
var MAX_FLOOR = 100000;
var MAX_OFFLINE_SECONDS = 24 * 60 * 60;
var MAX_BAG_SIZE = 20;
var MAX_TEMPER_RANK = 5;
var GEAR_SLOTS = ["Weapon", "Helmet", "Chest", "Gloves", "Boots", "Amulet"];
var CLASSES = {
	"Vowkeeper": "Strength",
	"Arcanist": "Intellect",
	"Ranger": "Dexterity"
};
var QUALITY = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"];
var QUALITY_POWER = { "COMMON": 1.0, "UNCOMMON": 1.12, "RARE": 1.28, "EPIC": 1.52, "LEGENDARY": 1.88 };

function InitModule(ctx, logger, nk, initializer) {
	initializer.registerRpc("emberfall_progression_sync", progressionSyncRpc);
	initializer.registerRpc("emberfall_progression_farm", progressionFarmRpc);
	initializer.registerRpc("emberfall_progression_class", progressionClassRpc);
	initializer.registerRpc("emberfall_progression_allocate", progressionAllocateRpc);
	initializer.registerRpc("emberfall_progression_equip", progressionEquipRpc);
	initializer.registerRpc("emberfall_progression_sell", progressionSellRpc);
	initializer.registerRpc("emberfall_progression_temper", progressionTemperRpc);
	logger.info("Emberfall server-owned progression RPCs registered (schema %d).", PROFILE_SCHEMA);
}

function progressionSyncRpc(ctx, logger, nk, payload) {
	return withProfile(ctx, nk, payload, function(profile, request) {
		return { ok: true, profile: profile, settlement: request.settlement };
	});
}

function progressionFarmRpc(ctx, logger, nk, payload) {
	return withProfile(ctx, nk, payload, function(profile, request) {
		var floor = request.input.farm_floor;
		var enabled = request.input.farm_enabled;
		if (typeof floor !== "number" || floor % 1 !== 0 || floor < 1 || floor > profile.highest_floor || floor > MAX_FLOOR) {
			return { ok: false, error: "Choose a floor that this server profile has unlocked.", profile: profile, settlement: request.settlement };
		}
		if (typeof enabled !== "boolean") {
			return { ok: false, error: "A farming state is required.", profile: profile, settlement: request.settlement };
		}
		profile.farm_floor = floor;
		profile.farm_enabled = enabled;
		return { ok: true, profile: profile, settlement: request.settlement };
	});
}

function progressionClassRpc(ctx, logger, nk, payload) {
	return withProfile(ctx, nk, payload, function(profile, request) {
		var className = request.input.class_name;
		if (typeof className !== "string" || !Object.prototype.hasOwnProperty.call(CLASSES, className)) {
			return { ok: false, error: "That class is not available.", profile: profile, settlement: request.settlement };
		}
		profile.class_name = className;
		return { ok: true, profile: profile, settlement: request.settlement };
	});
}

function progressionAllocateRpc(ctx, logger, nk, payload) {
	return withProfile(ctx, nk, payload, function(profile, request) {
		var attribute = request.input.attribute;
		if (typeof attribute !== "string" || ["Strength", "Dexterity", "Intellect", "Vitality", "Spirit"].indexOf(attribute) < 0) {
			return { ok: false, error: "That attribute is not available.", profile: profile, settlement: request.settlement };
		}
		if (profile.attribute_points < 1) {
			return { ok: false, error: "No attribute points are available.", profile: profile, settlement: request.settlement };
		}
		profile.attributes[attribute] += 1;
		profile.attribute_points -= 1;
		return { ok: true, profile: profile, settlement: request.settlement };
	});
}

function progressionEquipRpc(ctx, logger, nk, payload) {
	return withProfile(ctx, nk, payload, function(profile, request) {
		var itemId = request.input.item_id;
		var index = findItem(profile.inventory, itemId);
		if (index < 0) return { ok: false, error: "That item is not in the server bag.", profile: profile, settlement: request.settlement };
		var item = profile.inventory[index];
		var oldItem = profile.equipment[item.slot];
		profile.inventory.splice(index, 1);
		profile.inventory.push(oldItem);
		profile.equipment[item.slot] = item;
		return { ok: true, profile: profile, settlement: request.settlement };
	});
}

function progressionSellRpc(ctx, logger, nk, payload) {
	return withProfile(ctx, nk, payload, function(profile, request) {
		var index = findItem(profile.inventory, request.input.item_id);
		if (index < 0) return { ok: false, error: "That item is not in the server bag.", profile: profile, settlement: request.settlement };
		var item = profile.inventory.splice(index, 1)[0];
		profile.gold += item.sell;
		return { ok: true, profile: profile, settlement: request.settlement, sold_gold: item.sell };
	});
}

function progressionTemperRpc(ctx, logger, nk, payload) {
	return withProfile(ctx, nk, payload, function(profile, request) {
		var slot = request.input.slot;
		if (typeof slot !== "string" || GEAR_SLOTS.indexOf(slot) < 0) {
			return { ok: false, error: "That equipment slot is not available.", profile: profile, settlement: request.settlement };
		}
		var item = profile.equipment[slot];
		var rank = item.temper || 0;
		var cost = 90 + item.tier * 80 + rank * 120;
		if (rank >= MAX_TEMPER_RANK) return { ok: false, error: "This item has reached its temper limit.", profile: profile, settlement: request.settlement };
		if (profile.gold < cost) return { ok: false, error: "Not enough Gold to temper this item.", profile: profile, settlement: request.settlement };
		profile.gold -= cost;
		item.temper = rank + 1;
		item.power += 8 + item.tier * 2;
		if (["Helmet", "Chest", "Gloves", "Boots"].indexOf(slot) >= 0) {
			item.armor += 5 + item.tier * 2;
			item.stats.Vitality += 1;
		} else {
			var primary = CLASSES[profile.class_name];
			item.stats[primary] = (item.stats[primary] || 0) + 1;
		}
		item.sell += Math.floor(cost * 0.2);
		return { ok: true, profile: profile, settlement: request.settlement, temper_cost: cost };
	});
}

function withProfile(ctx, nk, payload, operation) {
	if (!ctx || typeof ctx.userId !== "string" || ctx.userId.length < 1) {
		return JSON.stringify({ ok: false, error: "An authenticated player account is required." });
	}
	var input = {};
	if (payload) {
		try { input = JSON.parse(payload); } catch (error) { return JSON.stringify({ ok: false, error: "The request is not valid JSON." }); }
	}
	if (!input || typeof input !== "object" || Array.isArray(input)) {
		return JSON.stringify({ ok: false, error: "The request must be an object." });
	}
	var loaded = readProfile(nk, ctx.userId);
	var profile = loaded.profile;
	var now = Math.floor(Date.now() / 1000);
	var settlement = settleOffline(profile, now, nk);
	var result = operation(profile, { input: input, settlement: settlement });
	if (loaded.created || settlement.elapsed_seconds > 0 || result.ok) {
		writeProfile(nk, ctx.userId, profile, loaded.version);
	}
	result.profile = publicProfile(profile);
	return JSON.stringify(result);
}

function readProfile(nk, userId) {
	var rows = nk.storageRead([{ collection: PROFILE_COLLECTION, key: PROFILE_KEY, userId: userId }]);
	if (rows && rows.length > 0) {
		var row = rows[0];
		var parsed = row.value;
		if (typeof parsed === "string") parsed = JSON.parse(parsed);
		if (!parsed || parsed.schema !== PROFILE_SCHEMA) throw new Error("Unsupported Emberfall progression profile schema.");
		return { profile: normalizeProfile(parsed), version: row.version || "*", created: false };
	}
	var profile = createProfile(Math.floor(Date.now() / 1000));
	return { profile: profile, version: "*", created: true };
}

function writeProfile(nk, userId, profile, version) {
	nk.storageWrite([{
		collection: PROFILE_COLLECTION,
		key: PROFILE_KEY,
		userId: userId,
		value: profile,
		permissionRead: 1,
		permissionWrite: 0,
		version: version
	}]);
}

function createProfile(now) {
	var profile = {
		schema: PROFILE_SCHEMA,
		class_name: "Vowkeeper",
		gold: 600,
		level: 1,
		xp: 0,
		attribute_points: 2,
		attributes: { Strength: 0, Dexterity: 0, Intellect: 0, Vitality: 0, Spirit: 0 },
		highest_floor: 1,
		farm_floor: 1,
		farm_enabled: true,
		run_count: 0,
		wins: 0,
		fails: 0,
		item_serial: 0,
		inventory: [],
		equipment: {},
		last_settled_at: now,
		progress_seconds: 0
	};
	for (var i = 0; i < GEAR_SLOTS.length; i++) {
		var slot = GEAR_SLOTS[i];
		profile.equipment[slot] = createItem(profile, slot, 1, i === 1 ? "RARE" : "UNCOMMON", true);
	}
	return profile;
}

function normalizeProfile(profile) {
	profile.gold = boundedInt(profile.gold, 0, 2000000000, 600);
	profile.level = boundedInt(profile.level, 1, 100000, 1);
	profile.xp = boundedInt(profile.xp, 0, 2000000000, 0);
	profile.attribute_points = boundedInt(profile.attribute_points, 0, 2000000, 0);
	profile.highest_floor = boundedInt(profile.highest_floor, 1, MAX_FLOOR, 1);
	profile.farm_floor = boundedInt(profile.farm_floor, 1, profile.highest_floor, 1);
	profile.farm_enabled = profile.farm_enabled !== false;
	profile.run_count = boundedInt(profile.run_count, 0, 2000000000, 0);
	profile.wins = boundedInt(profile.wins, 0, 2000000000, 0);
	profile.fails = boundedInt(profile.fails, 0, 2000000000, 0);
	profile.item_serial = boundedInt(profile.item_serial, 0, 2000000000, 0);
	profile.last_settled_at = boundedInt(profile.last_settled_at, 0, 5000000000, 0);
	profile.progress_seconds = boundedInt(profile.progress_seconds, 0, 120, 0);
	if (!Object.prototype.hasOwnProperty.call(CLASSES, profile.class_name)) profile.class_name = "Vowkeeper";
	if (!profile.attributes || typeof profile.attributes !== "object") profile.attributes = {};
	var attrNames = ["Strength", "Dexterity", "Intellect", "Vitality", "Spirit"];
	for (var a = 0; a < attrNames.length; a++) profile.attributes[attrNames[a]] = boundedInt(profile.attributes[attrNames[a]], 0, 1000000, 0);
	if (!Array.isArray(profile.inventory)) profile.inventory = [];
	profile.inventory = profile.inventory.slice(0, MAX_BAG_SIZE);
	if (!profile.equipment || typeof profile.equipment !== "object") profile.equipment = {};
	for (var i = 0; i < GEAR_SLOTS.length; i++) {
		var slot = GEAR_SLOTS[i];
		if (!profile.equipment[slot] || typeof profile.equipment[slot] !== "object") {
			profile.equipment[slot] = createItem(profile, slot, itemTier(profile.highest_floor), "COMMON", true);
		}
	}
	return profile;
}

function settleOffline(profile, now, nk) {
	var previous = profile.last_settled_at;
	var elapsed = previous > 0 && now >= previous ? Math.min(now - previous, MAX_OFFLINE_SECONDS) : 0;
	var report = { elapsed_seconds: elapsed, runs: 0, wins: 0, fails: 0, gold: 0, xp: 0, items: 0, salvaged: 0 };
	if (profile.farm_enabled && elapsed > 0) {
		var available = elapsed + profile.progress_seconds;
		var duration = runDuration(profile.farm_floor);
		var runs = Math.floor(available / duration);
		profile.progress_seconds = available - runs * duration;
		for (var i = 0; i < runs; i++) {
			var outcome = simulateRun(profile, secureSeed(nk), nk);
			report.runs += 1;
			profile.run_count += 1;
			var gold = outcome.won ? 186 + profile.farm_floor * 4 : 55;
			var xp = outcome.won ? 420 + profile.farm_floor * 8 : 100;
			profile.gold += gold;
			profile.xp += xp;
			report.gold += gold;
			report.xp += xp;
			if (outcome.won) {
				profile.wins += 1;
				report.wins += 1;
				if (profile.farm_floor === profile.highest_floor && profile.highest_floor < MAX_FLOOR) profile.highest_floor += 1;
				var created = awardLoot(profile, outcome.seed, nk);
				report.items += created.items;
				report.salvaged += created.salvaged;
				profile.gold += created.overflow_gold;
				report.gold += created.overflow_gold;
			} else {
				profile.fails += 1;
				report.fails += 1;
			}
			addExperience(profile, xp);
		}
	} else if (!profile.farm_enabled) {
		profile.progress_seconds = 0;
	}
	if (now > profile.last_settled_at) profile.last_settled_at = now;
	return report;
}

function simulateRun(profile, seed, nk) {
	var power = profile.level * 1.3 + profile.highest_floor * 0.8;
	var attributeNames = Object.keys(profile.attributes);
	for (var a = 0; a < attributeNames.length; a++) power += profile.attributes[attributeNames[a]] * 0.15;
	for (var i = 0; i < GEAR_SLOTS.length; i++) {
		var item = profile.equipment[GEAR_SLOTS[i]];
		power += (item.power || 0) * 0.09 + (item.armor || 0) * 0.015;
	}
	var difficulty = 10 + profile.farm_floor * 1.14;
	var chance = Math.max(0.52, Math.min(0.985, 0.88 + (power - difficulty) * 0.012));
	return { seed: seed, won: random01(seed, 7, nk) < chance };
}

function awardLoot(profile, seed, nk) {
	var count = random01(seed, 11, nk) < 0.68 ? 2 : 1;
	var items = 0;
	var salvaged = 0;
	var overflowGold = 0;
	for (var i = 0; i < count; i++) {
		var qualityRoll = random01(seed, 20 + i, nk);
		var quality = qualityRoll < 0.004 ? "LEGENDARY" : qualityRoll < 0.045 ? "EPIC" : qualityRoll < 0.21 ? "RARE" : qualityRoll < 0.52 ? "UNCOMMON" : "COMMON";
		var slot = GEAR_SLOTS[Math.floor(random01(seed, 40 + i, nk) * GEAR_SLOTS.length)];
		var item = createItem(profile, slot, itemTier(profile.farm_floor), quality, false);
		if (profile.inventory.length < MAX_BAG_SIZE) {
			profile.inventory.push(item);
			items += 1;
		} else {
			overflowGold += item.sell;
			salvaged += 1;
		}
	}
	return { items: items, salvaged: salvaged, overflow_gold: overflowGold };
}

function createItem(profile, slot, tier, quality, starter) {
	var primary = CLASSES[profile.class_name] || "Strength";
	var qualityName = quality || "COMMON";
	var tierValue = Math.max(1, tier || 1);
	profile.item_serial += 1;
	var base = 26 + tierValue * 10 + Math.min(99, tierValue) * 2;
	var power = Math.floor(base * (QUALITY_POWER[qualityName] || 1));
	var armor = ["Helmet", "Chest", "Gloves", "Boots"].indexOf(slot) >= 0 ? Math.floor(power * 0.62) : 0;
	var statKey = (slot === "Helmet" || slot === "Chest" || slot === "Boots") ? "Vitality" : primary;
	var statAmount = Math.max(1, tierValue + Math.floor(power / 55));
	return {
		id: (starter ? "starter" : "loot") + "_" + profile.item_serial,
		slot: slot,
		name: (starter ? "Ashen " : "Veilforged ") + qualityName.charAt(0) + qualityName.slice(1).toLowerCase() + " " + slot,
		quality: qualityName,
		tier: tierValue,
		power: power,
		armor: armor,
		stats: (function() { var values = { Strength: 0, Dexterity: 0, Intellect: 0, Vitality: 0, Spirit: 0 }; values[statKey] = statAmount; return values; })(),
		sell: Math.floor((24 + tierValue * 18) * (QUALITY_POWER[qualityName] || 1)),
		temper: 0
	};
}

function addExperience(profile, amount) {
	profile.xp += amount;
	while (profile.xp >= profile.level * 1000 && profile.level < 100000) {
		profile.xp -= profile.level * 1000;
		profile.level += 1;
		profile.attribute_points += 2;
	}
}

function findItem(items, itemId) {
	if (typeof itemId !== "string") return -1;
	for (var i = 0; i < items.length; i++) if (items[i] && items[i].id === itemId) return i;
	return -1;
}

function itemTier(floor) { return Math.max(1, Math.floor((floor - 1) / 10) + 1); }
function runDuration(floor) { return 45 + Math.min(100, floor) * 0.35; }
function boundedInt(value, minimum, maximum, fallback) {
	if (typeof value !== "number" || !isFinite(value) || value % 1 !== 0) return fallback;
	return Math.max(minimum, Math.min(maximum, value));
}
function secureSeed(nk) {
	if (!nk || typeof nk.secureRandomBytes !== "function") throw new Error("Nakama secure random bytes are required for progression rewards.");
	var bytes = nk.secureRandomBytes(16);
	if (!bytes || typeof bytes.byteLength !== "number" || bytes.byteLength !== 16 || typeof Uint8Array !== "function") throw new Error("Nakama returned invalid secure random bytes.");
	var values = new Uint8Array(bytes);
	if (values.length !== 16) throw new Error("Nakama returned invalid secure random bytes.");
	var result = "";
	for (var i = 0; i < values.length; i++) {
		var hex = values[i].toString(16);
		result += hex.length === 1 ? "0" + hex : hex;
	}
	return result;
}
function random01(seed, salt, nk) {
	if (!nk || typeof nk.sha256Hash !== "function") throw new Error("Nakama SHA-256 is required for progression rewards.");
	var digest = nk.sha256Hash(seed + ":" + salt);
	if (typeof digest !== "string" || !/^[0-9a-fA-F]{64}$/.test(digest)) throw new Error("Nakama returned an invalid SHA-256 digest.");
	return parseInt(digest.substring(0, 8), 16) / 4294967296;
}

function publicProfile(profile) {
	return JSON.parse(JSON.stringify(profile));
}
