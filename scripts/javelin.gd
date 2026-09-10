class_name Javelin
extends Area2D
## Javelot lancé par le gardien : vole loin, transperce jusqu'à 2 mutants, se plante puis disparaît.

const TEXTURE := preload("res://assets/sprites/javelin.png")
const GRAVITY := 260.0
const MAX_PIERCE := 2

var velocity := Vector2.ZERO
var damage := 30.0
var life := 2.5
var pierced := 0
var stuck := false
var owner_position := Vector2.ZERO
var hit_bodies: Array = []

@onready var sprite: Sprite2D = Sprite2D.new()


func _ready() -> void:
	sprite.texture = TEXTURE
	sprite.scale = Vector2(2, 2)
	add_child(sprite)
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 8)
	shape_node.shape = shape
	add_child(shape_node)
	collision_layer = 0
	collision_mask = 1 | 4   # monde + ennemis
	z_index = 8
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if stuck:
		life -= delta
		if life <= 0.6:
			modulate.a = life / 0.6
		if life <= 0.0:
			queue_free()
		return
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation = velocity.angle()
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if stuck:
		return
	if body is Enemy:
		if body in hit_bodies:
			return
		hit_bodies.append(body)
		body.take_damage(damage, owner_position)
		pierced += 1
		if pierced >= MAX_PIERCE:
			_stick()
	elif body is StaticBody2D:
		_stick()


func _stick() -> void:
	stuck = true
	life = 1.2
	Fx.spark(get_parent(), global_position, 1.5)
	set_deferred("monitoring", false)
