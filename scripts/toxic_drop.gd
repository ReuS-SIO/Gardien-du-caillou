class_name ToxicDrop
extends Area2D
## Goutte toxique crachée par un boss : trajectoire balistique, blesse le joueur au contact.

const TEXTURE := preload("res://assets/sprites/toxic_drop.png")
const GRAVITY := 500.0

var velocity := Vector2.ZERO
var damage := 10
var life := 3.0


func _ready() -> void:
	var s := Sprite2D.new()
	s.texture = TEXTURE
	s.scale = Vector2(2, 2)
	add_child(s)
	var c := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	c.shape = shape
	add_child(c)
	collision_layer = 0
	collision_mask = 1 | 2
	z_index = 10
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation = velocity.angle() + PI * 0.5
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(damage, global_position)
	Fx.spark(get_parent(), global_position, 1.5)
	Audio.play("splash", 0.15, -6.0)
	queue_free()
