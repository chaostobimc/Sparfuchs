extends Control
class_name ClockFace
## Analoges Zifferblatt mit draggbarem Minutenzeiger.
## Die Werte `hour` (0..23) und `minute` (0..59) können auch extern gesetzt werden.

signal changed(hour: int, minute: int)

var hour: int = 0
var minute: int = 0

func _draw() -> void:
    var cx: float = size.x / 2.0
    var cy: float = size.y / 2.0
    var r: float = min(size.x, size.y) * 0.45
    
    # Hintergrundkreis (statt draw_colored_circle, das nicht existiert)
    draw_circle(Vector2(cx, cy), r, Color(0.12, 0.12, 0.14, 1.0))
    draw_circle(Vector2(cx, cy), r - 2.0, Color(0.0, 0.0, 0.0, 1.0))
    
    for i in 12:
        var a: float = deg_to_rad(i * 30.0 - 90.0)
        var major: bool = i % 3 == 0
        var x1: float = cx + cos(a) * (r - 8.0)
        var y1: float = cy + sin(a) * (r - 8.0)
        var x2: float = cx + cos(a) * (r - (18.0 if major else 12.0))
        var y2: float = cy + sin(a) * (r - (18.0 if major else 12.0))
        draw_line(Vector2(x1, y1), Vector2(x2, y2), Color(0.8, 0.8, 0.8, 0.8), 2.0 if major else 1.0)
        
    _draw_hand(cx, cy, r * 0.78, minute * 6.0 - 90.0, Color(0.85, 0.85, 0.85), 4.0)
    var hour_angle: float = ((hour % 12) + minute / 60.0) * 30.0 - 90.0
    _draw_hand(cx, cy, r * 0.5, hour_angle, Color(0.95, 0.8, 0.6), 7.0)
    draw_circle(Vector2(cx, cy), 5.0, Color(0.7, 0.7, 0.7, 1.0))

func _draw_hand(cx: float, cy: float, length: float, angle_deg: float, color: Color, width: float) -> void:
    var a: float = deg_to_rad(angle_deg)
    var ex: float = cx + cos(a) * length
    var ey: float = cy + sin(a) * length
    draw_line(Vector2(cx, cy), Vector2(ex, ey), color, width)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _drag(event.position)
    elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_LEFT:
        _drag(event.position)

func _drag(pos: Vector2) -> void:
    var cx: float = size.x / 2.0
    var cy: float = size.y / 2.0
    var ang: float = rad_to_deg(atan2(pos.y - cy, pos.x - cx))
    minute = int(round((ang + 90.0) / 6.0)) % 60
    if minute < 0:
        minute += 60
    changed.emit(hour, minute)
