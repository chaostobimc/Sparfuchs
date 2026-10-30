extends Node3D
## Prozeduraler Regen aus vielen dünnen "Strich"-Boxen.
## Wird als Kind des Spielers angelegt, damit er die Reihenfolge der
## Jumpscare-Stille später einfach steuern kann.

var _streaks: Array = []
var _count: int = 140
var _volume := Vector3(7.0, 6.0, 7.0)
var _top: float = 5.0

func _ready() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.7, 0.8, 0.9, 0.35)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.disable_receive_shadows = true
    for i in _count:
        var m := BoxMesh.new()
        m.size = Vector3(0.02, 1.3, 0.02)
        var mi := MeshInstance3D.new()
        mi.mesh = m
        mi.material_override = mat
        mi.position = Vector3(
            randf_range(-_volume.x / 2.0, _volume.x / 2.0),
            randf_range(0.0, _top),
            randf_range(-_volume.z / 2.0, _volume.z / 2.0))
        add_child(mi)
        _streaks.append({"mesh": mi, "vel": randf_range(6.0, 9.5)})

func _process(delta: float) -> void:
    for s in _streaks:
        var mi: MeshInstance3D = s["mesh"]
        mi.position.y -= s["vel"] * delta
        if mi.position.y < -1.2:
            mi.position.y = _top
            mi.position.x = randf_range(-_volume.x / 2.0, _volume.x / 2.0)
            mi.position.z = randf_range(-_volume.z / 2.0, _volume.z / 2.0)

func set_enabled(enabled: bool) -> void:
    visible = enabled
    for s in _streaks:
        (s["mesh"] as MeshInstance3D).visible = enabled
