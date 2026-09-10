extends Node2D
## Scène de jeu : construit la zone (carte fermée), gère les vagues, le boss, les buffs et la progression.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const BOSS_SCENE := preload("res://scenes/boss.tscn")
const TEX_GROUND := preload("res://assets/sprites/tile_ground.png")
const TEX_PLATFORM := preload("res://assets/sprites/tile_platform.png")
const TEX_ROCK := preload("res://assets/sprites/rock.png")
const TEX_ORE := preload("res://assets/sprites/ore_crystal.png")

const LEVEL_WIDTH := 1920
const LEVEL_HEIGHT := 360
const GROUND_Y := 328
const WAVES := ZoneData.WAVES_PER_ZONE

@onready var world: Node2D = $World
@onready var hud: CanvasLayer = $HUD

var zone_index: int = 0
var zone: Dictionary = {}
var player: Player
var boss: Boss
var state := "intro"
var wave := 0
var spawn_queue: Array = []
var spawn_timer := 0.0
var alive_enemies: Array = []
var spawn_point := Vector2.ZERO
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	zone_index = clampi(GameState.current_zone, 0, ZoneData.ZONES.size() - 1)
	zone = ZoneData.ZONES[zone_index]
	rng.seed = zone_index * 7919 + 13
	GameState.reset_run_buffs()

	_build_background()
	_build_level()
	_build_overlay()
	_spawn_player()

	hud.set_zone(zone["name"], zone["subtitle"])
	hud.set_wave(0, WAVES)
	hud.set_buffs([])
	hud.upgrade_chosen.connect(_on_upgrade_chosen)
	hud.next_zone_pressed.connect(_on_next_zone)
	hud.zone_menu_pressed.connect(_on_zone_menu)
	hud.restart_pressed.connect(_on_restart)
	Audio.play_music("zone_%d" % zone_index)
	_intro()


# ---------------------------------------------------------------- construction de la zone

func _build_background() -> void:
	var parallax := ParallaxBackground.new()
	add_child(parallax)

	var texture: Texture2D = load(zone["background"])
	var scale_factor := float(LEVEL_HEIGHT) / texture.get_height()
	var scaled_width := texture.get_width() * scale_factor

	var far := ParallaxLayer.new()
	far.motion_scale = Vector2(0.4, 1.0)
	far.motion_mirroring = Vector2(scaled_width, 0)
	var bg := Sprite2D.new()
	bg.texture = texture
	bg.centered = false
	bg.scale = Vector2(scale_factor, scale_factor)
	bg.modulate = zone["tint"]
	far.add_child(bg)
	parallax.add_child(far)

	# couche intermédiaire : silhouettes sombres au niveau du sol pour la profondeur
	var mid := ParallaxLayer.new()
	mid.motion_scale = Vector2(0.75, 1.0)
	mid.motion_mirroring = Vector2(LEVEL_WIDTH, 0)
	for i in range(14):
		var deco := Sprite2D.new()
		deco.texture = TEX_ROCK if rng.randf() < 0.6 else TEX_ORE
		deco.scale = Vector2(3, 3)
		deco.modulate = Color(0.15, 0.12, 0.18, 0.75)
		deco.position = Vector2(rng.randf_range(0, LEVEL_WIDTH), GROUND_Y - deco.texture.get_height() * 1.5 + 6)
		mid.add_child(deco)
	parallax.add_child(mid)


