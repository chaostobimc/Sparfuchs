extends Interactable
## Not-Schalter am Ausgangstor (Akt 4). Betätigung löst das Finale aus.

func _ready() -> void:
    super._ready()
    obj_type = "switch"
    prompt = "Not-Schalter betätigen"

func interact() -> void:
    if GameManager.get_flag("act4_gate_open"):
        GameManager.show_message("Das Ausgangstor ist bereits entsperrt.", "info")
        return
    GameManager.set_flag("act4_gate_open", true)
    AudioManager.sfx("gate")
    AudioManager.sfx("click")
    super.interact()
