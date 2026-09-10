extends CanvasLayer
## Interface en jeu : PV, vagues, buffs, barre de boss, messages, pause, choix d'amélioration, fin de zone.

signal upgrade_chosen(id: String)
signal next_zone_pressed
signal zone_menu_pressed
signal restart_pressed

@onready var hp_label: Label = $TopLeft/VBox/HPRow/HPLabel
@onready var hp_bar: ProgressBar = $TopLeft/VBox/HPRow/HPBar
@onready var throw_label: Label = $TopLeft/VBox/ThrowRow/ThrowLabel
@onready var throw_bar: ProgressBar = $TopLeft/VBox/ThrowRow/ThrowBar
@onready var wave_label: Label = $TopLeft/VBox/WaveLabel
@onready var buffs_label: Label = $TopLeft/VBox/BuffsLabel
@onready var zone_label: Label = $ZoneLabel
@onready var message: Label = $Message
@onready var boss_bar: VBoxContainer = $BossBar
@onready var boss_name: Label = $BossBar/BossName
@onready var boss_progress: ProgressBar = $BossBar/BossProgress
@onready var pause_panel: PanelContainer = $PausePanel
@onready var upgrade_panel: PanelContainer = $UpgradePanel
@onready var choices: HBoxContainer = $UpgradePanel/VBox/Choices
@onready var end_panel: PanelContainer = $EndPanel
@onready var end_title: Label = $EndPanel/VBox/EndTitle
@onready var end_text: Label = $EndPanel/VBox/EndText
@onready var next_button: Button = $EndPanel/VBox/EndButtons/NextButton

var message_tween: Tween


func _ready() -> void:
	$PausePanel/VBox/ResumeButton.pressed.connect(toggle_pause)
	$PausePanel/VBox/RestartButton.pressed.connect(_on_restart)
	$PausePanel/VBox/QuitButton.pressed.connect(_on_quit)
	next_button.pressed.connect(func() -> void: next_zone_pressed.emit())
	$EndPanel/VBox/EndButtons/MenuButton.pressed.connect(func() -> void: zone_menu_pressed.emit())
	Audio.hook_buttons(self)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not upgrade_panel.visible and not end_panel.visible:
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_panel.visible = paused
	if paused:
		$PausePanel/VBox/ResumeButton.grab_focus()


func _on_restart() -> void:
	get_tree().paused = false
	pause_panel.visible = false
	restart_pressed.emit()


func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ---------------------------------------------------------------- affichage

func set_hp(hp: int, max_hp: int) -> void:
	hp_label.text = "PV %d/%d" % [hp, max_hp]
	hp_bar.max_value = max_hp
	hp_bar.value = hp


func set_throw_cooldown(remaining: float, total: float) -> void:
	throw_bar.max_value = maxf(total, 0.01)
	throw_bar.value = total - remaining
	throw_label.text = "Javelot : prêt" if remaining <= 0.0 else "Javelot : %.1f s" % remaining


func set_wave(wave: int, total: int) -> void:
	wave_label.text = "Vague %d / %d" % [wave, total] if wave > 0 else "Préparez-vous..."


func set_buffs(labels: Array) -> void:
	if labels.is_empty():
		buffs_label.text = "Buffs : aucun"
	else:
		buffs_label.text = "Buffs : " + ", ".join(PackedStringArray(labels))


func set_zone(zone_name: String, subtitle: String) -> void:
	zone_label.text = "%s  —  %s" % [zone_name, subtitle]


func show_message(text: String, duration: float = 2.0) -> void:
	message.text = text
	if message_tween != null and message_tween.is_valid():
		message_tween.kill()
	message.modulate.a = 0.0
	message_tween = create_tween()
	message_tween.tween_property(message, "modulate:a", 1.0, 0.25)
	message_tween.tween_interval(duration)
	message_tween.tween_property(message, "modulate:a", 0.0, 0.4)


func show_boss(boss_title: String, max_hp: float) -> void:
	boss_name.text = boss_title
	boss_progress.max_value = max_hp
	boss_progress.value = max_hp
	boss_bar.visible = true


func set_boss_hp(hp: float, max_hp: float) -> void:
	boss_progress.max_value = max_hp
	boss_progress.value = maxf(hp, 0.0)


func hide_boss() -> void:
	boss_bar.visible = false


func show_upgrades(ids: Array) -> void:
	for child in choices.get_children():
		child.queue_free()
	for id in ids:
		var info: Dictionary = GameState.UPGRADES[id]
		var button := Button.new()
		button.text = "%s\n%s" % [info["title"], info["desc"]]
		button.custom_minimum_size = Vector2(150, 60)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(_on_upgrade_pressed.bind(id))
		choices.add_child(button)
	Audio.hook_buttons(choices)
	upgrade_panel.visible = true
	get_tree().paused = true
	if choices.get_child_count() > 0:
		choices.get_child(0).grab_focus()


func _on_upgrade_pressed(id: String) -> void:
	upgrade_panel.visible = false
	upgrade_chosen.emit(id)


func show_end(title: String, text: String, has_next: bool) -> void:
	end_title.text = title
	end_text.text = text
	next_button.visible = has_next
	end_panel.visible = true
	get_tree().paused = true
	if has_next:
		next_button.grab_focus()
	else:
		$EndPanel/VBox/EndButtons/MenuButton.grab_focus()