func _build_level() -> void:
	# sol
	var ground := _make_static_body(Vector2(LEVEL_WIDTH * 0.5, GROUND_Y + 32), Vector2(LEVEL_WIDTH + 400, 64))
	var ground_sprite := Sprite2D.new()
	ground_sprite.texture = TEX_GROUND
	ground_sprite.centered = false
	ground_sprite.region_enabled = true
	ground_sprite.region_rect = Rect2(0, 0, LEVEL_WIDTH * 0.5, 16)
	ground_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ground_sprite.scale = Vector2(2, 2)
	ground_sprite.position = Vector2(-LEVEL_WIDTH * 0.5, -32)
	ground.add_child(ground_sprite)
	world.add_child(ground)

	# murs invisibles : la carte est fermée
	world.add_child(_make_static_body(Vector2(-20, LEVEL_HEIGHT * 0.5), Vector2(40, LEVEL_HEIGHT * 3)))
	world.add_child(_make_static_body(Vector2(LEVEL_WIDTH + 20, LEVEL_HEIGHT * 0.5), Vector2(40, LEVEL_HEIGHT * 3)))
	world.add_child(_make_static_body(Vector2(LEVEL_WIDTH * 0.5, -120), Vector2(LEVEL_WIDTH + 400, 40)))

	# plateformes traversables par le bas
	for p in zone["platforms"]:
		var x: float = p[0]
		var y: float = p[1]
		var tiles: int = p[2]
		var width := tiles * 32.0
		var body := _make_static_body(Vector2(x + width * 0.5, y + 6), Vector2(width, 12), true)
		var sprite := Sprite2D.new()
		sprite.texture = TEX_PLATFORM
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, tiles * 16, 6)
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		sprite.scale = Vector2(2, 2)
		sprite.position = Vector2(-width * 0.5, -6)
		body.add_child(sprite)
		world.add_child(body)

	# décor au sol : rochers et cristaux de minerai contaminé
	var ore_count: int = 2 + int(zone["particles"]) / 8
	for i in range(10 + ore_count):
		var deco := Sprite2D.new()
		deco.texture = TEX_ORE if i < ore_count else TEX_ROCK
		deco.scale = Vector2(2, 2)
		deco.position = Vector2(rng.randf_range(40, LEVEL_WIDTH - 40), GROUND_Y - deco.texture.get_height() + 2)
		deco.z_index = -1
		if deco.texture == TEX_ORE:
			var pulse := deco.create_tween().set_loops()
			pulse.tween_property(deco, "modulate", Color(1.4, 1.4, 1.6), 0.8)
			pulse.tween_property(deco, "modulate", Color.WHITE, 0.8)
		world.add_child(deco)

	# particules toxiques (contamination croissante selon la zone)
	var particle_count: int = int(zone["particles"])
	if particle_count > 0:
		var particles := CPUParticles2D.new()
		particles.amount = particle_count
		particles.lifetime = 4.0
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(LEVEL_WIDTH * 0.5, 10)
		particles.position = Vector2(LEVEL_WIDTH * 0.5, GROUND_Y)
		particles.direction = Vector2(0, -1)
		particles.spread = 20.0
		particles.gravity = Vector2(0, -25)
		particles.initial_velocity_min = 10.0
		particles.initial_velocity_max = 30.0
		particles.scale_amount_min = 1.5
		particles.scale_amount_max = 3.0
		var overlay_color: Color = zone["overlay"]
		particles.color = Color(overlay_color.r, overlay_color.g, overlay_color.b, 0.55)
		world.add_child(particles)


