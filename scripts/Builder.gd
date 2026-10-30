extends RefCounted
class_name Builder
## Helfer zum prozeduralen Bauen von Geometrie mit optionalen Texturen.
## Alle Level nutzen diese Funktionen, damit du Räume leicht bearbeiten kannst.
## `tex` ist der Name eines Textures aus `assets/textures/` (leer = reine Farbe).

const TEX := {
    "concrete": preload("res://assets/textures/concrete.png"),
    "wood": preload("res://assets/textures/wood.png"),
    "wallpaper": preload("res://assets/textures/wallpaper.png"),
    "metal": preload("res://assets/textures/metal.png"),
    "fabric": preload("res://assets/textures/fabric.png"),
    "paper": preload("res://assets/textures/paper.png"),
    "dirt": preload("res://assets/textures/dirt.png"),
    "fern": preload("res://assets/textures/fern.png"),
}

## Erzeugt eine Box-Mesh (mit optionalem Texture).
static func box(size: Vector3, color: Color, roughness: float = 0.9, tex: String = "") -> MeshInstance3D:
    var m := BoxMesh.new()
    m.size = size
    var mi := MeshInstance3D.new()
    mi.mesh = m
    mi.material_override = _mat(color, roughness, tex)
    return mi

## Erzeugt eine Ebene (mit optionalem Texture).
static func plane(size: Vector3, color: Color, roughness: float = 0.9, tex: String = "") -> MeshInstance3D:
    var m := PlaneMesh.new()
    m.size = Vector2(size.x, size.y)
    var mi := MeshInstance3D.new()
    mi.mesh = m
    mi.material_override = _mat(color, roughness, tex)
    return mi

## Erzeugt einen Zylinder (mit optionalem Texture).
static func cylinder(radius: float, height: float, color: Color, roughness: float = 0.8, tex: String = "") -> MeshInstance3D:
    var m := CylinderMesh.new()
    m.radius = radius
    m.height = height
    var mi := MeshInstance3D.new()
    mi.mesh = m
    mi.material_override = _mat(color, roughness, tex)
    return mi

static func _mat(color: Color, roughness: float, tex: String) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    mat.metalness = 0.0
    if not tex.is_empty():
        mat.albedo_texture = TEX.get(tex)
    return mat

## Wand-/Boden-/Decken-Element als StaticBody3D mit Kollision.
## `size` ist die volle Ausdehnung (BoxShape.size = halbe Ausdehnung).
static func static_box(size: Vector3, color: Color, pos: Vector3, parent: Node = null,
                       roughness: float = 0.95, collision_layer: int = 1, tex: String = "") -> StaticBody3D:
    var body := StaticBody3D.new()
    var shape := BoxShape3D.new()
    shape.size = size * 0.5
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.collision_layer = collision_layer
    body.add_child(cs)
    var mesh := box(size, color, roughness, tex)
    body.add_child(mesh)
    body.position = pos
    if parent:
        parent.add_child(body)
    return body

## Ein Zylinder-StaticBody für Säulen etc.
static func static_cylinder(radius: float, height: float, color: Color, pos: Vector3,
                            parent: Node = null, tex: String = "") -> StaticBody3D:
    var body := StaticBody3D.new()
    var shape := CylinderShape3D.new()
    shape.radius = radius
    shape.height = height
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.collision_layer = 1
    body.add_child(cs)
    var mesh := cylinder(radius, height, color, 0.8, tex)
    mesh.position.y = -height / 2.0
    body.add_child(mesh)
    body.position = pos
    if parent:
        parent.add_child(body)
    return body

## Ein einzelnes Wand-Segment (für Türöffnungen / gaps).
static func wall_segment(length: float, height: float, thickness: float,
                         color: Color, pos: Vector3, parent: Node, tex: String = "") -> StaticBody3D:
    return static_box(Vector3(length, height, thickness), color, pos, parent, 0.95, 1, tex)

## Baut nur Boden und Decke (Wände per Wall-Segment).
static func floor_ceiling(floor_size: Vector2, wall_height: float, floor_color: Color,
                          ceiling_color: Color, parent: Node, floor_tex: String = "",
                          ceil_tex: String = "") -> StaticBody3D:
    var floor := static_box(Vector3(floor_size.x, 0.2, floor_size.y), floor_color,
                            Vector3(0, -0.1, 0), parent, 0.95, 1, floor_tex)
    var ceil := static_box(Vector3(floor_size.x, 0.2, floor_size.y), ceiling_color,
                           Vector3(0, wall_height + 0.1, 0), parent, 0.95, 0, ceil_tex)
    return floor

## Vollständiger Raum (ohne Türöffnungen). Für Türen nutze floor_ceiling + wall_segment.
static func room(floor_size: Vector2, wall_height: float, floor_color: Color,
                 wall_color: Color, ceiling_color: Color, parent: Node,
                 floor_tex: String = "", wall_tex: String = "",
                 ceil_tex: String = "") -> StaticBody3D:
    var floor := static_box(Vector3(floor_size.x, 0.2, floor_size.y), floor_color,
                            Vector3(0, -0.1, 0), parent, 0.95, 1, floor_tex)
    var ceil := static_box(Vector3(floor_size.x, 0.2, floor_size.y), ceiling_color,
                           Vector3(0, wall_height + 0.1, 0), parent, 0.95, 0, ceil_tex)
    var t := 0.2
    var hw := floor_size.x / 2.0
    var hd := floor_size.y / 2.0
    static_box(Vector3(floor_size.x, wall_height, t), wall_color,
               Vector3(0, wall_height / 2.0, -hd), parent, 0.95, 1, wall_tex)
    static_box(Vector3(floor_size.x, wall_height, t), wall_color,
               Vector3(0, wall_height / 2.0, hd), parent, 0.95, 1, wall_tex)
    static_box(Vector3(t, wall_height, floor_size.y), wall_color,
               Vector3(-hw, wall_height / 2.0, 0), parent, 0.95, 1, wall_tex)
    static_box(Vector3(t, wall_height, floor_size.y), wall_color,
               Vector3(hw, wall_height / 2.0, 0), parent, 0.95, 1, wall_tex)
    return floor
