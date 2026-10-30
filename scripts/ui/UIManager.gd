extends Node
## UI-Manager (Autoload). Besitzt die gesamte 2D-Oberfläche:
## - HUD: Ziel-Text, Interaktionshinweis, Kreuz, Nachrichten-Toast
## - Überlagerungen: Notizen-Leser, Keypad (Safe), Uhr (Penthouse), Pause
## - Finale Jumpscare-Strobe
## Alle Szenen kommunizieren mit ihm via `UIManager.<methode>()`.

signal pause_toggled(paused: bool)
signal keypad_solved(code: String)
signal clock_solved()

var _canvas: CanvasLayer
@onready var _crosshair_res: GDScript = load("res://scripts/ui/Crosshair.gd")
@onready var _jumpscare_res: GDScript = load("res://scripts/ui/JumpscareScreen.gd")
@onready var _keypad_res: GDScript = load("res://scripts/ui/KeypadUI.gd")
@onready var _clock_res: GDScript = load("res://scripts/ui/ClockUI.gd")

var _game_active: bool = false
var _paused: bool = false

# HUD-Knoten
var _crosshair: Control
var _objective_label: Label
var _prompt_label: Label
var _note_count: Label
var _toast_panel: Panel
var _toast_label: Label
var _toast_tween: Tween

# Überlagerungen
var _note_reader: Control
var _keypad: Control
var _clock: Control
var _pause: Control
var _jumpscare: JumpscareScreen

func _ready() -> void:
    _canvas = CanvasLayer.new()
    add_child(_canvas)
    _canvas.screen_rect = true
    _build_hud()
    _build_pause()
    _build_jumpscare()
    GameManager.message_requested.connect(show_message)
    GameManager.objective_changed.connect(_on_objective)
    GameManager.note_added.connect(update_note_count)
    update_note_count()

# ---------------------------------------------------------------------------
# HUD
# ---------------------------------------------------------------------------

func _build_hud() -> void:
    _crosshair = _crosshair_res.new() as Control
    _crosshair.set_anchors_preset(Control.PRESET_FULL_RECT)
    _canvas.add_child(_crosshair)

    _objective_label = Label.new()
    _objective_label.text = ""
    _objective_label.position = Vector2(20, 18)
    _objective_label.size = Vector2(720, 90)
    _objective_label.add_theme_font_size_override("font_size", 15)
    _objective_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.85))
    _objective_label.visible = false
    _canvas.add_child(_objective_label)

    _prompt_label = Label.new()
    _prompt_label.set_anchors_preset(Control.PRESET_FULL_RECT)
    _prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_MIDDLE
    _prompt_label.add_theme_font_size_override("font_size", 18)
    _prompt_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
    _prompt_label.visible = false
    _canvas.add_child(_prompt_label)

    _note_count = Label.new()
    _note_count.text = "Notizen: 0"
    _note_count.set_anchors_preset(Control.PRESET_FULL_RECT)
    _note_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _note_count.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    _note_count.set_position(Vector2(-20, 20))
    _note_count.set_size(Vector2(220, 30))
    _note_count.add_theme_font_size_override("font_size", 13)
    _note_count.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
    _note_count.visible = false
    _canvas.add_child(_note_count)

    _toast_panel = Panel.new()
    _toast_panel.position = Vector2(340, 90)
    _toast_panel.size = Vector2(600, 90)
    _toast_panel.visible = false
    _canvas.add_child(_toast_panel)
    _toast_label = Label.new()
    _toast_label.text = ""
    _toast_label.position = Vector2(20, 20)
    _toast_label.size = Vector2(560, 50)
    _toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _toast_label.vertical_alignment = VERTICAL_ALIGNMENT_MIDDLE
    _toast_label.add_theme_font_size_override("font_size", 18)
    _toast_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
    _toast_panel.add_child(_toast_label)

func set_game_active(active: bool) -> void:
    _game_active = active
    _crosshair.visible = active
    _objective_label.visible = active
    _prompt_label.visible = active
    _note_count.visible = active
    _toast_panel.visible = false
    if active:
        _on_objective(GameManager.current_objective)
    if not active:
        hide_pause()
        hide_note_reader()
        hide_keypad()
        hide_clock()

func set_prompt(text: String) -> void:
    _prompt_label.text = text
    _prompt_label.visible = _game_active and not text.is_empty()

## Gibt true zurück, wenn ein Modal-Overlay (Keypad, Uhr, Notizen, Pause) offen ist.
func any_overlay_open() -> bool:
    if _pause and _pause.visible:
        return true
    if _note_reader:
        return true
    if _keypad:
        return true
    if _clock:
        return true
    return false

func _on_objective(text: String) -> void:
    if _game_active:
        _objective_label.text = text

func update_note_count() -> void:
    _note_count.text = "Notizen: " + str(GameManager.notes.size())

func show_message(text: String, style: String = "info") -> void:
    if not _game_active:
        return
    _toast_label.text = text
    match style:
        "success":
            _toast_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
        "danger":
            _toast_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
        _:
            _toast_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
    _toast_panel.visible = true
    _toast_panel.modulate.a = 0.0
    if _toast_tween:
        _toast_tween.kill()
    _toast_tween = create_tween()
    _toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.08)
    _toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 3.2).done(func():
        _toast_panel.visible = false)

# ---------------------------------------------------------------------------
# Noten-Leser
# ---------------------------------------------------------------------------

