extends Control
## Sélection de zone : déblocage progressif, aperçu, description et statistiques du gardien.

@onready var zones_box: VBoxContainer = $Layout/Left/Zones
@onready var preview: TextureRect = $Preview
@onready var zone_name: Label = $Layout/Right/VBox/ZoneName
@onready var zone_subtitle: Label = $Layout/Right/VBox/ZoneSubtitle
@onready var zone_description: Label = $Layout/Right/VBox/ZoneDescription
@onready var zone_info: Label = $Layout/Right/VBox/ZoneInfo
@onready var stats: Label = $Layout/Right/VBox/Stats

var buttons: Array = []


func _ready() -> void:
	$Layout/Left/BackButton.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	for i in range(ZoneData.ZONES.size()):
		var zone: Dictionary = ZoneData.ZONES[i]
		var button := Button.new()
		var status := "Verrouillée"
		if GameState.is_zone_completed(i):
			status = "Sécurisée ✓"
		elif GameState.is_zone_unlocked(i):
			status = "Disponible"
		button.text = "%d. %s  —  %s" % [i + 1, zone["name"], status]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not GameState.is_zone_unlocked(i)
		button.pressed.connect(_on_zone_pressed.bind(i))
		button.focus_entered.connect(_show_zone.bind(i))
		button.mouse_entered.connect(_show_zone.bind(i))
		zones_box.add_child(button)
		buttons.append(button)
	_refresh_stats()
	Audio.hook_buttons(self)
	Audio.play_music("menu")
	var first := clampi(GameState.unlocked_zones - 1, 0, buttons.size() - 1)
	_show_zone(first)
	buttons[first].grab_focus()


func _show_zone(index: int) -> void:
	var zone: Dictionary = ZoneData.ZONES[index]
	zone_name.text = zone["name"]
	zone_subtitle.text = zone["subtitle"]
	zone_description.text = zone["description"]
	var boss: Dictionary = ZoneData.BOSSES[zone["boss"]]
	var enemy_names: Array = []
	for type in zone["enemies"]:
		var n: String = ZoneData.ENEMIES[type]["name"]
		if not (n in enemy_names):
			enemy_names.append(n)
	zone_info.text = "Mutants : %s\nBoss : %s" % [", ".join(PackedStringArray(enemy_names)), boss["name"]]
	preview.texture = load(zone["background"])


func _refresh_stats() -> void:
	var lines: Array = []
	lines.append("PV max : %d   Dégâts : %d   Vitesse : %d" % [GameState.get_max_hp(), int(GameState.get_damage()), int(GameState.get_speed())])
	var owned: Array = []
	for id in GameState.UPGRADES.keys():
		var level: int = GameState.upgrades[id]
		if level > 0:
			var title: String = GameState.UPGRADES[id]["title"]
			owned.append("%s x%d" % [title, level] if level > 1 else title)
	if owned.is_empty():
		lines.append("Améliorations : aucune pour l'instant")
	else:
		lines.append("Améliorations : " + ", ".join(PackedStringArray(owned)))
	lines.append("Mutants éliminés : %d" % GameState.total_kills)
	stats.text = "\n".join(PackedStringArray(lines))


func _on_zone_pressed(index: int) -> void:
	GameState.current_zone = index
	get_tree().change_scene_to_file("res://scenes/game.tscn")
