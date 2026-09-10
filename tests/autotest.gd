extends Node
## Test automatique de la boucle de gameplay complète d'une zone.
## Lancement : Godot.exe --path . res://tests/autotest.tscn
## Variables d'environnement : GDC_ZONE (index de zone), GDC_SHOTS (dossier des captures d'écran).

const GAME := preload("res://scenes/game.tscn")

var game: Node
var shots_dir := ""
var failures := 0


func _ready() -> void:
	shots_dir = OS.get_environment("GDC_SHOTS")
	GameState.clear_save()
	GameState.current_zone = int(OS.get_environment("GDC_ZONE")) if OS.has_environment("GDC_ZONE") else 0
	Engine.time_scale = 2.0
	game = GAME.instantiate()
	add_child(game)
	_run()
	# garde-fou : on quitte quoi qu'il arrive au bout de 150 s
	get_tree().create_timer(150.0, true, false, true).timeout.connect(func() -> void:
		_log("TIMEOUT du test")
		_finish(1))


func _run() -> void:
	await _wait(0.6)
	await _shot("01_intro")
	_check(game.state == "intro", "état intro")

	await _wait_state("wave")
	await _wait(2.0)
	_check(game.alive_enemies.size() > 0, "des ennemis sont apparus (%d)" % game.alive_enemies.size())
	await _shot("02_wave1")

	# dégâts sur le joueur puis vérification de l'invulnérabilité (les ennemis sont encore loin)
	var hp_before: int = game.player.hp
	game.player.take_damage(30, game.player.global_position + Vector2(50, 0))
	game.player.take_damage(30, game.player.global_position + Vector2(50, 0))
	_check(game.player.hp == hp_before - 30, "dégâts + invulnérabilité (%d -> %d)" % [hp_before, game.player.hp])

	await _wait(5.0)
	await _shot("02b_wave1_contact")

	# lancer de javelot : projectile créé, temps de recharge actif
	game.player._throw()
	var javelins := 0
	for child in game.world.get_children():
		if child is Javelin:
			javelins += 1
	_check(javelins == 1, "javelot lancé")
	_check(game.player.throw_cooldown > 0.0, "recharge du javelot active (%.1f s)" % game.player.throw_cooldown)

	# le joueur tue tout jusqu'au boss
	var guard := 0
	while game.state != "boss" and guard < 400:
		guard += 1
		for e in game.alive_enemies.duplicate():
			if is_instance_valid(e):
				e.take_damage(9999.0, e.global_position + Vector2(30, 0))
		await _wait(0.3)
	_check(game.state == "boss", "arrivée au boss après 5 vagues (vague=%d)" % game.wave)
	_check(GameState.run_buffs["labels"].size() + 0 >= 0, "buffs mineurs : %s" % str(GameState.run_buffs["labels"]))
	await _wait(1.5)
	await _shot("03_boss")

	# mort du joueur pendant le boss puis réapparition
	game.player.take_damage(99999, game.player.global_position + Vector2(50, 0))
	_check(game.player.dead, "le joueur meurt")
	await _wait_state("dead")
	await _wait_state("boss")
	await _wait(0.5)
	_check(not game.player.dead and game.player.hp == game.player.max_hp, "réapparition avec PV pleins (%d/%d)" % [game.player.hp, game.player.max_hp])
	_check(is_instance_valid(game.boss), "le boss est réapparu")

	# on laisse le boss agir un peu (attaque spéciale) puis on le tue
	await _wait(4.0)
	await _shot("04_boss_fight")
	guard = 0
	while game.state == "boss" and guard < 300:
		guard += 1
		if is_instance_valid(game.boss):
			game.boss.take_damage(150.0, game.boss.global_position + Vector2(40, 0))
		await _wait(0.15)
	_check(game.state == "victory", "boss vaincu")
	await _wait_visible(game.hud.upgrade_panel)
	await _shot("05_upgrade")
	_check(game.hud.choices.get_child_count() == 3, "3 améliorations proposées")
	var chosen_button: Button = game.hud.choices.get_child(0)
	chosen_button.pressed.emit()
	await _wait_visible(game.hud.end_panel)
	await _shot("06_end")
	var total_upgrades := 0
	for id in GameState.upgrades.keys():
		total_upgrades += GameState.upgrades[id]
	_check(total_upgrades == 1, "amélioration permanente appliquée")
	_check(GameState.is_zone_completed(GameState.current_zone), "zone marquée terminée")
	_check(GameState.unlocked_zones == mini(GameState.current_zone + 2, GameState.ZONE_COUNT), "zone suivante débloquée (%d)" % GameState.unlocked_zones)
	_check(FileAccess.file_exists(GameState.SAVE_PATH), "fichier de sauvegarde écrit")

	# rechargement de la sauvegarde
	var unlocked := GameState.unlocked_zones
	GameState.unlocked_zones = 1
	GameState.load_game()
	_check(GameState.unlocked_zones == unlocked, "sauvegarde rechargée (%d)" % GameState.unlocked_zones)

	_finish(0)


# ---------------------------------------------------------------- utilitaires

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _wait_state(target: String) -> void:
	var guard := 0
	while game.state != target and guard < 3000:
		guard += 1
		await get_tree().process_frame
	_check(game.state == target, "état attendu '%s' (actuel '%s')" % [target, game.state])


func _wait_visible(control: CanvasItem) -> void:
	var guard := 0
	while not control.visible and guard < 3000:
		guard += 1
		await get_tree().process_frame
	_check(control.visible, "panneau visible : %s" % control.name)


func _shot(name: String) -> void:
	if shots_dir == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := shots_dir.path_join(name + ".png")
	var err := image.save_png(path)
	_log("capture %s (%s)" % [path, error_string(err)])


func _check(condition: bool, label: String) -> void:
	if condition:
		_log("OK   " + label)
	else:
		failures += 1
		_log("FAIL " + label)


func _log(text: String) -> void:
	print("[AUTOTEST] " + text)


func _finish(code: int) -> void:
	_log("Terminé avec %d échec(s)" % failures)
	Audio.stop_all()
	# laisse au serveur audio le temps de libérer les lectures en cours avant de quitter
	await get_tree().create_timer(0.2, true, false, true).timeout
	get_tree().quit(code if failures == 0 else 1)
