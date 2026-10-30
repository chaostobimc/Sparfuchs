extends Interactable
## Rezeption-Safe (Akt 1). E-Taste öffnet das Tastenfeld.
## Das Rätsel wird gelöst, wenn der Code "10449" eingegeben wird.

@onready var _cabinet: Node3D = get_node_or_null("Cabinet")

func _ready() -> void:
    super._ready()
    obj_type = "puzzle"
    prompt = "Panzerschloss öffnen"
    UIManager.keypad_solved.connect(_on_solved)

func _on_solved(_code: String) -> void:
    if _cabinet:
        var t := create_tween()
        t.tween_property(_cabinet, "position:x", 0.5, 0.7)
    AudioManager.sfx("lock")

func interact() -> void:
    if GameManager.get_flag("act1_safe_open"):
        GameManager.show_message("Der Safe ist bereits offen.", "info")
        return
    UIManager.open_keypad("10449")
    super.interact()
