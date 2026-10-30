extends Light3D
## Zerrüttetes, flackerndes Licht (eine alte Lampe im Sturm).
## Wird an OmniLight3D/SpotLight3D/DirectionalLight3D gehängt.

@export var min_energy: float = 0.05
@export var max_energy: float = 1.4
@export var speed: float = 9.0
@export var stutter_chance: float = 0.02

var _t: float = 0.0

func _process(delta: float) -> void:
    _t += delta
    var v := min_energy + (max_energy - min_energy) * (0.5 + 0.5 * sin(_t * speed)) * (0.6 + 0.4 * sin(_t * speed * 2.7))
    if randf() < stutter_chance:
        v = min_energy * 0.3
    light_energy = v
