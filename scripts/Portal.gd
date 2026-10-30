extends Area3D
class_name Portal
## Triger für Szenenwechsel (Türen, Aufzüge, Geheimtüren).
## Der Spieler löst beim Betreten den Wechsel in `target_scene` aus.

@export var target_scene: String = ""
@export var act: int = 1
@export var require_flag: String = ""
@export var lock_message: String = "Diese Tür ist verschlossen."

func _ready() -> void:
    collision_layer = 0
    collision_mask = 1
    var shape := SphereShape3D.new()
    shape.radius = 1.3
    var cs := CollisionShape3D.new()
    cs.shape = shape
    add_child(cs)

func _on_body_entered(body: Node) -> void:
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
    GameManager.load_level(target_scene, body.global_transform)
