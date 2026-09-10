class_name Player
extends CharacterBody2D
## Le gardien : déplacement, saut (double saut si débloqué), coup de lance, lancer de javelot, PV, mort.

signal hp_changed(hp: int, max_hp: int)
signal throw_cooldown_changed(remaining: float, total: float)
signal died

const GRAVITY := 980.0
const JUMP_VELOCITY := -350.0
const ATTACK_DURATION := 0.2
const THROW_DURATION := 0.25
const THROW_SPEED := 460.0
const INVULN_TIME := 1.0
const RUN_FRAME_TIME := 0.11

const TEX_IDLE := preload("res://assets/sprites/player_idle.png")
const TEX_RUN := [preload("res://assets/sprites/player_run_0.png"), preload("res://assets/sprites/player_run_1.png")]
const TEX_JUMP := preload("res://assets/sprites/player_jump.png")
const TEX_ATTACK := preload("res://assets/sprites/player_attack.png")
const TEX_THROW := preload("res://assets/sprites/player_throw.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var camera: Camera2D = $Camera2D

var hp: int = 100
var max_hp: int = 100
var facing: int = 1
var dead := false

var attack_timer := 0.0
var attack_cooldown := 0.0
var throw_timer := 0.0
var throw_cooldown := 0.0
var invuln_timer := 0.0
var coyote_timer := 0.0
var jump_buffer := 0.0
var air_jumps := 0
var anim_time := 0.0
var hit_enemies: Array = []


func _ready() -> void:
	refresh_stats()
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	throw_cooldown_changed.emit(0.0, GameState.get_throw_cooldown())


## Recalcule les statistiques après un buff ou une amélioration.
func refresh_stats() -> void:
	var old_max := max_hp
	max_hp = GameState.get_max_hp()
	if max_hp > old_max:
		hp += max_hp - old_max
	hp = mini(hp, max_hp)
	hp_changed.emit(hp, max_hp)


func heal(amount: int) -> void:
	if dead:
		return
	hp = mini(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)
	if amount > 0:
		Fx.float_text(get_parent(), global_position, "+%d" % amount, Color(0.5, 1.0, 0.5))
		if amount >= 10:
			Audio.play("heal", 0.0, -6.0)


func _physics_process(delta: float) -> void:
	if dead:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		velocity.y += GRAVITY * delta
		move_and_slide()
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	throw_timer = maxf(throw_timer - delta, 0.0)
	invuln_timer = maxf(invuln_timer - delta, 0.0)
	jump_buffer = maxf(jump_buffer - delta, 0.0)
	if throw_cooldown > 0.0:
		throw_cooldown = maxf(throw_cooldown - delta, 0.0)
		throw_cooldown_changed.emit(throw_cooldown, GameState.get_throw_cooldown())

	# --- déplacement horizontal
	var dir := Input.get_axis("move_left", "move_right")
	var speed := GameState.get_speed()
	var accel := speed * (12.0 if is_on_floor() else 7.0)
	velocity.x = move_toward(velocity.x, dir * speed, accel * delta)
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1

	# --- gravité, coyote time et double saut
	if is_on_floor():
		coyote_timer = 0.1
		air_jumps = 1 if GameState.has_double_jump() else 0
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)
		velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.12
	if jump_buffer > 0.0:
		if coyote_timer > 0.0:
			_jump()
			Audio.play("jump")
		elif air_jumps > 0:
			air_jumps -= 1
			_jump()
			Audio.play("double_jump")
			Fx.spark(get_parent(), global_position + Vector2(0, 28), 1.5)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	# --- coup de lance
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0 and throw_timer <= 0.0:
		attack_timer = ATTACK_DURATION
		attack_cooldown = GameState.get_attack_cooldown()
		hit_enemies.clear()
		Audio.play("attack", 0.1)
	attack_area.scale.x = float(facing)
	if attack_timer > 0.0:
		_apply_attack()

	# --- lancer de javelot
	if Input.is_action_just_pressed("throw") and throw_cooldown <= 0.0 and attack_timer <= 0.0:
		_throw()

	move_and_slide()
	_update_animation(delta, dir)


func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	jump_buffer = 0.0
	coyote_timer = 0.0


func _apply_attack() -> void:
	var damage := GameState.get_damage()
	for body in attack_area.get_overlapping_bodies():
		if body is Enemy and not (body in hit_enemies):
			hit_enemies.append(body)
			body.take_damage(damage, global_position)
			var steal := int(round(damage * GameState.get_lifesteal()))
			if steal > 0:
				heal(steal)


func _throw() -> void:
	throw_timer = THROW_DURATION
	throw_cooldown = GameState.get_throw_cooldown()
	throw_cooldown_changed.emit(throw_cooldown, throw_cooldown)
	var javelin := Javelin.new()
	javelin.global_position = global_position + Vector2(facing * 14, -6)
	javelin.velocity = Vector2(facing * THROW_SPEED, -40.0)
	javelin.damage = GameState.get_damage() * GameState.THROW_DAMAGE_MULT
	javelin.owner_position = global_position
	get_parent().add_child(javelin)
	Audio.play("throw")


func _update_animation(delta: float, dir: float) -> void:
	sprite.flip_h = facing < 0
	sprite.offset = Vector2.ZERO
	if attack_timer > 0.0:
		sprite.texture = TEX_ATTACK
		# la texture d'attaque est plus large (lance tendue) : on recale le corps
		sprite.offset = Vector2(9 * facing, 1)
	elif throw_timer > 0.0:
		sprite.texture = TEX_THROW
	elif not is_on_floor():
		sprite.texture = TEX_JUMP
	elif absf(velocity.x) > 12.0 and dir != 0.0:
		anim_time += delta
		var frame := int(anim_time / RUN_FRAME_TIME) % 2
		sprite.texture = TEX_RUN[frame]
	else:
		anim_time = 0.0
		sprite.texture = TEX_IDLE
	# clignotement pendant l'invulnérabilité
	if invuln_timer > 0.0:
		sprite.modulate.a = 0.35 if int(invuln_timer * 20.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0


func take_damage(amount: int, from_position: Vector2) -> void:
	if dead or invuln_timer > 0.0:
		return
	hp = maxi(hp - amount, 0)
	invuln_timer = INVULN_TIME
	var push_dir := signf(global_position.x - from_position.x)
	if push_dir == 0.0:
		push_dir = -float(facing)
	velocity = Vector2(push_dir * 190.0, -170.0)
	hp_changed.emit(hp, max_hp)
	Fx.float_text(get_parent(), global_position, "-%d" % amount, Color(1.0, 0.4, 0.4))
	if hp <= 0:
		_die()
	else:
		Audio.play("player_hurt")


func _die() -> void:
	dead = true
	sprite.texture = TEX_JUMP
	sprite.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(sprite, "rotation", deg_to_rad(90.0 * facing), 0.4)
	t.parallel().tween_property(sprite, "modulate", Color(0.6, 0.3, 0.6, 0.7), 0.4)
	Audio.play("player_die", 0.0)
	died.emit()


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	dead = false
	sprite.rotation = 0.0
	sprite.modulate = Color.WHITE
	refresh_stats()
	hp = max_hp
	invuln_timer = 1.2
	throw_cooldown = 0.0
	throw_cooldown_changed.emit(0.0, GameState.get_throw_cooldown())
	hp_changed.emit(hp, max_hp)
	Audio.play("respawn", 0.0)
