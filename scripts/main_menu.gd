extends Control
## Menu principal : lancer le jeu, lire l'histoire, effacer la sauvegarde, quitter.

@onready var play_button: Button = $MenuPanel/VBox/PlayButton
@onready var story_panel: PanelContainer = $StoryPanel
@onready var progress: Label = $MenuPanel/VBox/Progress


func _ready() -> void:
	play_button.pressed.connect(_on_play)
	$MenuPanel/VBox/StoryButton.pressed.connect(func() -> void: story_panel.visible = true)
	$MenuPanel/VBox/ResetButton.pressed.connect(_on_reset)
	$MenuPanel/VBox/QuitButton.pressed.connect(func() -> void: get_tree().quit())
	$StoryPanel/VBox/CloseButton.pressed.connect(func() -> void: story_panel.visible = false)
	_refresh_progress()
	Audio.hook_buttons(self)
	Audio.play_music("menu")
	play_button.grab_focus()


func _refresh_progress() -> void:
	var done := GameState.completed_zones.size()
	if GameState.all_zones_completed():
		progress.text = "Toutes les zones sont sécurisées !\n%d mutants éliminés" % GameState.total_kills
	elif GameState.has_save():
		progress.text = "Zones sécurisées : %d / %d\n%d mutants éliminés" % [done, GameState.ZONE_COUNT, GameState.total_kills]
	else:
		progress.text = "Nouvelle partie"


func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/zone_select.tscn")


func _on_reset() -> void:
	GameState.clear_save()
	_refresh_progress()
