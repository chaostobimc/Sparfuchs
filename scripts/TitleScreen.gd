extends Control
## Startbildschirm. Lässt Atmosphären-Audio abspielen und startet das Spiel.

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    AudioManager.start_rain()
    AudioManager.start_ambient()
    AudioManager.set_rain_volume(0.4)
    AudioManager.set_ambient_volume(0.4)
    UIManager.set_game_active(false)
    _build_ui()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.015, 0.015, 0.02)
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var title := Label.new()
    title.text = "THE DIPLOMAT PEAK"
    title.position = Vector2(0, 150)
    title.size = Vector2(1280, 90)
    title.horizontal_alignment = Control.HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 56)
    title.add_theme_color_override("font_color", Color(0.82, 0.86, 0.72))
    add_child(title)

    var sub := Label.new()
    sub.text = "Das letzte Kapitel"
    sub.position = Vector2(0, 245)
    sub.size = Vector2(1280, 50)
    sub.horizontal_alignment = Control.HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size", 28)
    sub.add_theme_color_override("font_color", Color(0.45, 0.55, 0.45))
    add_child(sub)

    var quote := Label.new()
    quote.text = "\"1988 schloss das Diplomat Peak nach einer Sturmnacht für immer.\nHeute, um 23:45 Uhr, betritt Gorgii das vergessene Hotel.\""
    quote.position = Vector2(0, 320)
    quote.size = Vector2(1280, 90)
    quote.horizontal_alignment = Control.HORIZONTAL_ALIGNMENT_CENTER
    quote.add_theme_font_size_override("font_size", 17)
    quote.add_theme_color_override("font_color", Color(0.55, 0.5, 0.45))
    add_child(quote)

    var hint := Label.new()
    hint.text = "Bewegung: WASD    Sprint: Shift    Interagieren: E\nBlinklicht: F    Journal: I/J    Pause: ESC"
    hint.position = Vector2(0, 420)
    hint.size = Vector2(1280, 70)
    hint.horizontal_alignment = Control.HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 16)
    hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
    add_child(hint)

    var btn := Button.new()
    btn.text = "ZUM STARTEN klicken"
    btn.custom_minimum_size = Vector2(340, 72)
    btn.position = Vector2(470, 510)
    btn.add_theme_font_size_override("font_size", 22)
    btn.pressed.connect(_start)
    add_child(btn)

    var credit := Label.new()
    credit.text = "Ein Godot-4 Projekt - vollständig editierbar"
    credit.position = Vector2(0, 640)
    credit.size = Vector2(1280, 30)
    credit.horizontal_alignment = Control.HORIZONTAL_ALIGNMENT_CENTER
    credit.add_theme_font_size_override("font_size", 13)
    credit.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
    add_child(credit)

func _start() -> void:
    DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_LOCKED)
    AudioManager.sfx("door")
    GameManager.load_level("res://scenes/Foyer.tscn")
