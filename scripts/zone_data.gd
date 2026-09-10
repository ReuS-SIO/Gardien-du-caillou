class_name ZoneData
extends RefCounted
## Données statiques du jeu : ennemis, boss, zones, composition des vagues.

## Vitesses volontairement inférieures à celle du joueur (170) pour laisser le temps de frapper et d'esquiver.
const ENEMIES := {
	"gecko": {
		"name": "Gecko mutant", "texture": "res://assets/sprites/enemy_gecko.png",
		"hp": 28.0, "speed": 72.0, "damage": 8, "flying": false, "charger": false,
	},
	"crab": {
		"name": "Crabe mutant", "texture": "res://assets/sprites/enemy_crab.png",
		"hp": 70.0, "speed": 36.0, "damage": 12, "flying": false, "charger": false,
	},
	"bat": {
		"name": "Roussette mutante", "texture": "res://assets/sprites/enemy_bat.png",
		"hp": 24.0, "speed": 62.0, "damage": 6, "flying": true, "charger": false,
	},
	"boar": {
		"name": "Cochon sauvage mutant", "texture": "res://assets/sprites/enemy_boar.png",
		"hp": 55.0, "speed": 50.0, "damage": 14, "flying": false, "charger": true,
	},
}

const BOSSES := {
	"cagou": {
		"name": "Cagou colossal", "texture": "res://assets/sprites/boss_cagou.png",
		"hp": 420.0, "speed": 48.0, "damage": 16, "flying": false, "charger": false,
		"special": "slam", "minion": "gecko",
	},
	"crab": {
		"name": "Crabe de cocotier titanesque", "texture": "res://assets/sprites/boss_crab.png",
		"hp": 600.0, "speed": 38.0, "damage": 20, "flying": false, "charger": false,
		"special": "minions", "minion": "crab",
	},
	"snake": {
		"name": "Tricot rayé abyssal", "texture": "res://assets/sprites/boss_snake.png",
		"hp": 750.0, "speed": 58.0, "damage": 18, "flying": false, "charger": false,
		"special": "spit", "minion": "bat",
	},
	"deer": {
		"name": "Cerf rusa irradié", "texture": "res://assets/sprites/boss_deer.png",
		"hp": 900.0, "speed": 56.0, "damage": 24, "flying": false, "charger": true,
		"special": "charge", "minion": "boar",
	},
	"bat": {
		"name": "Roussette alpha", "texture": "res://assets/sprites/boss_bat.png",
		"hp": 1050.0, "speed": 72.0, "damage": 22, "flying": true, "charger": false,
		"special": "storm", "minion": "bat",
	},
}

## Plateformes : [x (px), y (px du haut), largeur en tuiles de 32 px]
const ZONES := [
	{
		"id": "foret_seche", "name": "Forêt sèche de niaoulis",
		"subtitle": "Zone 1 — Contamination naissante",
		"description": "Les premiers animaux étranges ont été aperçus dans la forêt de niaoulis qui borde la mine. Les geckos se sont mis à briller la nuit.",
		"background": "res://assets/backgrounds/bg_foret_seche.png",
		"tint": Color(1.0, 1.0, 1.0), "overlay": Color(0.5, 1.0, 0.3, 0.0), "particles": 0,
		"enemies": ["gecko", "gecko", "boar"], "boss": "cagou",
		"platforms": [[220, 250, 5], [560, 190, 4], [880, 240, 6], [1260, 180, 4], [1580, 250, 5]],
	},
	{
		"id": "mangrove", "name": "Mangrove de la baie",
		"subtitle": "Zone 2 — L'eau se trouble",
		"description": "L'eau qui descend de la montagne charrie une boue violette. Dans la mangrove, les crabes ont doublé de taille et attaquent tout ce qui bouge.",
		"background": "res://assets/backgrounds/bg_mangrove.png",
		"tint": Color(0.95, 1.0, 0.92), "overlay": Color(0.5, 1.0, 0.3, 0.05), "particles": 10,
		"enemies": ["crab", "crab", "gecko", "bat"], "boss": "crab",
		"platforms": [[160, 240, 4], [420, 170, 3], [700, 230, 5], [1000, 160, 4], [1300, 230, 5], [1640, 170, 4]],
	},
	{
		"id": "plage", "name": "Plage de Kouaoua",
		"subtitle": "Zone 3 — Le lagon contaminé",
		"description": "Le lagon a pris une teinte fluorescente. Les tricots rayés, normalement inoffensifs, sortent de l'eau pour chasser sur le sable.",
		"background": "res://assets/backgrounds/bg_plage.png",
		"tint": Color(0.9, 1.0, 0.88), "overlay": Color(0.6, 1.0, 0.2, 0.08), "particles": 18,
		"enemies": ["crab", "bat", "bat", "gecko"], "boss": "snake",
		"platforms": [[120, 260, 3], [380, 200, 4], [660, 150, 3], [940, 210, 6], [1280, 150, 3], [1540, 200, 4], [1760, 260, 3]],
	},
	{
		"id": "mine_nickel", "name": "Mine de nickel à ciel ouvert",
		"subtitle": "Zone 4 — Le cœur du mal",
		"description": "Voici la mine où tout a commencé. Le minerai suinte une lumière malsaine et les cerfs rusa qui y broutaient sont devenus des monstres.",
		"background": "res://assets/backgrounds/bg_mine_nickel.png",
		"tint": Color(0.92, 0.85, 1.0), "overlay": Color(0.7, 0.3, 1.0, 0.12), "particles": 28,
		"enemies": ["boar", "boar", "gecko", "bat", "crab"], "boss": "deer",
		"platforms": [[200, 230, 4], [480, 160, 4], [780, 250, 5], [1080, 170, 3], [1360, 240, 5], [1680, 160, 4]],
	},
	{
		"id": "port_kouaoua", "name": "Port de chargement",
		"subtitle": "Zone 5 — Dernier rempart",
		"description": "Les mutants convergent vers le port pour embarquer sur les minéraliers. Si la contamination quitte l'île, toute la faune du Pacifique est menacée. C'est ici que tout se joue.",
		"background": "res://assets/backgrounds/bg_port_kouaoua.png",
		"tint": Color(0.85, 0.8, 1.0), "overlay": Color(0.8, 0.2, 1.0, 0.16), "particles": 40,
		"enemies": ["gecko", "crab", "bat", "boar"], "boss": "bat",
		"platforms": [[140, 250, 4], [400, 180, 5], [720, 120, 3], [960, 220, 6], [1320, 150, 4], [1620, 240, 5]],
	},
]

const WAVES_PER_ZONE := 5


## Retourne la liste des types d'ennemis d'une vague (déterministe).
static func get_wave(zone_index: int, wave_number: int) -> Array:
	var zone: Dictionary = ZONES[zone_index]
	var pool: Array = zone["enemies"]
	var rng := RandomNumberGenerator.new()
	rng.seed = zone_index * 1000 + wave_number * 17
	# zone 1 : 4 → 8 mutants par vague ; zone 5 : 8 → 12
	var count: int = 3 + wave_number + zone_index
	var result: Array = []
	for i in range(count):
		result.append(pool[rng.randi_range(0, pool.size() - 1)])
	# la première vague de la première zone ne contient que des geckos (prise en main)
	if zone_index == 0 and wave_number == 1:
		result.fill("gecko")
	return result


## Multiplicateur de difficulté (PV / dégâts) selon la zone et la vague.
static func get_difficulty(zone_index: int, wave_number: int) -> float:
	return 1.0 + zone_index * 0.3 + (wave_number - 1) * 0.06
