extends Control
## Einfaches Wohnkreuz als HUD-Zielpunkt.

func _draw() -> void:
    var c := Vector2(size.x / 2.0, size.y / 2.0)
    var col := Color(0.8, 0.8, 0.8, 0.45)
    draw_line(c - Vector2(12, 0), c + Vector2(12, 0), col, 2.0)
    draw_line(c - Vector2(0, 12), c + Vector2(0, 12), col, 2.0)
    draw_circle(c, 1.5, Color(0.8, 0.8, 0.8, 0.6))
