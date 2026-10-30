extends SceneBase
## Akt 2 - Hotelkorridor & Maschinenraum.
## Der korridor führt zum Maschinenraum mit dem Notstrom-Aggregat (4 Hebel).
## Der Aufzug (Portal) führt nach oben ins Penthouse.

func _ready() -> void:
    spawn_position = Vector3(0.0, 0.0, 6.5)
    spawn_yaw = 0.0
    super._ready()
    _build_room()
    _build_generator()
    _build_elevator()
    _build_notes()
    _build_decor()

func _build_room() -> void:
    var W := 18.0
    var D := 14.0
    var H := 5.0
    Builder.room(Vector2(W, D), H, Color(0.14, 0.1, 0.07), Color(0.13, 0.16, 0.14),
                 Color(0.03, 0.03, 0.03), self, "wood", "wallpaper", "concrete")

func _build_generator() -> void:
    # Aggregat-Gehäuse hinter den Hebeln
    var body := Node3D.new()
    body.position = Vector3(0.0, 0.0, -6.3)
    add_child(body)
    Builder.static_box(Vector3(4.0, 2.6, 1.2), Color(0.1, 0.1, 0.12), Vector3(0, 1.3, 0), body)
    # Hebel-Panel davor
    var panel := Builder.box(Vector3(4.2, 1.6, 0.1), Color(0.2, 0.2, 0.22))
    panel.position = Vector3(0, 1.4, 0.7)
    body.add_child(panel)
    var levers := PuzzleLevers.new()
    levers.position = Vector3(0.0, 0.0, -5.3)
    add_child(levers)
    # Wartungsschild (Notiz-2 Umfeld)
    LevelKit.accent_light(body, Vector3(0, 2.2, 0.7), Color(0.5, 0.5, 0.5), 0.6, 4.0)

func _build_elevator() -> void:
    # Aufzug-Gitter (visual, keine Kollision)
    var gate := Node3D.new()
    gate.position = Vector3(6.0, 0.0, -6.0)
    add_child(gate)
    var frame_mat := StandardMaterial3D.new()
    frame_mat.albedo_color = Color(0.25, 0.25, 0.28)
    frame_mat.metalness = 0.6
    frame_mat.roughness = 0.4
    var post := Builder.box(Vector3(0.1, 3.4, 0.1), Color(0.25, 0.25, 0.28))
    post.position = Vector3(-0.7, 1.7, 0)
    gate.add_child(post)
    var post2 := Builder.box(Vector3(0.1, 3.4, 0.1), Color(0.25, 0.25, 0.28))
    post2.position = Vector3(0.7, 1.7, 0)
    gate.add_child(post2)
    var top := Builder.box(Vector3(1.5, 0.15, 0.8), Color(0.2, 0.2, 0.22))
    top.position = Vector3(0, 3.3, 0)
    gate.add_child(top)
    var portal := Portal.new()
    portal.position = Vector3(0.0, 1.7, 0.0)
    portal.target_scene = "res://scenes/Penthouse.tscn"
    portal.act = 3
    portal.require_flag = "act2_generator_on"
    portal.lock_message = "Der Aufzug bewegt sich nicht. Schalte das Notstrom-Aggregat ein!"
    gate.add_child(portal)
    # Status-Leuchte
    var lamp := Builder.box(Vector3(0.12, 0.12, 0.12), Color(0.1, 0.3, 0.1))
    lamp.position = Vector3(0, 2.9, 0.35)
    lamp.name = "StatusLed"
    gate.add_child(lamp)

func _build_notes() -> void:
    var crate := Node3D.new()
    crate.position = Vector3(4.5, 0.0, 2.0)
    Builder.static_box(Vector3(0.8, 0.8, 0.8), Color(0.22, 0.15, 0.09), Vector3(0, 0.4, 0), crate)
    var paper := Builder.box(Vector3(0.45, 0.01, 0.32), Color(0.75, 0.72, 0.6))
    paper.position = Vector3(0, 0.83, 0)
    paper.rotation.y = 0.2
    crate.add_child(paper)
    var note_node := Node3D.new()
    note_node.position = Vector3(0, 0.85, 0)
    note_node.set_script(load("res://scripts/Note.gd") as Script)
    note_node.set("note_id", "article2")
    crate.add_child(note_node)
    add_child(crate)

func _build_decor() -> void:
    LevelKit.plant(self, Vector3(-7.5, 0.0, 5.0), 1.0)
    LevelKit.plant(self, Vector3(7.5, 0.0, 5.0), 1.0)
    LevelKit.plant(self, Vector3(-7.5, 0.0, -5.0), 0.9)
    LevelKit.accent_light(self, Vector3(0.0, 3.2, 3.0), Color(1.0, 0.7, 0.4), 1.2, 8.0)
    LevelKit.accent_light(self, Vector3(-6.0, 3.0, -2.0), Color(1.0, 0.6, 0.35), 0.9, 5.0)
    LevelKit.accent_light(self, Vector3(6.0, 3.0, 0.0), Color(0.6, 0.7, 0.9), 0.9, 5.0)
    LevelKit.window(self, Vector3(0.0, 2.4, -7.0), Vector2(4.0, 2.0), 0.0, Color(0.2, 0.28, 0.38))
    LevelKit.fallen_kommode(self, Vector3(-5.0, 0.0, 2.0), Vector3(0, 0, deg_to_rad(-15)))
    LevelKit.rug(self, Vector3(0, 0.0, 0.0), Vector2(10.0, 6.0), Color(0.22, 0.16, 0.12))
