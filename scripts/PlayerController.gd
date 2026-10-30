extends CharacterBody3D
## Erste-Person-Controller. Bewegt den Spieler, verwaltet Mouse-Look
## (Pointer-Lock), das Blinklicht, die Interaktion mit Gegenständen und
## das zweiwegige Nachrichten-/Journal-System.

@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var look_sensitivity: float = 2.0
@export var interact_range: float = 3.4
@export var head_height: float = 1.7
@export var bob_amount: float = 0.05
@export var bob_speed: float = 10.0

var _yaw: float = 0.0
var _pitch: float = 0.0
var _last_mouse: Vector2 = Vector2.ZERO
var _head: Node3D
var _cam: Camera3D
var _flashlight: SpotLight3D
var _flashlight_on: bool = true
var _target: Node = null
var _ray: RayCast3D
var _bob_phase: float = 0.0
var _step_dist: float = 0.0
var _was_locked: bool = false
var _pause_shown: bool = false
var _game_started: bool = false
var _gravity: float = 9.8

func _ready() -> void:
    _gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
    _build_view()
    _build_collider()
    var st := get_meta("spawn_transform", Transform3D.IDENTITY) as Transform3D
    global_transform = st
    _yaw = get_meta("spawn_yaw", 0.0) as float
    if _head:
        _head.rotation.y = _yaw
    velocity = Vector3.ZERO
    _last_mouse = Input.get_mouse_position()
    GameManager.player = self
    UIManager.set_game_active(true)
    AudioManager.start_rain()
    AudioManager.start_ambient()
    AudioManager.set_rain_volume(0.5)
    AudioManager.set_ambient_volume(0.4)
    _game_started = true
    _was_locked = DisplayServer.mouse_get_mode() == DisplayServer.MOUSE_MODE_CAPTURED
    set_process_input(true)

func _build_view() -> void:
    _head = Node3D.new()
    _head.name = "Head"
    _head.position = Vector3(0, head_height, 0)
    add_child(_head)

    _cam = Camera3D.new()
    _cam.name = "Camera3D"
    _cam.fov = 75.0
    _cam.near = 0.05
    _cam.far = 200.0
    _cam.make_current()
    _cam.environment = get_meta("level_environment", null) as Environment
    _head.add_child(_cam)

    _flashlight = SpotLight3D.new()
    _flashlight.name = "Flashlight"
    _flashlight.position = Vector3(0, 0, -0.2)
    _flashlight.angle = 0.55
    _flashlight.attenuation = 1.4
    _flashlight.spot_attenuation = 0.55
    _flashlight.light_energy = 4.0
    _flashlight.shadow_enabled = true
    _flashlight.shadow_blur = 4
    _flashlight.look_at(_flashlight.global_position + Vector3(0, 0, -1))
    _head.add_child(_flashlight)

    # Sichtbarkeits-Raycast (testet nur die Welt-Layer 1).
    _ray = RayCast3D.new()
    _ray.name = "LOSRay"
    _ray.enabled = true
    _ray.collision_mask = 1
    add_child(_ray)

func _build_collider() -> void:
    var shape := CapsuleShape3D.new()
    shape.radius = 0.35
    shape.height = 0.9
    var cs := CollisionShape3D.new()
    cs.shape = shape
    cs.position = Vector3(0, 0.8, 0)
    add_child(cs)
    # nur mit der Welt (Layer 1) kollidieren.
    collision_layer = 1
    collision_mask = 1

