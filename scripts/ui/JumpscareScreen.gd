extends Control
## Vollscreen-Überlagerung für den Final-Jumpscare.
## Der UIManager wechselt `flash_color` in rasender Folge (Strobe).

var flash_color: Color = Color(0, 0, 0, 1)

func _draw() -> void:
    draw_rect(Rect2(0, 0, size.x, size.y), flash_color)
