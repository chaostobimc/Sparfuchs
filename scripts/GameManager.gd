extends Node
## Globaler Spiel-Manager (Autoload).
## Behält den Zustand des gesamten Spiels: Aktueller Akt, Spielstände (Flags),
## Ziele, notierte Fundstücke (Zeitungsartikel) und den Spieler-Vektor.
## Alle Skripte können auf ihn zugreifen via `GameManager.<methode>`.

signal objective_changed(text: String)
signal message_requested(text: String, style: String)
signal note_added(id: String, title: String)
signal act_changed(act: int)
signal game_completed()

## Das Typ-Limit für den Haupt-Charakter (wird von PlayerController gesetzt).
var player: Node3D = null

## Aktueller Spielstand (Boolean-Flags), z.B. "act1_safe_open".
var flags: Dictionary = {}

## Bereits gesammelte/notierte Fundstücke. Schlüssel = Artikel-ID.
var notes: Dictionary = {}

## ID des zuletzt hinzugefügten Fundstücks (für das Journal).
var last_note_id: String = ""

## Aktuelles Ziel als deutscher String.
var current_objective: String = ""

## Title-Screen verwenden diese, um direkt in den Titel zu springen.
var _current_scene_path: String = ""

func set_flag(name: String, value: bool = true) -> void:
    flags[name] = value

func get_flag(name: String) -> bool:
    return flags.get(name, false)

func set_objective(text: String) -> void:
    if current_objective == text:
        return
    current_objective = text
    objective_changed.emit(text)

func add_note(id: String, title: String, body: String) -> void:
    if notes.has(id):
        return
    notes[id] = {"title": title, "body": body}
    last_note_id = id
    note_added.emit(id, title)

func has_note(id: String) -> bool:
    return notes.has(id)

func get_note(id: String) -> Dictionary:
    return notes.get(id, {"title": "", "body": ""})

## Ein kurzes, zentrums-aligneds Text-Feedback (z.B. "Safe geöffnet").
func show_message(text: String, style: String = "info") -> void:
    message_requested.emit(text, style)

## Wechsel in eine Level-Szene. Jedes Level definiert selbst, wo der
## Spieler eintritt (siehe `spawn_position` / `spawn_yaw` in SceneBase).
func load_level(scene_path: String) -> void:
    _current_scene_path = scene_path
    if not ResourceLoader.exists(scene_path):
        push_error("GameManager: Szene nicht gefunden: " + scene_path)
        return
    var packed := load(scene_path) as PackedScene
    get_tree().change_scene_to_packed(packed)

func set_act(act: int) -> void:
    current_act = act
    act_changed.emit(act)
    set_objective(objective_for_act(act))

var current_act: int = 1

func objective_for_act(act: int) -> String:
    match act:
        1:
            return "Akt 1 - Foyer: Öffne den Safe der Rezeption. (Tipp: Zeitungsartikel lesen!)"
        2:
            return "Akt 2 - Korridor: Schalte das Notstrom-Aggregat im Maschinenraum ein."
        3:
            return "Akt 3 - Penthouse: Stell die Standuhr auf die Schattenzeit ein."
        4:
            return "Akt 4 - Terrasse: Öffne das Ausgangstor und gehe nach draußen."
        _:
            return ""

## Wird am Ende des Finales aufgerufen.
func complete_game() -> void:
    set_flag("game_completed", true)
    game_completed.emit()