# ---------------------------------------------------------------------------
# Bewegung & Mouse-Look
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
    var locked := DisplayServer.mouse_get_mode() == DisplayServer.MOUSE_MODE_CAPTURED
    # Pause automatisch anzeigen, wenn der Pointer entsperrt wird
    # (aber nicht, wenn ein Overlay offen ist).
    if _game_started and _was_locked and not locked and not _pause_shown and not UIManager.any_overlay_open():
        UIManager.show_pause()
        _pause_shown = true
    if locked:
        _pause_shown = false
    if locked and not _was_locked:
        _last_mouse = Input.get_mouse_position()
    _was_locked = locked

    var overlay := UIManager.any_overlay_open()

    # Mouse-Look
    if locked and not overlay:
        var mp := Input.get_mouse_position()
        var d := mp - _last_mouse
        _last_mouse = mp
        _yaw -= d.x * look_sensitivity
        _pitch -= d.y * look_sensitivity
        _pitch = clamp(_pitch, -PI / 2 + 0.05, PI / 2 - 0.05)
        _head.rotation.y = _yaw
        _cam.rotation.x = _pitch

    # Bewegung
    var input := Vector2.ZERO
    if Input.is_action_pressed("move_forward"):
        input.y -= 1.0
    if Input.is_action_pressed("move_backward"):
        input.y += 1.0
    if Input.is_action_pressed("move_left"):
        input.x -= 1.0
    if Input.is_action_pressed("move_right"):
        input.x += 1.0
    input = input.normalized()

    if locked and not overlay and is_on_floor():
        var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
        var forward := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
        var right := Vector3(cos(_yaw), 0.0, -sin(_yaw))
        var wish := forward * (-input.y) + right * input.x
        wish = wish.normalized() * speed
        velocity.x = wish.x
        velocity.z = wish.z
        _bob_phase += delta * bob_speed
        _step_dist += speed * delta
        if _step_dist > 2.2:
            _step_dist = 0.0
            AudioManager.sfx("step")
    else:
        velocity.x = lerp(velocity.x, 0.0, 0.2)
        velocity.z = lerp(velocity.z, 0.0, 0.2)

    velocity.y -= _gravity * delta
    move_and_slide()

    # Head-Bob
    var bob := Vector3.ZERO
    if locked and not overlay and input.length() > 0.01 and is_on_floor():
        bob.y = sin(_bob_phase * 2.0) * bob_amount
        bob.x = cos(_bob_phase) * bob_amount * 0.4
    _head.position.y = head_height + bob.y
    _head.position.x = bob.x

    # Interaktions-Ziel bestimmen
    _update_interaction()

func _update_interaction() -> void:
    var t := _get_target()
    _target = t
    if t:
        var prompt: String = t.get("prompt")
        UIManager.set_prompt("E  " + prompt)
    else:
        UIManager.set_prompt("")

func _get_target() -> Node:
    if not _cam:
        return null
    var origin := _cam.global_transform.origin
    var dir := -_cam.global_transform.basis.z
    var best: Node = null
    var best_dist := interact_range
    for node in get_tree().get_nodes_in_group("interactable"):
        if not node.is_inside_tree():
            continue
        if not node.can_interact():
            continue
        var tp := node.global_position
        var to := tp - origin
        var dist := to.length()
        if dist > interact_range or dist < 0.05:
            continue
        to = to.normalized()
        if dir.dot(to) < 0.65:
            continue
        # Sichtbarkeit prüfen (Wände blockieren; eigene Kollision ignorieren).
        _ray.global_position = origin
        _ray.target_position = to * dist
        if _ray.is_colliding():
            var col := _ray.get_collider()
            if col == self or (col and self.is_ancestor_of(col)):
                pass
            elif not _is_part_of(node, col):
                continue
        if dist < best_dist:
            best_dist = dist
            best = node
    return best

func _is_part_of(node: Node, collider: Node) -> bool:
    if not collider:
        return false
    if collider == node:
        return true
    if node.is_ancestor_of(collider):  # Nachkomme (z.B. Schrank-Body)
        return true
    if collider.is_ancestor_of(node):  # Vorfahre (z.B. Truhe unter der Notiz)
        return true
    return false

# ---------------------------------------------------------------------------
# Eingaben
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if DisplayServer.mouse_get_mode() != DisplayServer.MOUSE_MODE_CAPTURED:
            DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
            _last_mouse = Input.get_mouse_position()
            _pause_shown = false
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            if UIManager.any_overlay_open():
                UIManager.close_top_overlay()
            return
        if UIManager.any_overlay_open():
            return
        match event.keycode:
            KEY_E:
                if _target:
                    _target.interact()
            KEY_I, KEY_J:
                _open_journal()
            KEY_F:
                _toggle_flashlight()

func _open_journal() -> void:
    var id := GameManager.last_note_id
    if id and GameManager.has_note(id):
        UIManager.show_note_reader(id)

func _toggle_flashlight() -> void:
    _flashlight_on = not _flashlight_on
    _flashlight.visible = _flashlight_on
    AudioManager.sfx("click")
