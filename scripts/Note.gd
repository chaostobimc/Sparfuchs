extends Interactable
## Eine lesbare Notiz / Zeitungsartikel. Greift per ID auf NotesData zurück.

@export var note_id: String = ""

func _ready() -> void:
    super._ready()
    obj_type = "note"
    prompt = "Artikel lesen"
    if not note_id.is_empty():
        var data := NotesData.get(note_id)
        if not GameManager.has_note(note_id):
            GameManager.add_note(note_id, data["title"], data["body"])

func interact() -> void:
    if not note_id.is_empty():
        var data := NotesData.get(note_id)
        if not GameManager.has_note(note_id):
            GameManager.add_note(note_id, data["title"], data["body"])
        UIManager.update_note_count()
        UIManager.show_note_reader(note_id)
    super.interact()
