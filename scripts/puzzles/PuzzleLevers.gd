extends Node3D
class_name PuzzleLevers
## Das Notstrom-Aggregat (Akt 2). Baut vier Hebel und prüft die Reihenfolge
## Rot -> Blau -> Grün -> Gelb. Bei falscher Reihenfolge wird alles zurückgesetzt.

var _sequence: Array = [0, 1, 2, 3]
var _progress: int = 0
var solved: bool = false

func _ready() -> void:
    _build()

func _build() -> void:
    var names := ["Rot", "Blau", "Grün", "Gelb"]
    var accents := [Color(0.9, 0.2, 0.2), Color(0.25, 0.45, 0.95),
                    Color(0.3, 0.9, 0.35), Color(0.95, 0.9, 0.2)]
    for i in 4:
        var lever := load("res://scripts/puzzles/Lever.gd").new() as Lever
        lever.lever_color = names[i]
        lever.lever_index = i
        lever.accent_color = accents[i]
        lever.position = Vector3(-2.25 + i * 1.5, 0.0, 1.2)
        add_child(lever)

func on_lever_pressed(index: int) -> void:
    if solved:
        return
    if index == _sequence[_progress]:
        _progress += 1
        if _progress >= _sequence.size():
            solved = true
            GameManager.set_flag("act2_generator_on", true)
            AudioManager.sfx("generator")
            GameManager.show_message("Das Notstromaggregat springt an! Der Aufzug ist bereit.", "success")
        else:
            GameManager.show_message("Korrekt (" + str(_progress) + "/4).", "info")
    else:
        _progress = 0
        for child in get_children():
            if child is Lever:
                child.reset()
        GameManager.show_message("Falsche Reihenfolge! Die Kette wird zurückgesetzt.", "danger")
        AudioManager.sfx("lock")
