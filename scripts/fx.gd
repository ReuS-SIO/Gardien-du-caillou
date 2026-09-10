class_name Fx
extends RefCounted
## Petits effets visuels réutilisables (économes : de simples tweens).

const SPARK := preload("res://assets/sprites/hit_spark.png")


static func spark(parent: Node, pos: Vector2, size: float = 2.0) -> void:
	var s := Sprite2D.new()
	s.texture = SPARK
	s.position = pos
	s.scale = Vector2(size, size)
	s.z_index = 20
	parent.add_child(s)
	var t := s.create_tween()
	t.tween_property(s, "scale", Vector2(size * 3.0, size * 3.0), 0.18)
	t.parallel().tween_property(s, "modulate:a", 0.0, 0.18)
	t.tween_callback(s.queue_free)


static func float_text(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos + Vector2(-20, -30)
	l.z_index = 30
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	parent.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "position:y", l.position.y - 28.0, 0.7)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.3)
	t.tween_callback(l.queue_free)
