class_name Enemy
extends CharacterBody2D
## Mutant de base : IA simple (poursuite, saut, charge, vol), dégâts de contact, PV.

signal died(enemy: Enemy)

const GRAVITY := 900.0
const JUMP_VELOCITY := -330.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var data: Dictionary = {}
var target: Node2D
var hp: float = 10.0
var max_hp: float = 10.0
var speed: float = 60.0
var damage: int = 10
var flying := false
var charger := false
var is_dead := false
var half_height := 12.0
var base_scale := 2.0

var dir: int = 1
var flash_timer := 0.0
var stun_timer := 0.0
var hover_time := 0.0
var anim_time := 0.0
var jump_cooldown := 0.0
var knockback := Vector2.ZERO

# machine à états de la charge (cochon sauvage) : 0 poursuite, 1 préparation, 2 charge, 3 récupération
var charge_state := 0
var charge_timer := 0.0
var charge_cooldown := 0.0


func setup(enemy_data: Dictionary, difficulty: float, tex_scale: float = 2.0) -> void:
	data = enemy_data
	base_scale = tex_scale
	max_hp = float(data["hp"]) * difficulty
	hp = max_hp
	speed = float(data["speed"]) * (1.0 + (difficulty - 1.0) * 0.25)
	damage = int(round(float(data["damage"]) * difficulty))
	flying = bool(data.get("flying", false))
	charger = bool(data.get("charger", false))
	if not is_node_ready():
		await ready
	sprite.texture = load(data["texture"])
	sprite.scale = Vector2(tex_scale, tex_scale)
	var size: Vector2 = sprite.texture.get_size() * tex_scale
	half_height = size.y * 0.5
	var body_rect := RectangleShape2D.new()
	body_rect.size = Vector2(size.x * 0.75, size.y * 0.9)
	body_shape.shape = body_rect
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = Vector2(size.x * 0.85, size.y * 0.9)
	hitbox_shape.shape = hit_rect


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if flash_timer > 0.0:
		flash_timer -= delta
		sprite.modulate = Color(4, 4, 4) if flash_timer > 0.0 else Color.WHITE
	if not is_instance_valid(target):
		return
	var to_target: Vector2 = target.global_position - global_position
	if stun_timer > 0.0:
		# étourdi par un coup : subit seulement la gravité et le recul
		stun_timer -= delta
		if not flying:
			velocity.y += GRAVITY * delta
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		else:
			velocity = velocity.lerp(Vector2.ZERO, 4.0 * delta)
	elif flying:
		_fly(delta, to_target)
	else:
		_walk(delta, to_target)
	velocity += knockback
	knockback = Vector2.ZERO
	move_and_slide()
	if stun_timer <= 0.0:
		_check_contact()
	_animate(delta)


func _walk(delta: float, to_target: Vector2) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	jump_cooldown = maxf(jump_cooldown - delta, 0.0)
	charge_cooldown = maxf(charge_cooldown - delta, 0.0)
	if absf(to_target.x) > 6.0:
		dir = 1 if to_target.x > 0.0 else -1

	if charger:
		_charge_logic(delta, to_target)
		return

	velocity.x = move_toward(velocity.x, dir * speed, speed * 8.0 * delta)
	_try_jump(to_target)


func _charge_logic(delta: float, to_target: Vector2) -> void:
	charge_timer -= delta
	match charge_state:
		0:
			velocity.x = move_toward(velocity.x, dir * speed, speed * 8.0 * delta)
			_try_jump(to_target)
			if charge_cooldown <= 0.0 and absf(to_target.x) < 230.0 and absf(to_target.y) < 40.0 and is_on_floor():
				charge_state = 1
				charge_timer = 0.45
		1:
			velocity.x = move_toward(velocity.x, 0.0, speed * 10.0 * delta)
			sprite.modulate = Color(1.6, 1.0, 1.0)
			if charge_timer <= 0.0:
				charge_state = 2
				charge_timer = 0.6
				sprite.modulate = Color.WHITE
		2:
			velocity.x = dir * speed * 2.8
			if charge_timer <= 0.0 or is_on_wall():
				charge_state = 3
				charge_timer = 1.2
				charge_cooldown = 2.2
		3:
			velocity.x = move_toward(velocity.x, dir * speed * 0.5, speed * 6.0 * delta)
			if charge_timer <= 0.0:
				charge_state = 0


func _try_jump(to_target: Vector2) -> void:
	if not is_on_floor() or jump_cooldown > 0.0:
		return
	var wants_jump := is_on_wall() or (to_target.y < -50.0 and absf(to_target.x) < 120.0 and randf() < 0.05)
	if wants_jump:
		velocity.y = JUMP_VELOCITY
		jump_cooldown = 0.8


func _fly(delta: float, to_target: Vector2) -> void:
	hover_time += delta
	var desired := to_target.normalized() * speed
	desired.y += sin(hover_time * 5.0) * 45.0
	velocity = velocity.lerp(desired, 3.0 * delta)
	if absf(to_target.x) > 6.0:
		dir = 1 if to_target.x > 0.0 else -1


func _check_contact() -> void:
	for body in hitbox.get_overlapping_bodies():
		if body is Player:
			body.take_damage(damage, global_position)


func _animate(delta: float) -> void:
	sprite.flip_h = dir < 0
	anim_time += delta
	var moving := velocity.length() > 15.0
	var wobble := 0.08 * sin(anim_time * 14.0) if moving else 0.0
	sprite.scale = Vector2(base_scale * (1.0 - wobble), base_scale * (1.0 + wobble))


func take_damage(amount: float, from_position: Vector2) -> void:
	if is_dead:
		return
	hp -= amount
	flash_timer = 0.1
	stun_timer = 0.28
	if charge_state == 2:
		charge_state = 3
		charge_timer = 1.0
		charge_cooldown = 2.0
	var push := signf(global_position.x - from_position.x)
	if push == 0.0:
		push = 1.0
	knockback = Vector2(push * 170.0, 0.0 if flying else -90.0)
	Fx.spark(get_parent(), global_position)
	Fx.float_text(get_parent(), global_position, str(int(round(amount))), Color(1.0, 0.9, 0.4))
	if hp <= 0.0:
		_die()


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	GameState.total_kills += 1
	died.emit(self)
	hitbox.set_deferred("monitoring", false)
	body_shape.set_deferred("disabled", true)
	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2(base_scale * 1.4, base_scale * 0.2), 0.15)
	t.parallel().tween_property(sprite, "modulate", Color(0.8, 1.0, 0.4, 0.0), 0.15)
	t.tween_callback(queue_free)
