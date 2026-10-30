extends Control
## On-Screen-Tastenfeld für den Rezeption-Safe (Akt 1).
## Wird vom UIManager instantiiert. Ziel-Code ist vorgegeben (10449).

signal solved(code: String)
signal cancelled()

@export var target_code: String = "10449"
@export var title_text: String = "PANZERSCHLOSS - REZEPTION"

var _display: Label
var _panel: Panel

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    _build()

func _build() -> void:
    _panel = Panel.new()
    _panel.position = Vector2(110, 80)
    _panel.size = Vector2(460, 540)
    add_child(_panel)

    var title := Label.new()
    title.text = title_text
    title.position = Vector2(20, 16)
    title.add_theme_font_size_override("font_size", 20)
    title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
    _panel.add_child(title)

    _display = Label.new()
    _display.text = "-----"
    _display.position = Vector2(40, 60)
    _display.size = Vector2(380, 60)
    _display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _display.add_theme_font_size_override("font_size", 40)
    _display.add_theme_color_override("font_color", Color(0.35, 0.9, 0.5))
    _panel.add_child(_display)

    var input := ""
    func press(digit: String) -> void:
        if input.length() >= 6:
            return
        input += digit
        _display.text = _mask(input)
        AudioManager.sfx("click")

    func _mask(s: String) -> String:
        var out := ""
        for c in s:
            out += "*"
        return out

    func submit() -> void:
        if input.is_empty():
            return
        if input == target_code:
            _display.text = "****"
            _display.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
            AudioManager.sfx("lock")
            solved.emit(input)
        else:
            _display.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
            AudioManager.sfx("click")
            input = ""
            _display.text = "-----"
            await get_tree().create_timer(0.8).timeout
            _display.add_theme_color_override("font_color", Color(0.35, 0.9, 0.5))
            _display.text = "-----"

    # Tastenlayout 0-9 + C (clear) + OK.
    var cols := 3
    var x0 := 40.0
    var y0 := 150.0
    var bw := 110.0
    var bh := 60.0
    var gap := 15.0
    var order := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"]
    for i in order.size():
        var col := i % cols
        var row := i / cols
        var label := order[i]
        var btn := Button.new()
        btn.text = label
        btn.position = Vector2(x0 + col * (bw + gap), y0 + row * (bh + gap))
        btn.size = Vector2(bw, bh)
        btn.custom_minimum_size = Vector2(bw, bh)
        btn.add_theme_font_size_override("font_size", 20)
        _panel.add_child(btn)
        if label == "OK":
            btn.pressed.connect(submit)
        elif label == "C":
            btn.pressed.connect(func():
                input = ""
                _display.text = "-----"
                AudioManager.sfx("click"))
        else:
            btn.pressed.connect(func(d = label): press(d))

    var hint := Label.new()
    hint.text = "Code = Zimmernummer + Geburtsjahr"
    hint.position = Vector2(30, 478)
    hint.size = Vector2(300, 30)
    hint.add_theme_font_size_override("font_size", 13)
    hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
    _panel.add_child(hint)

    var close := Button.new()
    close.text = "Abbrechen"
    close.position = Vector2(330, 470)
    close.size = Vector2(110, 40)
    close.pressed.connect(_on_cancel)
    _panel.add_child(close)

func _on_cancel() -> void:
    cancelled.emit()
