extends Control
## Analoges Zifferblatt mit draggbarem Minutenzeiger.
## Die Werte `hour` (0..23) und `minute` (0..59) können auch extern gesetzt werden.

signal changed(hour: int, minute: int)

var hour: int = 0
var minute: int = 0

func _draw() -> void:
    var cx := size.x / 2.0
    var cy := size.y / 2.0
    var r := min(size.x, size.y) * 0.45
    draw_circle(Vector2(cx, cy), r, Color(0.12, 0.12, 0.14, 1.0))
    draw_colored_circle(Vector2(cx, cy), r, Color(0.0, 0.0, 0.0, 1.0))
    for i in 12:
        var a := deg_to_rad(i * 30.0 - 90.0)
        var major := i % 3 == 0
        var x1 := cx + cos(a) * (r - 8)
        var y1 := cy + sin(a) * (r - 8)
        var x2 := cx + cos(a) * (r - (18 if major else 12))
        var y2 := cy + sin(a) * (r - (18 if major else 12))
        draw_line(Vector2(x1, y1), Vector2(x2, y2), Color(0.8, 0.8, 0.8, 0.8), 2.0 if major else 1.0)
    _draw_hand(cx, cy, r * 0.78, minute * 6.0 - 90.0, Color(0.85, 0.85, 0.85), 4.0)
    var hour_angle := ((hour % 12) + minute / 60.0) * 30.0 - 90.0
    _draw_hand(cx, cy, r * 0.5, hour_angle, Color(0.95, 0.8, 0.6), 7.0)
    draw_circle(Vector2(cx, cy), 5.0, Color(0.7, 0.7, 0.7, 1.0))

func _draw_hand(cx: float, cy: float, length: float, angle_deg: float, color: Color, width: float) -> void:
    var a := deg_to_rad(angle_deg)
    var ex := cx + cos(a) * length
    var ey := cy + sin(a) * length
    draw_line(Vector2(cx, cy), Vector2(ex, ey), color, width)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _drag(event.position)
    elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_LEFT:
        _drag(event.position)

func _drag(pos: Vector2) -> void:
    var cx := size.x / 2.0
    var cy := size.y / 2.0
    var ang := rad_to_deg(atan2(pos.y - cy, pos.x - cx))
    minute = int(round((ang + 90.0) / 6.0)) % 60
    if minute < 0:
        minute += 60
    changed.emit(hour, minute)
