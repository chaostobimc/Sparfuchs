extends Node3D
class_name Door
## Eine Tür: physikalische Füllung (Slab) + Übergang (Portal-Logic).
## Die Füllung wird verschoben und ihrer Kollision entzogen, sobald
## `require_flag` gesetzt ist. Danach führt der Spieler in `target_scene`.

@export var target_scene: String = ""
@export var act: int = 1
@export var require_flag: String = ""
@export var lock_message: String = "Diese Tür ist verschlossen."
@export var door_size: Vector3 = Vector3(2.0, 3.0, 0.2)
@export var open_slide: Vector3 = Vector3(2.2, 0.0, 0.0)
@export var door_color: Color = Color(0.12, 0.09, 0.06)
@export var is_open_initially: bool = false

var _slab: StaticBody3D
var _opened: bool = false

func _ready() -> void:
    _slab = StaticBody3D.new()
    _slab.name = "Slab"
    var shape := BoxShape3D.new()
    shape.size = door_size * 0.5
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.collision_layer = 1
    _slab.add_child(cs)
    var mesh := Builder.box(door_size, door_color)
    _slab.add_child(mesh)
    _slab.position = Vector3(0, door_size.y / 2.0, 0)
    add_child(_slab)

    var portal := Area3D.new()
    portal.position = Vector3(0, door_size.y / 2.0, 0.7)
    portal.collision_layer = 0
    portal.collision_mask = 1
    var ps := SphereShape3D.new()
    ps.radius = 1.4
    var pcs := CollisionShape3D.new()
    pcs.shape = ps
    portal.add_child(pcs)
    portal.body_entered.connect(_on_enter)
    add_child(portal)

    if is_open_initially:
        _opened = true
        _slab.collision_layer = 0

func _on_enter(body: Node) -> void:
    if body != GameManager.player:
        return
    if not require_flag.is_empty() and not GameManager.get_flag(require_flag):
        GameManager.show_message(lock_message, "danger")
        AudioManager.sfx("lock")
        return
    if target_scene.is_empty():
        return
    AudioManager.sfx("door")
    GameManager.set_act(act)
    GameManager.load_level(target_scene)

func _process(_delta: float) -> void:
    if not _opened and not require_flag.is_empty() and GameManager.get_flag(require_flag):
        _opened = true
        _slab.collision_layer = 0
        var t := create_tween()
        t.tween_property(_slab, "position", _slab.position + open_slide, 0.8)