func show_note_reader(note_id: String) -> void:
    if not GameManager.has_note(note_id):
        return
    var data := GameManager.get_note(note_id)
    hide_keypad()
    hide_clock()
    DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_NORMAL)
    _note_reader = Control.new()
    _note_reader.set_anchors_preset(Control.PRESET_FULL_RECT)
    _note_reader.mouse_filter = Control.MOUSE_FILTER_STOP
    var panel := Panel.new()
    panel.position = Vector2(180, 110)
    panel.size = Vector2(620, 540)
    _note_reader.add_child(panel)

    var title := Label.new()
    title.text = data["title"]
    title.position = Vector2(24, 16)
    title.add_theme_font_size_override("font_size", 18)
    title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6))
    panel.add_child(title)

    var body := RichTextLabel.new()
    body.text = data["body"]
    body.position = Vector2(24, 60)
    body.size = Vector2(570, 380)
    body.add_theme_font_size_override("normal_font_size", 15)
    body.add_theme_color_override("normal_font_color", Color(0.88, 0.88, 0.85))
    panel.add_child(body)

    var close := Button.new()
    close.text = "Verlassen"
    close.position = Vector2(470, 470)
    close.size = Vector2(130, 40)
    close.pressed.connect(hide_note_reader)
    panel.add_child(close)
    _canvas.add_child(_note_reader)

func hide_note_reader() -> void:
    if _note_reader:
        _note_reader.queue_free()
        _note_reader = null
    if _game_active:
        DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_LOCKED)

## Schließt das oberste offene Overlay (Uhr > Keypad > Notizen) und sperrt die Maus wieder.
func close_top_overlay() -> void:
    if _clock:
        hide_clock()
    elif _keypad:
        hide_keypad()
    elif _note_reader:
        hide_note_reader()

# ---------------------------------------------------------------------------
# Keypad (Safe)
# ---------------------------------------------------------------------------

func open_keypad(target_code: String = "10449") -> void:
    hide_note_reader()
    hide_clock()
    DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_NORMAL)
    _keypad = _keypad_res.new() as Control
    _keypad.target_code = target_code
    _keypad.solved.connect(_on_keypad_solved)
    _keypad.cancelled.connect(hide_keypad)
    _canvas.add_child(_keypad)

func hide_keypad() -> void:
    if _keypad:
        _keypad.queue_free()
        _keypad = null
    if _game_active:
        DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_LOCKED)

func _on_keypad_solved(code: String) -> void:
    hide_keypad()
    GameManager.set_flag("act1_safe_open", true)
    keypad_solved.emit(code)
    GameManager.show_message("Der Safe ist offen! Der Korridor ist jetzt zugänglich.", "success")

# ---------------------------------------------------------------------------
# Uhr (Penthouse)
# ---------------------------------------------------------------------------

func open_clock() -> void:
    hide_note_reader()
    hide_keypad()
    DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_NORMAL)
    _clock = _clock_res.new() as Control
    _clock.solved.connect(_on_clock_solved)
    _clock.cancelled.connect(hide_clock)
    _canvas.add_child(_clock)

func hide_clock() -> void:
    if _clock:
        _clock.queue_free()
        _clock = null
    if _game_active:
        DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_LOCKED)

func _on_clock_solved() -> void:
    hide_clock()
    GameManager.set_flag("act3_clock_solved", true)
    clock_solved.emit()
    GameManager.show_message("Ein schweres Zahnrad klickt ein. Die Geheimtür zur Terrasse öffnet sich.", "success")

# ---------------------------------------------------------------------------
# Pause
# ---------------------------------------------------------------------------

func _build_pause() -> void:
    _pause = Control.new()
    _pause.set_anchors_preset(Control.PRESET_FULL_RECT)
    _pause.visible = false
    _pause.mouse_filter = Control.MOUSE_FILTER_STOP
    var panel := Panel.new()
    panel.position = Vector2(330, 200)
    panel.size = Vector2(400, 260)
    _pause.add_child(panel)
    var title := Label.new()
    title.text = "PAUSE"
    title.position = Vector2(20, 20)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
    panel.add_child(title)
    var hint := Label.new()
    hint.text = "Klicke, um das Spiel fortzusetzen."
    hint.position = Vector2(20, 120)
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 14)
    hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
    panel.add_child(hint)
    var cont := Button.new()
    cont.text = "Fortsetzen"
    cont.position = Vector2(140, 180)
    cont.size = Vector2(120, 40)
    cont.pressed.connect(func():
        hide_pause()
        DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_LOCKED))
    panel.add_child(cont)
    _canvas.add_child(_pause)

func show_pause() -> void:
    if not _game_active:
        return
    _pause.visible = true
    DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_NORMAL)
    pause_toggled.emit(true)

func hide_pause() -> void:
    _pause.visible = false
    pause_toggled.emit(false)

# ---------------------------------------------------------------------------
# Jumpscare (Finale)
# ---------------------------------------------------------------------------

func _build_jumpscare() -> void:
    _jumpscare = _jumpscare_res.new() as JumpscareScreen
    _jumpscare.set_anchors_preset(Control.PRESET_FULL_RECT)
    _jumpscare.visible = false
    _jumpscare.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _canvas.add_child(_jumpscare)

func show_jumpscare() -> void:
    _jumpscare.visible = true
    AudioManager.sfx("scream")
    AudioManager.sfx("thunder")
    var colors := [Color(1, 0, 0, 1), Color(1, 1, 1, 1), Color(0.2, 0, 0, 1), Color(1, 1, 0, 1)]
    var strobe := create_tween()
    strobe.set_loops()
    for i in 8:
        strobe.tween_property(_jumpscare, "flash_color", colors[i % 4], 0.05)
    await get_tree().create_timer(0.5).timeout
    strobe.stop()
    _jumpscare.flash_color = Color(0, 0, 0, 1)
    await get_tree().create_timer(0.8).timeout
    _quit_game()

func _quit_game() -> void:
    _jumpscare.flash_color = Color(0, 0, 0, 1)
    await get_tree().create_timer(1.2).timeout
    get_tree().quit()
