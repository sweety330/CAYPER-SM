extends Node
var left_stick := Vector2.ZERO
func _ready() -> void:
    _add_key("move_forward", KEY_W); _add_key("move_forward", KEY_UP)
    _add_key("move_backward", KEY_S); _add_key("move_backward", KEY_DOWN)
    _add_key("move_left", KEY_A); _add_key("move_left", KEY_LEFT)
    _add_key("move_right", KEY_D); _add_key("move_right", KEY_RIGHT)
    _add_key("jump", KEY_SPACE); _add_key("sprint", KEY_SHIFT)
    _add_key("interact", KEY_E); _add_key("menu", KEY_ESCAPE)
    _add_key("inventory", KEY_I)
func _add_key(action_name: String, key: Key) -> void:
    if not InputMap.has_action(action_name): InputMap.add_action(action_name)
    var event := InputEventKey.new()
    event.physical_keycode = key
    InputMap.action_add_event(action_name, event)
func get_move_vector() -> Vector2:
    var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    return left_stick if left_stick.length() > 0.1 else keyboard
func set_controller_input(left: Vector2, _right: Vector2) -> void: left_stick = left
