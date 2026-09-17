extends Node
## Autoload "GameState" : progression, améliorations permanentes, buffs de zone, sauvegarde.

const DEFAULT_SAVE_PATH := "user://gardiens_save.json"
const ZONE_COUNT := 5

## Chemin du fichier de sauvegarde (les tests automatiques le redirigent pour ne pas écraser la vraie partie).
var save_path: String = DEFAULT_SAVE_PATH

const BASE_HP := 100
const BASE_DAMAGE := 25.0
const BASE_SPEED := 170.0
const BASE_ATTACK_COOLDOWN := 0.35
const BASE_THROW_COOLDOWN := 2.0
const THROW_DAMAGE_MULT := 1.6

## Améliorations majeures permanentes proposées après chaque boss.
const UPGRADES := {
	"max_hp": {"title": "Cœur de niaouli", "desc": "+25 PV max", "max": 99},
	"damage": {"title": "Pointe de nickel", "desc": "+25 % de dégâts", "max": 99},
	"speed": {"title": "Foulée du cagou", "desc": "+12 % de vitesse", "max": 99},
	"double_jump": {"title": "Ailes de roussette", "desc": "Débloque le double saut", "max": 1},
	"lifesteal": {"title": "Sève régénérante", "desc": "+10 % de vol de vie", "max": 3},
	"attack_speed": {"title": "Réflexes de gecko", "desc": "+20 % de cadence (lance et javelot)", "max": 99},
}

var unlocked_zones: int = 1
var completed_zones: Array = []
var upgrades: Dictionary = {}
var total_kills: int = 0
var current_zone: int = 0
var run_buffs: Dictionary = {}


func _ready() -> void:
	_reset_upgrades()
	reset_run_buffs()
	load_game()


func _reset_upgrades() -> void:
	upgrades = {}
	for key in UPGRADES.keys():
		upgrades[key] = 0


## Buffs mineurs gagnés entre les vagues ; réinitialisés à chaque entrée dans une zone.
func reset_run_buffs() -> void:
	run_buffs = {"damage_mult": 1.0, "speed_mult": 1.0, "max_hp_bonus": 0, "labels": []}


# ---------------------------------------------------------------- statistiques dérivées

func get_max_hp() -> int:
	return BASE_HP + upgrades["max_hp"] * 25 + int(run_buffs["max_hp_bonus"])


func get_damage() -> float:
	return BASE_DAMAGE * (1.0 + 0.25 * upgrades["damage"]) * float(run_buffs["damage_mult"])


func get_speed() -> float:
	return BASE_SPEED * (1.0 + 0.12 * upgrades["speed"]) * float(run_buffs["speed_mult"])


func get_attack_cooldown() -> float:
	return BASE_ATTACK_COOLDOWN / (1.0 + 0.2 * upgrades["attack_speed"])


func get_throw_cooldown() -> float:
	return BASE_THROW_COOLDOWN / (1.0 + 0.2 * upgrades["attack_speed"])


func get_lifesteal() -> float:
	return 0.10 * upgrades["lifesteal"]


func has_double_jump() -> bool:
	return upgrades["double_jump"] > 0


# ---------------------------------------------------------------- progression

func is_zone_unlocked(index: int) -> bool:
	return index < unlocked_zones


func is_zone_completed(index: int) -> bool:
	return index in completed_zones


func apply_upgrade(id: String) -> void:
	if upgrades.has(id):
		upgrades[id] = mini(upgrades[id] + 1, UPGRADES[id]["max"])
	save_game()


func complete_zone(index: int) -> void:
	if not (index in completed_zones):
		completed_zones.append(index)
	unlocked_zones = clampi(maxi(unlocked_zones, index + 2), 1, ZONE_COUNT)
	save_game()


## Tire 3 améliorations disponibles (celles qui ne sont pas au maximum).
func pick_upgrade_choices(count: int = 3) -> Array:
	var available: Array = []
	for id in UPGRADES.keys():
		if upgrades[id] < UPGRADES[id]["max"]:
			available.append(id)
	available.shuffle()
	return available.slice(0, mini(count, available.size()))


func all_zones_completed() -> bool:
	return completed_zones.size() >= ZONE_COUNT


# ---------------------------------------------------------------- sauvegarde

func save_game() -> void:
	var data := {
		"version": 1,
		"unlocked_zones": unlocked_zones,
		"completed_zones": completed_zones,
		"upgrades": upgrades,
		"total_kills": total_kills,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Impossible d'écrire la sauvegarde : %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Sauvegarde illisible, elle est ignorée.")
		return false
	unlocked_zones = clampi(int(parsed.get("unlocked_zones", 1)), 1, ZONE_COUNT)
	completed_zones = []
	for z in parsed.get("completed_zones", []):
		completed_zones.append(int(z))
	total_kills = int(parsed.get("total_kills", 0))
	_reset_upgrades()
	var saved_upgrades = parsed.get("upgrades", {})
	if typeof(saved_upgrades) == TYPE_DICTIONARY:
		for key in saved_upgrades.keys():
			if upgrades.has(key):
				upgrades[key] = int(saved_upgrades[key])
	return true


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func clear_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	unlocked_zones = 1
	completed_zones = []
	total_kills = 0
	current_zone = 0
	_reset_upgrades()
	reset_run_buffs()
