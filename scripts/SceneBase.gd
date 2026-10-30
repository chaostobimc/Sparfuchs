extends Node3D
class_name SceneBase
## Basis für alle Level. Baut Umgebung (Nebel, Hintergrund), Licht,
## den Spieler (PlayerController), Regen und Donner auf.
## Die konkreten Level (LevelFoyer.gd etc.) erben davon und fügen
## Räumlichkeit, Rätsel und Notizen hinzu.

@export var act_number: int = 1
@export var spawn_position: Vector3 = Vector3(0.0, 0.0, 4.0)
@export var spawn_yaw: float = 0.0
@export var ambient_color: Color = Color(0.05, 0.06, 0.07)
@export var fog_color: Color = Color(0.04, 0.05, 0.06)
@export var fog_density: float = 0.05

var _player: CharacterBody3D
var _rain: Rain
var _thunder: Thunder
var _sky_light: DirectionalLight3D
var _env: Environment

func _ready() -> void:
    GameManager.set_act(act_number)
    _build_environment()
    _build_lighting()
    _build_player()
    _build_rain()
    _build_thunder()

# ---------------------------------------------------------------------------
# Umgebung & Licht
# ---------------------------------------------------------------------------

func _build_environment() -> void:
    _env = Environment.new()
    _env.background_mode = Environment.BG_COLOR
    _env.background_color = Color(0.015, 0.015, 0.02)
    _env.fog_enabled = true
    _env.fog_color = fog_color
    _env.fog_density = fog_density
    _env.fog_light_sensitive = true
    _env.volumetric_fog_enabled = true
    _env.volumetric_fog_density = 0.035
    _env.volumetric_fog_albedo = Color(0.5, 0.55, 0.5)
    _env.volumetric_fog_emissive = Color(0.0, 0.0, 0.0)
    _env.volumetric_fog_emissive_energy = 0.0
    _env.glow_enabled = true
    _env.glow_intensity = 0.6
    _env.glow_strength = 1.0
    _env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
    _env.glow_map_strength = 0.0

func _build_lighting() -> void:
    var hemi: HemisphereLight3D = HemisphereLight3D.new()
    hemi.environment = _env
    hemi.light_energy = 0.25
    hemi.sky_color = Color(0.1, 0.12, 0.14)
    hemi.ground_color = Color(0.04, 0.05, 0.04)
    add_child(hemi)

    var ambient: AmbientLight3D = AmbientLight3D.new()
    ambient.light_energy = 0.15
    add_child(ambient)

    # Fahlen Mondlicht-Richtlicht (wird beim Blitz aufgefrischt).
    _sky_light = DirectionalLight3D.new()
    _sky_light.environment = _env
    _sky_light.light_energy = 0.05
    _sky_light.direction = Vector3(-0.4, -1.0, -0.3)
    _sky_light.shadow_enabled = false
    add_child(_sky_light)

func _build_player() -> void:
    _player = CharacterBody3D.new()
    _player.name = "Player"
    var pc := load("res://scripts/PlayerController.gd") as Script
    _player.set_script(pc)
    _player.set_meta("spawn_transform", Transform3D(Basis(), spawn_position))
    _player.set_meta("spawn_yaw", spawn_yaw)
    _player.set_meta("level_environment", _env)
    add_child(_player)

func _build_rain() -> void:
    _rain = Rain.new()
    _player.add_child(_rain)

func _build_thunder() -> void:
    _thunder = Thunder.new()
    _thunder.add_light(_sky_light)
    add_child(_thunder)

## Hilfs-Funktion für Level: Blitz-Licht auffrischen (extra Blitz).
func trigger_flash() -> void:
    if _thunder:
        _thunder.flash()

func get_player() -> CharacterBody3D:
    return _player

func get_rain() -> Rain:
    return _rain

func set_rain_enabled(enabled: bool) -> void:
    if _rain:
        _rain.set_enabled(enabled)

func set_ambient_sound_level(level: float) -> void:
    AudioManager.set_rain_volume(level)
    AudioManager.set_ambient_volume(0.4 * level)
