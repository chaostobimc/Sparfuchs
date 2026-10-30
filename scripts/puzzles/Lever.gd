extends Interactable
## Ein einzelner Hebel (Lever) des Notstrom-Aggregats (Akt 2).
## Baut seine eigene Visualisierung und berichtet an den Eltern-Knoten
## (PuzzleLevers), welcher Hebel gezogen wurde.

@export var lever_color: String = "Rot"
@export var lever_index: int = 0
@export var accent_color: Color = Color(0.9, 0.2, 0.2)

var _pivot: Node3D
var _pressed: bool = false

func _ready() -> void:
    super._ready()
    obj_type = "lever"
    prompt = "Hebel ziehen (" + lever_color + ")"
    _build_visual()

func _build_visual() -> void:
    # Sockel (statisches Kollisions-Objekt, damit man nicht durchfällt/hindurchgeht)
    Builder.static_box(Vector3(0.45, 0.7, 0.4), Color(0.12, 0.1, 0.08), Vector3(0, 0.35, 0), self)
    # Drehpunkt
    var pivot := Node3D.new()
    pivot.name = "Pivot"
    pivot.position = Vector3(0, 0.7, 0)
    add_child(pivot)
    _pivot = pivot
    # Griff
    var handle := Builder.box(Vector3(0.08, 0.75, 0.08), accent_color, 0.5)
    handle.position = Vector3(0, 0.37, 0)
    pivot.add_child(handle)
    # Knauf
    var knob := Builder.cylinder(0.12, 0.14, accent_color, 0.5)
    knob.position = Vector3(0, 0.68, 0)
    pivot.add_child(knob)

func can_interact() -> bool:
    var p := get_parent() as PuzzleLevers
    return not (p and p.solved)

func interact() -> void:
    if not can_interact():
        return
    _pressed = true
    AudioManager.sfx("lever")
    if _pivot:
        var t := create_tween()
        t.tween_property(_pivot, "rotation:x", -0.6, 0.15)
    var p := get_parent() as PuzzleLevers
    if p:
        p.on_lever_pressed(lever_index)
    super.interact()

func reset() -> void:
    _pressed = false
    if _pivot:
        var t := create_tween()
        t.tween_property(_pivot, "rotation:x", 0.0, 0.2)
