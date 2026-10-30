extends Node3D
class_name Interactable
## Basis für alle interagierbaren Objekte (Safe, Hebel, Uhr, Notizen, Türen...).
## Der Spieler detektiert Objekte über die Gruppe "interactable".

signal interacted

@export var prompt: String = "Interagieren"
@export var obj_type: String = "generic"

func _ready() -> void:
    add_to_group("interactable")

## Kann der Spieler aktuell mit diesem Objekt interagieren? (z.B. Rätsel bereits gelöst)
func can_interact() -> bool:
    return true

## Wird aufgerufen, wenn der Spieler die E-Taste drückt.
func interact() -> void:
    interacted.emit()
