extends SceneBase
## Akt 3 - Penthouse & Ballsaal.
## Großer Ballsaal mit Standuhr (Zeit-Rätsel) und Geheimtür zur Terrasse.

func _ready() -> void:
    spawn_position = Vector3(0.0, 0.0, 7.0)
    spawn_yaw = 0.0
    super._ready()
    _build_room()
    _build_clock()
    _build_secret_door()
    _build_piano()
    _build_curtains()
    _build_notes()
    _build_decor()

func _build_room() -> void:
    var W := 20.0
    var D := 16.0
    var H := 6.0
    Builder.floor_ceiling(Vector2(W, D), H, Color(0.1, 0.07, 0.05), Color(0.02, 0.02, 0.02), self, "wood", "concrete")
    var t := 0.2
    var door_w := 2.2
    var door_x := 0.0
    # Nordwand mit Geheimtür-Öffnung
    var left_len := (door_x - door_w / 2.0) - (-W / 2.0)
    var right_start := door_x + door_w / 2.0
    var right_len := (W / 2.0) - right_start
    Builder.wall_segment(left_len, H, t, Color(0.12, 0.1, 0.14),
                         Vector3((-W / 2.0 + left_len / 2.0), H / 2.0, -D / 2.0), self, "wallpaper")
    Builder.wall_segment(right_len, H, t, Color(0.12, 0.1, 0.14),
                         Vector3((right_start + right_len / 2.0), H / 2.0, -D / 2.0), self, "wallpaper")
    # Südwand
    Builder.wall_segment(W, H, t, Color(0.12, 0.1, 0.14), Vector3(0, H / 2.0, D / 2.0), self, "wallpaper")
    # Ost-/Westwand
    Builder.wall_segment(t, H, D, Color(0.12, 0.1, 0.14), Vector3(-W / 2.0, H / 2.0, 0), self, "wallpaper")
    Builder.wall_segment(t, H, D, Color(0.12, 0.1, 0.14), Vector3(W / 2.0, H / 2.0, 0), self, "wallpaper")

func _build_clock() -> void:
    var clock := Node3D.new()
    clock.position = Vector3(-3.0, 0.0, -7.4)
    # Uhrkörper
    Builder.static_box(Vector3(1.0, 4.2, 0.5), Color(0.18, 0.1, 0.06), Vector3(0, 2.1, 0), clock)
    # Zifferblatt (Zylinder entlang Y -> um 90° gedreht, zeigt +Z)
    var dial := Builder.cylinder(0.32, 0.05, Color(0.85, 0.8, 0.65), 0.6)
    dial.position = Vector3(0, 3.2, 0.27)
    dial.rotation.x = PI / 2.0
    clock.add_child(dial)
    # "SecretDoor"-Klappe (schiebt sich bei Lösung aside)
    var secret := Builder.box(Vector3(0.9, 2.0, 0.05), Color(0.22, 0.15, 0.08))
    secret.position = Vector3(0, 1.4, 0.28)
    clock.add_child(secret)
    secret.name = "SecretDoor"
    var pc := load("res://scripts/puzzles/PuzzleClock.gd") as Script
    clock.set_script(pc)
    add_child(clock)

func _build_secret_door() -> void:
    var door := Door.new()
    door.position = Vector3(0.0, 0.0, -8.0)
    door.target_scene = "res://scenes/Terrace.tscn"
    door.act = 4
    door.require_flag = "act3_clock_solved"
    door.lock_message = "Die Geheimtür ist verschlossen. Stell die Standuhr auf die Schattenzeit ein!"
    door.open_slide = Vector3(2.2, 0.0, 0.0)
    add_child(door)

func _build_piano() -> void:
    var piano := Node3D.new()
    piano.position = Vector3(6.0, 0.0, -2.0)
    add_child(piano)
    Builder.static_box(Vector3(1.6, 1.0, 0.8), Color(0.08, 0.05, 0.04), Vector3(0, 0.5, 0), piano)
    var lid := Builder.box(Vector3(1.6, 0.08, 0.8), Color(0.06, 0.04, 0.03))
    lid.position = Vector3(0, 1.04, 0)
    piano.add_child(lid)
    LevelKit.accent_light(piano, Vector3(0, 1.6, 0), Color(1.0, 0.7, 0.4), 0.7, 4.0)

func _build_curtains() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.3, 0.08, 0.12)
    mat.roughness = 1.0
    mat.albedo_texture = Builder.TEX["fabric"]
    var sides := [-1, 1]
    for s in sides:
        for i in 4:
            var m := PlaneMesh.new()
            m.size = Vector2(1.2, 4.0)
            var mi := MeshInstance3D.new()
            mi.mesh = m
            mi.material_override = mat
            mi.position = Vector3(s * 9.9, 2.0, -6.0 + i * 4.0)
            mi.rotation.y = -s * PI / 2.0
            add_child(mi)

func _build_notes() -> void:
    _make_note(Vector3(-6.0, 0.0, 2.0), "article3")
    _make_note(Vector3(-6.0, 0.0, -1.0), "diary")

func _make_note(pos: Vector3, id: String) -> void:
    var crate := Node3D.new()
    crate.position = pos
    Builder.static_box(Vector3(0.8, 0.8, 0.8), Color(0.2, 0.14, 0.08), Vector3(0, 0.4, 0), crate)
    var paper := Builder.box(Vector3(0.45, 0.01, 0.32), Color(0.75, 0.72, 0.6))
    paper.position = Vector3(0, 0.83, 0)
    paper.rotation.y = 0.2
    crate.add_child(paper)
    var note_node := Node3D.new()
    note_node.position = Vector3(0, 0.85, 0)
    note_node.set_script(load("res://scripts/Note.gd") as Script)
    note_node.set("note_id", id)
    crate.add_child(note_node)
    add_child(crate)

func _build_decor() -> void:
    LevelKit.window(self, Vector3(-10.05, 3.0, 0.0), Vector2(4.0, 3.0), -PI / 2, Color(0.2, 0.25, 0.4))
    LevelKit.window(self, Vector3(10.05, 3.0, 0.0), Vector2(4.0, 3.0), PI / 2, Color(0.2, 0.25, 0.4))
    LevelKit.accent_light(self, Vector3(0.0, 4.5, 0.0), Color(1.0, 0.75, 0.45), 2.0, 14.0)
    LevelKit.accent_light(self, Vector3(-6.0, 3.0, 4.0), Color(1.0, 0.6, 0.35), 1.0, 6.0)
    LevelKit.accent_light(self, Vector3(6.0, 3.0, 4.0), Color(0.6, 0.7, 0.9), 0.9, 6.0)
    LevelKit.plant(self, Vector3(-9.0, 0.0, 6.0), 1.0)
    LevelKit.plant(self, Vector3(9.0, 0.0, 6.0), 1.0)
    LevelKit.rug(self, Vector3(0, 0.0, 0.0), Vector2(14.0, 8.0), Color(0.2, 0.1, 0.13))
