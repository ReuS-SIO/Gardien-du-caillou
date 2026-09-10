class_name Boss
extends Enemy
## Boss de zone : un mutant imposant avec une attaque spéciale et une phase enragée.

signal boss_hp_changed(hp: float, max_hp: float)

const TEX_DROP := preload("res://assets/sprites/toxic_drop.png")

var game: Node = null
var special_timer := 3.0
var acting := false
var enraged := false


func _physics_process(delta: float) -> void:
	super(delta)
	if is_dead or not is_instance_valid(target):
		return
	special_timer -= delta
	if special_timer <= 0.0 and not acting:
		_do_special()


func _do_special() -> void:
	acting = true
	var interval_min := 2.2 if enraged else 3.2
	var interval_max := 3.5 if enraged else 5.0
	special_timer = randf_range(interval_min, interval_max)
	match str(data.get("special", "")):
		"slam":
			await _special_slam()
		"minions":
			await _special_minions()
		"spit":
			await _special_spit()
		"charge":
			await _special_charge()
		"storm":
			await _special_spit()
			if is_instance_valid(self) and not is_dead:
				await _special_minions()
	if is_instance_valid(self):
		acting = false


## Saute puis s'écrase : onde de choc au sol et gouttes toxiques.
func _special_slam() -> void:
	if not is_on_floor():
		return
	velocity.y = -520.0
	await get_tree().create_timer(0.45).timeout
	var guard := 0
	while is_instance_valid(self) and not is_dead and not is_on_floor() and guard < 240:
		guard += 1
		await get_tree().physics_frame
	if not is_instance_valid(self) or is_dead:
		return
	Fx.spark(get_parent(), global_position + Vector2(0, half_height), 4.0)
	if is_instance_valid(target) and target is Player and target.is_on_floor():
		if absf(target.global_position.x - global_position.x) < 130.0:
			target.take_damage(damage, global_position)
	_spawn_drop(Vector2(-160, -220))
	_spawn_drop(Vector2(160, -220))


func _special_minions() -> void:
	if game == null or not game.has_method("spawn_enemy"):
		return
	sprite.modulate = Color(2.0, 1.2, 2.0)
	await get_tree().create_timer(0.4).timeout
	if not is_instance_valid(self) or is_dead:
		return
	sprite.modulate = Color.WHITE
	var minion_type := str(data.get("minion", "gecko"))
	var count := 3 if enraged else 2
	for i in range(count):
		var offset := Vector2((i - count * 0.5 + 0.5) * 50.0, -20.0)
		game.spawn_enemy(minion_type, global_position + offset, 0.7)


func _special_spit() -> void:
	if not is_instance_valid(target):
		return
	sprite.modulate = Color(1.2, 2.0, 1.2)
	await get_tree().create_timer(0.35).timeout
	if not is_instance_valid(self) or is_dead:
		return
	sprite.modulate = Color.WHITE
	var count := 5 if enraged else 3
	for i in range(count):
		if not is_instance_valid(target):
			break
		var to_target: Vector2 = target.global_position - global_position
		var flight_time := 0.9
		# vitesse balistique pour atteindre le joueur (gravité 500 dans le projectile)
		var vx := to_target.x / flight_time + (i - count * 0.5 + 0.5) * 40.0
		var vy := (to_target.y - 0.5 * 500.0 * flight_time * flight_time) / flight_time
		_spawn_drop(Vector2(vx, vy))
		await get_tree().create_timer(0.12).timeout
		if not is_instance_valid(self) or is_dead:
			return


func _special_charge() -> void:
	if not is_on_floor() or charge_state != 0:
		return
	charge_cooldown = 0.0
	charge_state = 1
	charge_timer = 0.5
	await get_tree().create_timer(2.0).timeout


func _spawn_drop(vel: Vector2) -> void:
	var drop := ToxicDrop.new()
	drop.global_position = global_position
	drop.velocity = vel
	drop.damage = maxi(int(damage * 0.6), 6)
	get_parent().add_child(drop)


func take_damage(amount: float, from_position: Vector2) -> void:
	super(amount, from_position)
	if is_dead:
		return
	boss_hp_changed.emit(hp, max_hp)
	if not enraged and hp <= max_hp * 0.5:
		enraged = true
		speed *= 1.3
		sprite.self_modulate = Color(1.3, 0.8, 1.2)
		Fx.float_text(get_parent(), global_position + Vector2(0, -half_height), "ENRAGÉ !", Color(1.0, 0.4, 1.0))
