extends CharacterBody3D
@export var walk_speed := 4.4
@export var run_speed := 7.0
@export var jump_velocity := 4.8
@export var mouse_sensitivity := 0.003
var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var camera_pivot: Node3D
var camera: Camera3D
var yaw := 0.0
var pitch := -0.16
var footstep_timer := 0.0
signal interacted(target: Node)
func _ready() -> void:
    camera_pivot = Node3D.new(); camera_pivot.name = "CameraPivot"
    camera_pivot.position = Vector3(0, 0.55, 0); add_child(camera_pivot)
    camera = Camera3D.new(); camera.name = "Camera3D"
    camera.position = Vector3(0, 0.45, 4.7); camera.current = true
    camera.fov = 72.0; camera_pivot.add_child(camera)
    GameManager.player_node = self
    if not OS.has_feature("mobile"): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _unhandled_input(event: InputEvent) -> void:
    if GameManager.current_state != GameManager.GameState.PLAYING: return
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * mouse_sensitivity
        pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -0.85, 0.25)
        camera_pivot.rotation = Vector3(pitch, yaw, 0)
    elif event is InputEventScreenDrag and event.position.x > get_viewport().get_visible_rect().size.x * 0.42:
        yaw -= event.relative.x * 0.0035
        pitch = clampf(pitch - event.relative.y * 0.0025, -0.85, 0.25)
        camera_pivot.rotation = Vector3(pitch, yaw, 0)
func _physics_process(delta: float) -> void:
    if GameManager.current_state != GameManager.GameState.PLAYING: return
    var input_dir := InputManager.get_move_vector()
    var forward := -camera_pivot.global_transform.basis.z
    var right := camera_pivot.global_transform.basis.x
    forward.y = 0; right.y = 0
    var direction := (right.normalized() * input_dir.x - forward.normalized() * input_dir.y).normalized()
    var speed := run_speed if Input.is_action_pressed("sprint") else walk_speed
    var game_root := get_tree().get_first_node_in_group("game_root")
    if game_root and game_root.has_method("get_player_speed_multiplier"): speed *= game_root.get_player_speed_multiplier()
    if direction.length() > 0.05:
        velocity.x = direction.x * speed; velocity.z = direction.z * speed
        var body := get_node_or_null("Body")
        if body: body.rotation.y = lerp_angle(body.rotation.y, atan2(-direction.x, -direction.z), delta * 9.0)
    else:
        velocity.x = move_toward(velocity.x, 0.0, walk_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, walk_speed * 5.0 * delta)
    if not is_on_floor(): velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"): velocity.y = jump_velocity
    if is_on_floor() and direction.length() > 0.1:
        footstep_timer -= delta
        if footstep_timer <= 0.0:
            AudioManager.play_sfx("footstep")
            footstep_timer = 0.52 if speed == walk_speed else 0.34
    else:
        footstep_timer = 0.0
    move_and_slide()
func interact() -> void:
    var from := camera.global_position
    var to := from + -camera.global_transform.basis.z * 3.6
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit and hit.collider.has_method("interact"):
        hit.collider.interact(); interacted.emit(hit.collider)
