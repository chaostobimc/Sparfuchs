extends RefCounted
class_name LevelKit
## Wiederverwendbare Bausteine für die Level (Mobiliar, Pflanzen, Licht...).
## Alles ist prozedural und in Godot-Standard-Materialien gehalten,
## damit das Spiel sofort läuft und du alles einfach anpassen kannst.

## Eine Pflanze (Topf + Farnfronen) für tropisches Flair.
static func plant(parent: Node, pos: Vector3, scale: float = 1.0) -> Node3D:
    var node := Node3D.new()
    node.position = pos
    node.scale = Vector3(scale, scale, scale)
    var pot := Builder.static_box(Vector3(0.5, 0.5, 0.5), Color(0.35, 0.25, 0.18), Vector3(0, 0.25, 0), node)
    var soil := Builder.box(Vector3(0.44, 0.05, 0.44), Color(0.12, 0.1, 0.07))
    soil.position = Vector3(0, 0.5, 0)
    node.add_child(soil)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.25, 0.5, 0.2)
    mat.roughness = 1.0
    mat.albedo_texture = Builder.TEX["fern"]
    var frond_count := 7
    for i in frond_count:
        var m := PlaneMesh.new()
        m.size = Vector2(0.22, 0.9)
        var mi := MeshInstance3D.new()
        mi.mesh = m
        mi.material_override = mat
        var ang := (i / float(frond_count)) * TAU
        mi.position = Vector3(cos(ang) * 0.15, 0.55, sin(ang) * 0.15)
        mi.rotation = Vector3(deg_to_rad(randf_range(20, 45)), ang, deg_to_rad(randf_range(-10, 10)))
        node.add_child(mi)
    parent.add_child(node)
    return node

## Ein Rezeptionstresen.
static func desk(parent: Node, pos: Vector3, rot_y: float = 0.0) -> Node3D:
    var node := Node3D.new()
    node.position = pos
    node.rotation.y = rot_y
    Builder.static_box(Vector3(2.2, 0.9, 0.8), Color(0.3, 0.18, 0.1), Vector3(0, 0.45, 0), node)
    var top := Builder.box(Vector3(2.3, 0.08, 0.9), Color(0.45, 0.3, 0.2))
    top.position = Vector3(0, 0.94, 0)
    node.add_child(top)
    # Schublade/front
    var front := Builder.box(Vector3(1.4, 0.7, 0.02), Color(0.25, 0.15, 0.09))
    front.position = Vector3(0, 0.5, 0.41)
    node.add_child(front)
    parent.add_child(node)
    return node

## Ein safe-artiger Schrank/Panzer.
static func cabinet(parent: Node, pos: Vector3, rot_y: float = 0.0) -> Node3D:
    var node := Node3D.new()
    node.position = pos
    node.rotation.y = rot_y
    Builder.static_box(Vector3(1.0, 1.6, 0.6), Color(0.2, 0.2, 0.22), Vector3(0, 0.8, 0), node)
    parent.add_child(node)
    return node

## Eine flackernde Zimmerlampe (OmniLight mit FlickerLight-Skript).
static func accent_light(parent: Node, pos: Vector3, color: Color, energy: float,
                        range: float = 6.0) -> OmniLight3D:
    var light := OmniLight3D.new()
    light.position = pos
    light.light_color = color
    light.light_energy = energy
    light.omni_range = range
    light.shadow_enabled = false
    var fs := load("res://scripts/FlickerLight.gd") as Script
    light.set_script(fs)
    parent.add_child(light)
    return light

## Ein Bild/Fenster an der Wand (leuchtende Fläche).
static func window(parent: Node, pos: Vector3, size: Vector2, rot_y: float = 0.0,
                  color: Color = Color(0.3, 0.4, 0.5)) -> Node3D:
    var node := Node3D.new()
    node.position = pos
    node.rotation.y = rot_y
    var m := PlaneMesh.new()
    m.size = size
    var mi := MeshInstance3D.new()
    mi.mesh = m
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emissive_enabled = true
    mat.emissive = color
    mat.emissive_energy = 1.0
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mi.material_override = mat
    node.add_child(mi)
    parent.add_child(node)
    return node

## Ein Teppich (flache Box auf dem Boden).
static func rug(parent: Node, pos: Vector3, size: Vector2, color: Color) -> Node3D:
    var node := Node3D.new()
    node.position = pos
    var m := Builder.box(Vector3(size.x, 0.02, size.y), color, 1.0, "fabric")
    m.position.y = 0.01
    node.add_child(m)
    parent.add_child(node)
    return node

## Ein zerrüttetes, fallendes Möbelstück (Kommode/Tisch).
static func fallen_kommode(parent: Node, pos: Vector3, rot: Vector3) -> Node3D:
    var node := Node3D.new()
    node.position = pos
    node.rotation = rot
    Builder.static_box(Vector3(1.4, 0.8, 0.6), Color(0.28, 0.18, 0.12), Vector3(0, 0.4, 0), node, 0.95, 1, "wood")
    parent.add_child(node)
    return node
