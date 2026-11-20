extends Node

enum GameState { MAIN_MENU, PLAYING, PAUSED, DIALOGUE, MENU_OPEN }
var current_state: GameState = GameState.PLAYING
var player_name := "أنت"
var player_money: float = 1500.0
var player_level: int = 1
var player_experience: int = 0
var game_time_minutes: int = 480
var day_cycle_minutes: int = 1440
var player_node: Node3D
signal state_changed(new_state: GameState, old_state: GameState)
signal money_changed(new_amount: float, delta: float)
signal level_up(new_level: int)
func change_state(new_state: GameState) -> void:
	if current_state == new_state: return
	var old := current_state
	current_state = new_state
	state_changed.emit(new_state, old)
func add_money(amount: float) -> void:
	player_money = maxf(0.0, player_money + amount)
	money_changed.emit(player_money, amount)
func spend_money(amount: float) -> bool:
	if amount < 0.0 or player_money < amount: return false
	player_money -= amount
	money_changed.emit(player_money, -amount)
	return true
func add_experience(amount: int) -> void:
	player_experience += maxi(0, amount)
	while player_experience >= player_level * 500:
		player_experience -= player_level * 500
		player_level += 1
		level_up.emit(player_level)
func get_time_string() -> String:
	var mins := posmod(game_time_minutes, 1440)
	return "%02d:%02d" % [mins / 60, mins % 60]
func reset_game_data() -> void:
	player_name = "أنت"
	player_money = 1500.0
	player_level = 1
	player_experience = 0
	game_time_minutes = 480
func pause_game() -> void: change_state(GameState.PAUSED)
func resume_game() -> void: change_state(GameState.PLAYING)
