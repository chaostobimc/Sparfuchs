extends SceneBase
## Akt 1 - Foyer & Rezeption.
## Raum with Empfang, Safe (Panzerschloss) und verschlossener Korridor-Tür.

func _ready() -> void:
    spawn_position = Vector3(0.0, 0.0, 4.5)
    spawn_yaw = 0.0
    super._ready()
    _build_room()
    _build_reception()
    _build_safe()
    _build_corridor_door()
    _build_notes()
    _build_decor()

func _build_room() -> void:
    var W := 14.0
    var D := 10.0
    var H := 4.5
    Builder.floor_ceiling(Vector2(W, D), H, Color(0.16, 0.11, 0.07), Color(0.04, 0.04, 0.04), self, "wood", "concrete")
    var t := 0.2
    var door_w := 2.4
    # Nordwand (z=-5) mit Türöffnung
    var half_left := (W / 2.0 - door_w / 2.0)
    Builder.wall_segment(half_left, H, t, Color(0.15, 0.19, 0.16),
                         Vector3(-(W / 4.0 + door_w / 4.0), H / 2.0, -D / 2.0), self, "wallpaper")
    Builder.wall_segment(half_left, H, t, Color(0.15, 0.19, 0.16),
                         Vector3(W / 4.0 + door_w / 4.0, H / 2.0, -D / 2.0), self, "wallpaper")
    # Südwand (z=5)
    Builder.wall_segment(W, H, t, Color(0.15, 0.19, 0.16), Vector3(0, H / 2.0, D / 2.0), self, "wallpaper")
    # Ost-/Westwand
    Builder.wall_segment(t, H, D, Color(0.15, 0.19, 0.16), Vector3(-W / 2.0, H / 2.0, 0), self, "wallpaper")
    Builder.wall_segment(t, H, D, Color(0.15, 0.19, 0.16), Vector3(W / 2.0, H / 2.0, 0), self, "wallpaper")

func _build_reception() -> void:
    LevelKit.desk(self, Vector3(0.0, 0.0, -1.0), 0.0)
    # Stehlampe über dem Tresen
    LevelKit.accent_light(self, Vector3(0.0, 2.8, -1.0), Color(1.0, 0.75, 0.4), 1.6, 7.0)

func _build_safe() -> void:
    var safe := Node3D.new()
    safe.position = Vector3(-3.5, 0.0, -4.0)
    Builder.static_box(Vector3(1.1, 1.6, 0.6), Color(0.12, 0.12, 0.15), Vector3(0, 0.8, 0), safe)
    var door := Builder.box(Vector3(0.95, 1.4, 0.05), Color(0.28, 0.28, 0.3))
    door.position = Vector3(-0.48, 0.8, 0.31)
    safe.add_child(door)
    door.name = "Cabinet"
    var ps := load("res://scripts/puzzles/PuzzleSafe.gd") as Script
    safe.set_script(ps)
    add_child(safe)

func _build_corridor_door() -> void:
    var door: Door = Door.new()
    door.position = Vector3(0.0, 0.0, -5.0)
    door.target_scene = "res://scenes/Corridor.tscn"
    door.act = 2
    door.require_flag = "act1_safe_open"
    door.lock_message = "Die Tür zum Korridor ist verschlossen. Öffne erst den Safe der Rezeption!"
    add_child(door)

func _build_notes() -> void:
    var note := Node3D.new()
    note.position = Vector3(2.5, 0.0, 0.5)
    Builder.static_box(Vector3(0.6, 0.6, 0.6), Color(0.22, 0.15, 0.09), Vector3(0, 0.3, 0), note)
    var paper := Builder.box(Vector3(0.4, 0.01, 0.3), Color(0.75, 0.72, 0.6))
    paper.position = Vector3(0, 0.62, 0)
    paper.rotation.y = 0.3
    note.add_child(paper)
    var note_node := Node3D.new()
    note_node.position = Vector3(0, 0.65, 0)
    var n := load("res://scripts/Note.gd") as Script
    note_node.set_script(n)
    note_node.set("note_id", "article1")
    note.add_child(note_node)
    add_child(note)

func _build_decor() -> void:
    LevelKit.plant(self, Vector3(-6.2, 0.0, 4.0), 1.1)
    LevelKit.plant(self, Vector3(6.2, 0.0, 4.0), 1.0)
    LevelKit.plant(self, Vector3(-6.2, 0.0, -4.0), 0.9)
    LevelKit.window(self, Vector3(-7.05, 2.2, 0.0), Vector2(3.0, 2.0), -PI / 2, Color(0.25, 0.35, 0.45))
    LevelKit.window(self, Vector3(7.05, 2.2, 0.0), Vector2(3.0, 2.0), PI / 2, Color(0.2, 0.3, 0.4))
    LevelKit.rug(self, Vector3(0, 0.0, 2.0), Vector2(6.0, 3.0), Color(0.25, 0.18, 0.13))
    LevelKit.fallen_kommode(self, Vector3(5.0, 0.0, -3.0), Vector3(0, 0, deg_to_rad(18)))
    LevelKit.accent_light(self, Vector3(5.0, 3.0, -3.0), Color(1.0, 0.6, 0.35), 0.9, 5.0)
