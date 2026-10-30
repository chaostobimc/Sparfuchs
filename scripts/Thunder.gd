extends Node
class_name Thunder
## Perodisch Blitz + Donner. Flashing registered lights kurz auf.
## Registriere Lichter via `add_light(light)`.

@export var min_interval: float = 7.0
@export var max_interval: float = 22.0
@export var flash_duration: float = 0.12
@export var flash_energy: float = 7.0

var _timer := 0.0
var _next := 8.0
var _lights: Array = []

func _ready() -> void:
    _next = randf_range(min_interval, max_interval)

func add_light(light: Light3D) -> void:
    _lights.append(light)

func _process(delta: float) -> void:
    _timer += delta
    if _timer >= _next:
        _timer = 0.0
        _next = randf_range(min_interval, max_interval)
        flash()

func flash() -> void:
    AudioManager.thunder()
    for l in _lights:
        if l is Light3D and l.visible:
            var orig := l.light_energy
            l.light_energy = flash_energy
            var t := create_tween()
            t.tween_property(l, "light_energy", orig, flash_duration)
