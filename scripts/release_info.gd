extends RefCounted
## Public beta identity. No account, save contents, identifiers or secrets in feedback.
const VERSION := "0.47.0-beta.1"
const VERSION_CODE := 53
const FEEDBACK_URL := "https://github.com/Philmenting/Emberfall-Ashen-Veil/issues"

static func feedback(game: Control) -> String:
	var report := "Emberfall %s (%d)\nPlatform: %s\nDisplay: %dx%d\nClass: %s | Level: %d | Next floor: %d\nFarm: %s, floor %d | Stance: %s\nBattery mode: %s | Large text: %s | Reduced motion: %s\n\nWhat happened?\nExpected result?\nSteps to reproduce?\n" % [VERSION,VERSION_CODE,OS.get_name(),game.get_viewport_rect().size.x,game.get_viewport_rect().size.y,game.character_class,game.player_level,game.floor_number,game.farm_mode,game.farm_floor,game.combat_stances[game.character_class],game.preferences.battery,game.preferences.large_text,game.preferences.reduced_motion]
	if game.preferences.playtest: report+="\n"+game.PlaytestNotes.report(game.playtest_notes)+"\n"
	return report
