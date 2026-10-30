extends Interactable
## Die Standuhr (Akt 3). E-Taste öffnet das Uhr-Overlay.
## Gelöst, wenn die Zeiger auf 22:55 (bzw. 10:55) stehen.

@onready var _door: Node3D = get_node_or_null("SecretDoor")

func _ready() -> void:
    super._ready()
    obj_type = "puzzle"
    prompt = "Standuhr einstellen"
    UIManager.clock_solved.connect(_on_solved)

func _on_solved() -> void:
    if _door:
        var t := create_tween()
        t.tween_property(_door, "position:z", -1.6, 0.8)
    AudioManager.sfx("lock")

func interact() -> void:
    if GameManager.get_flag("act3_clock_solved"):
        GameManager.show_message("Die Geheimtür zur Terrasse steht bereits offen.", "info")
        return
    UIManager.open_clock()
    super.interact()
