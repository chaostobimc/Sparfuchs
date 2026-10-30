extends Control
## On-Screen-Uhr für das Penthouse-Rätsel (Akt 3).
## Die Zeiger können per Maus dragged (Minutenzeiger) oder mit +/-Buttons
## eingestellt werden. Ziel: 22:55 (bzw. 10:55).

signal solved()
signal cancelled()

@export var title_text: String = "STANDUHR - PENTHOUSE"
@export var target_hour: int = 22
@export var target_minute: int = 55

var _hour: int = 0
var _minute: int = 0
var _panel: Panel
var _face: ClockFace
var _display: Label
var _status: Label
var _solved: bool = false

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build()

func _build() -> void:
    _panel = Panel.new()
    _panel.position = Vector2(140, 60)
    _panel.size = Vector2(420, 560)
    add_child(_panel)

    var title := Label.new()
    title.text = title_text
    title.position = Vector2(20, 16)
    title.add_theme_font_size_override("font_size", 20)
    title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
    _panel.add_child(title)

    _display = Label.new()
    _display.text = "00:00"
    _display.position = Vector2(40, 50)
    _display.size = Vector2(340, 40)
    _display.horizontal_alignment = Control.HORIZONTAL_ALIGNMENT_CENTER
    _display.add_theme_font_size_override("font_size", 26)
    _display.add_theme_color_override("font_color", Color(0.35, 0.9, 0.5))
    _panel.add_child(_display)

    _face = ClockFace.new()
    _face.position = Vector2(70, 100)
    _face.size = Vector2(280, 280)
    _face.mouse_filter = Control.MOUSE_FILTER_STOP
    _face.changed.connect(_on_face_changed)
    _panel.add_child(_face)

    _status = Label.new()
    _status.text = "Ziel: 22:55  (10:55 Uhr)"
    _status.position = Vector2(30, 410)
    _status.size = Vector2(360, 30)
    _status.horizontal_alignment = Control.HORIZONTAL_ALIGNMENT_CENTER
    _status.add_theme_font_size_override("font_size", 14)
    _status.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
    _panel.add_child(_status)

    var by := 450.0
    var bw := 90.0
    var bh := 46.0
    var gap := 10.0
    var x0 := 40.0
    _make_btn(_panel, "Stunde -", Vector2(x0, by), bw, bh, func(): _hour = (_hour - 1 + 24) % 24)
    _make_btn(_panel, "Stunde +", Vector2(x0 + (bw + gap), by), bw, bh, func(): _hour = (_hour + 1) % 24)
    _make_btn(_panel, "Minute -", Vector2(x0, by + (bh + gap)), bw, bh, func(): _minute = (_minute - 1 + 60) % 60)
    _make_btn(_panel, "Minute +", Vector2(x0 + (bw + gap), by + (bh + gap)), bw, bh, func(): _minute = (_minute + 1) % 60)

    var reset := Button.new()
    reset.text = "Reset"
    reset.position = Vector2(x0 + 2 * (bw + gap), by + (bh + gap))
    reset.size = Vector2(bw, bh)
    reset.pressed.connect(func():
        _hour = 0
        _minute = 0
        AudioManager.sfx("click"))
    _panel.add_child(reset)

    var close := Button.new()
    close.text = "Abbrechen"
    close.position = Vector2(x0 + 3 * (bw + gap), by)
    close.size = Vector2(bw, bh)
    close.pressed.connect(_on_cancel)
    _panel.add_child(close)

func _make_btn(parent: Control, text: String, pos: Vector2, w: float, h: float, cb: Callable) -> void:
    var b := Button.new()
    b.text = text
    b.position = pos
    b.size = Vector2(w, h)
    b.add_theme_font_size_override("font_size", 16)
    b.pressed.connect(cb)
    parent.add_child(b)

func _on_face_changed(h: int, m: int) -> void:
    _minute = m
    _update()

func _update() -> void:
    _face.hour = _hour
    _face.minute = _minute
    _display.text = "%02d:%02d" % [_hour, _minute]
    if not _solved and _minute == target_minute and (_hour == target_hour or (_hour == 10 and target_hour == 22)):
        _solved = true
        _status.text = "Richtig! Die Geheimtür öffnet sich."
        _status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
        AudioManager.sfx("lock")
        solved.emit()

func _on_cancel() -> void:
    cancelled.emit()