func _make_static_body(center: Vector2, size: Vector2, one_way: bool = false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.one_way_collision = one_way
	body.add_child(shape)
	return body


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	var rect := ColorRect.new()
	rect.color = zone["overlay"]
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	add_child(layer)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	spawn_point = Vector2(LEVEL_WIDTH * 0.5, GROUND_Y - 32)
	player.position = spawn_point
	world.add_child(player)
	player.camera.limit_right = LEVEL_WIDTH
	player.camera.limit_bottom = LEVEL_HEIGHT
	player.hp_changed.connect(hud.set_hp)
	player.throw_cooldown_changed.connect(hud.set_throw_cooldown)
	player.died.connect(_on_player_died)
	hud.set_hp(player.hp, player.max_hp)
	hud.set_throw_cooldown(0.0, GameState.get_throw_cooldown())


# ---------------------------------------------------------------- boucle de jeu

func _intro() -> void:
	state = "intro"
	hud.show_message("%s\n%s" % [zone["name"], zone["subtitle"]], 2.4)
	await get_tree().create_timer(2.8).timeout
	if state == "intro":
		_start_wave(1)


func _process(delta: float) -> void:
	if state == "wave" and not spawn_queue.is_empty():
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = maxf(1.6 - zone_index * 0.15, 0.7)
			spawn_enemy(spawn_queue.pop_front())


func _start_wave(number: int) -> void:
	wave = number
	state = "wave"
	spawn_queue = ZoneData.get_wave(zone_index, number)
	spawn_timer = 0.6
	hud.set_wave(number, WAVES)
	hud.show_message("Vague %d" % number, 1.4)
	Audio.play("wave_start", 0.0)


## Fait apparaître un mutant. Sans position, il arrive par un bord de la carte.
func spawn_enemy(type: String, at: Variant = null, difficulty_scale: float = 1.0) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	world.add_child(enemy)
	enemy.setup(ZoneData.ENEMIES[type], ZoneData.get_difficulty(zone_index, maxi(wave, 1)) * difficulty_scale)
	var pos: Vector2
	if at != null:
		pos = at
	else:
		var side := -1 if rng.randf() < 0.5 else 1
		var x := 30.0 if side < 0 else LEVEL_WIDTH - 30.0
		var y := rng.randf_range(80.0, 160.0) if enemy.flying else GROUND_Y - enemy.half_height - 1.0
		pos = Vector2(x, y)
	enemy.global_position = pos
	enemy.target = player
	enemy.died.connect(_on_enemy_died)
	alive_enemies.append(enemy)
	return enemy


func _on_enemy_died(enemy: Enemy) -> void:
	alive_enemies.erase(enemy)
	if state == "wave" and spawn_queue.is_empty() and alive_enemies.is_empty():
		_wave_cleared()


func _wave_cleared() -> void:
	state = "between"
	var buff_text := _apply_minor_buff()
	hud.set_buffs(GameState.run_buffs["labels"])
	# petit répit : on récupère un quart de ses PV entre deux vagues
	player.heal(int(player.max_hp * 0.25))
	hud.show_message("Vague nettoyée !\n%s" % buff_text, 2.4)
	Audio.play("wave_clear", 0.0)
	await get_tree().create_timer(3.0).timeout
	if state != "between":
		return
	if wave < WAVES:
		_start_wave(wave + 1)
	else:
		_start_boss()


## Buff mineur aléatoire, valable jusqu'à la fin de la zone.
func _apply_minor_buff() -> String:
	var buffs: Dictionary = GameState.run_buffs
	var text := ""
	match rng.randi_range(0, 3):
		0:
			buffs["damage_mult"] = float(buffs["damage_mult"]) * 1.10
			text = "+10 % dégâts"
			buffs["labels"].append(text)
		1:
			buffs["speed_mult"] = float(buffs["speed_mult"]) * 1.08
			text = "+8 % vitesse"
			buffs["labels"].append(text)
		2:
			buffs["max_hp_bonus"] = int(buffs["max_hp_bonus"]) + 15
			text = "+15 PV max"
			buffs["labels"].append(text)
		3:
			text = "Soin de 40 %"
			player.heal(int(player.max_hp * 0.4))
	player.refresh_stats()
	return text


func _start_boss() -> void:
	state = "boss"
	var boss_data: Dictionary = ZoneData.BOSSES[zone["boss"]]
	boss = BOSS_SCENE.instantiate()
	world.add_child(boss)
	boss.setup(boss_data, 1.0 + zone_index * 0.25, 2.5)
	var side := -1 if player.global_position.x > LEVEL_WIDTH * 0.5 else 1
	var x := 70.0 if side < 0 else LEVEL_WIDTH - 70.0
	var y := 110.0 if boss.flying else GROUND_Y - boss.half_height - 1.0
	boss.global_position = Vector2(x, y)
	boss.target = player
	boss.game = self
	boss.boss_hp_changed.connect(hud.set_boss_hp)
	boss.died.connect(_on_boss_died)
	hud.show_boss(boss_data["name"], boss.max_hp)
	hud.show_message("BOSS\n%s" % boss_data["name"], 2.5)
	Audio.play("boss_appear", 0.0)
	Audio.play_music("boss")


func _on_boss_died(_boss: Enemy) -> void:
	state = "victory"
	boss = null
	hud.hide_boss()
	_clear_enemies()
	GameState.complete_zone(zone_index)
	hud.show_message("Zone sécurisée !", 2.0)
	Audio.play("boss_die", 0.0)
	Audio.stop_music()
	await get_tree().create_timer(1.6).timeout
	Audio.play("victory", 0.0)
	await get_tree().create_timer(0.6).timeout
	var choices := GameState.pick_upgrade_choices(3)
	if choices.is_empty():
		_show_end()
	else:
		hud.show_upgrades(choices)


func _on_upgrade_chosen(id: String) -> void:
	GameState.apply_upgrade(id)
	Audio.play("upgrade", 0.0)
	if is_instance_valid(player):
		player.refresh_stats()
	_show_end()


func _show_end() -> void:
	var has_next := zone_index + 1 < ZoneData.ZONES.size()
	var title := "Zone sécurisée !"
	var text := "La contamination recule à %s.\nMutants éliminés au total : %d." % [zone["name"], GameState.total_kills]
	if not has_next:
		title = "Kouaoua est sauvée !"
		text = "Le minerai est neutralisé et la faune du Caillou peut guérir.\nMerci d'avoir joué, gardien.\nMutants éliminés au total : %d." % GameState.total_kills
	hud.show_end(title, text, has_next)


func _on_next_zone() -> void:
	get_tree().paused = false
	GameState.current_zone = zone_index + 1
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_zone_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/zone_select.tscn")


func _on_restart() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# ---------------------------------------------------------------- mort et réapparition

func _on_player_died() -> void:
	var previous := state
	state = "dead"
	hud.show_message("Vous êtes tombé...\nRéapparition", 2.0)
	await get_tree().create_timer(2.3).timeout
	_clear_enemies()
	for child in world.get_children():
		if child is ToxicDrop or child is Javelin:
			child.queue_free()
	player.respawn(spawn_point)
	Audio.play_music("zone_%d" % zone_index)
	match previous:
		"boss":
			_start_boss()
		"between":
			if wave < WAVES:
				_start_wave(wave + 1)
			else:
				_start_boss()
		_:
			_start_wave(maxi(wave, 1))


func _clear_enemies() -> void:
	for enemy in alive_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	alive_enemies.clear()
	spawn_queue.clear()
	if boss != null and is_instance_valid(boss):
		boss.queue_free()
	boss = null
	hud.hide_boss()
