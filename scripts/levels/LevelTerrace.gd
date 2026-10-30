extends SceneBase
## Akt 4 - Dachterrasse & Finale.
## Not-Schalter am Tor -> totale Stille -> Gang im Torflur -> Jumpscare.

var _led: MeshInstance3D
var _finalized: bool = false
var _final_trigger: Area3D

func _ready() -> void:
    spawn_position = Vector3(0.0, 0.0, 5.0)
    spawn_yaw = 0.0
    super._ready()
    _build_room()
    _build_gate()
    _build_switch()
    _build_corridor()
    _build_decor()

func _process(_delta: float) -> void:
    if not _finalized and GameManager.get_flag("act4_gate_open"):
        _finalized = true
        _on_gate_open()

func _on_gate_open() -> void:
    # Totale Stille: Regen und Ambient ab.
    AudioManager.stop_rain()
    AudioManager.stop_ambient()
    set_rain_enabled(false)
    # Grüne Status-LED "TOR ENTSPERRT".
    if _led:
        var mat := _led.material_override as StandardMaterial3D
        if mat:
            mat.emissive_enabled = true
            mat.emissive = Color(0.2, 1.0, 0.3)
            mat.emissive_energy = 1.5
    GameManager.show_message("TOR ENTSPERRT", "success")

func _build_room() -> void:
    var W := 16.0
    var D := 14.0
    var t := 0.2
    Builder.static_box(Vector3(W, 0.2, D), Color(0.12, 0.1, 0.08), Vector3(0, -0.1, 0), self, 0.95, 1, "concrete")
    # Niedrige Geländemauern (Süd/Ost/West)
    Builder.wall_segment(W, 1.2, t, Color(0.1, 0.1, 0.1), Vector3(0, 0.6, D / 2.0), self, "concrete")
    Builder.wall_segment(t, 1.2, D, Color(0.1, 0.1, 0.1), Vector3(-W / 2.0, 0.6, 0), self, "concrete")
    Builder.wall_segment(t, 1.2, D, Color(0.1, 0.1, 0.1), Vector3(W / 2.0, 0.6, 0), self, "concrete")
    # Nordwand (z=-7) mit Tor-Öffnung
    var gap := 3.2
    var left := (W / 2.0 - gap / 2.0)
    Builder.wall_segment(left, 3.0, t, Color(0.1, 0.1, 0.1),
                         Vector3(-(W / 4.0 + gap / 4.0), 1.5, -D / 2.0), self, "concrete")
    Builder.wall_segment(left, 3.0, t, Color(0.1, 0.1, 0.1),
                         Vector3(W / 4.0 + gap / 4.0, 1.5, -D / 2.0), self, "concrete")

func _build_gate() -> void:
    var gate := Door.new()
    gate.position = Vector3(0.0, 0.0, -7.0)
    gate.require_flag = "act4_gate_open"
    gate.lock_message = ""
    gate.door_size = Vector3(3.0, 2.8, 0.2)
    gate.open_slide = Vector3(0.0, 3.2, 0.0)
    gate.door_color = Color(0.15, 0.15, 0.17)
    add_child(gate)
    # Grüne LED
    _led = Builder.box(Vector3(0.2, 0.2, 0.1), Color(0.05, 0.1, 0.05))
    _led.position = Vector3(0.0, 2.0, -6.85)
    add_child(_led)

func _build_switch() -> void:
    var sw := Node3D.new()
    sw.position = Vector3(3.0, 0.0, -7.0)
    Builder.static_box(Vector3(0.4, 0.8, 0.2), Color(0.1, 0.1, 0.1), Vector3(0, 0.4, 0), sw)
    var lever := Builder.box(Vector3(0.2, 0.4, 0.2), Color(0.7, 0.2, 0.2))
    lever.position = Vector3(0, 0.5, 0.15)
    sw.add_child(lever)
    var es := EmergencySwitch.new()
    es.position = Vector3(0, 0.5, 0.2)
    sw.add_child(es)
    add_child(sw)

func _build_corridor() -> void:
    # Boden im Torflur
    Builder.static_box(Vector3(3.2, 0.2, 5.0), Color(0.1, 0.08, 0.06), Vector3(0, -0.1, -9.5), self, 0.95, 1, "concrete")
    # Seitenwände
    Builder.wall_segment(0.2, 3.0, 5.0, Color(0.1, 0.1, 0.1), Vector3(-1.6, 1.5, -9.5), self, "concrete")
    Builder.wall_segment(0.2, 3.0, 5.0, Color(0.1, 0.1, 0.1), Vector3(1.6, 1.5, -9.5), self, "concrete")
    # Endwand
    Builder.wall_segment(3.2, 3.0, 0.2, Color(0.1, 0.1, 0.1), Vector3(0, 1.5, -12.0), self, "concrete")
    # Final-Trigger (letzte Ecke)
    _final_trigger = Area3D.new()
    _final_trigger.position = Vector3(0, 1.5, -11.0)
    _final_trigger.collision_layer = 0
    _final_trigger.collision_mask = 1
    var shape := SphereShape3D.new()
    shape.radius = 1.5
    var cs := CollisionShape3D.new()
    cs.shape = shape
    _final_trigger.add_child(cs)
    _final_trigger.body_entered.connect(_on_final)
    add_child(_final_trigger)

func _on_final(body: Node) -> void:
    if body != GameManager.player:
        return
    if not GameManager.get_flag("act4_gate_open"):
        return
    GameManager.show_message("...", "info")
    # Kurze Stille, dann der Schlag.
    await get_tree().create_timer(0.6).timeout
    UIManager.show_jumpscare()
    GameManager.complete_game()

func _build_decor() -> void:
    LevelKit.plant(self, Vector3(-6.5, 0.0, 5.0), 0.9)
    LevelKit.plant(self, Vector3(6.5, 0.0, 5.0), 0.9)
    LevelKit.accent_light(self, Vector3(0.0, 3.5, 2.0), Color(1.0, 0.7, 0.4), 1.2, 8.0)
    LevelKit.fallen_kommode(self, Vector3(4.0, 0.0, 2.0), Vector3(0, 0, deg_to_rad(20)))
