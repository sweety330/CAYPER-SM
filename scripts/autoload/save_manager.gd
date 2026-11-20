extends Node
const SAVE_DIR := "user://saves/CAYPER_SM"
const SAVE_VERSION := 3
signal save_completed(slot: int)
signal load_completed(slot: int)
func _ready() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
func get_save_slot_path(slot: int) -> String: return "%s/slot_%d.json" % [SAVE_DIR, slot]
func save_game(slot: int = 1) -> bool:
    if slot < 1 or slot > 3: return false
    var pos := Vector3(0, 1, 8)
    if is_instance_valid(GameManager.player_node): pos = GameManager.player_node.global_position
    var extra: Dictionary = {}
    var game_root := get_tree().get_first_node_in_group("game_root")
    if game_root and game_root.has_method("export_extra_save_data"): extra = game_root.export_extra_save_data()
    var data := {"version":SAVE_VERSION,"player_name":GameManager.player_name,"money":GameManager.player_money,"level":GameManager.player_level,"experience":GameManager.player_experience,"game_time_minutes":GameManager.game_time_minutes,"position":{"x":pos.x,"y":pos.y,"z":pos.z},"economy":EconomyManager.serialize(),"extra":extra,"audio":AudioManager.save_audio_settings()}
    var file := FileAccess.open(get_save_slot_path(slot), FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(data, "\t")); file.close()
    save_completed.emit(slot)
    return true
func load_game(slot: int = 1) -> bool:
    if slot < 1 or slot > 3: return false
    var path := get_save_slot_path(slot)
    if not FileAccess.file_exists(path): return false
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null: return false
    var parsed = JSON.parse_string(file.get_as_text()); file.close()
    if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) > SAVE_VERSION: return false
    GameManager.player_name = str(parsed.get("player_name", "أنت"))
    GameManager.player_money = maxf(0.0, float(parsed.get("money", 1500.0)))
    GameManager.player_level = maxi(1, int(parsed.get("level", 1)))
    GameManager.player_experience = maxi(0, int(parsed.get("experience", 0)))
    GameManager.game_time_minutes = posmod(int(parsed.get("game_time_minutes", 480)), 1440)
    EconomyManager.restore(parsed.get("economy", {}))
    AudioManager.load_audio_settings(parsed.get("audio", {}))
    var p: Dictionary = parsed.get("position", {})
    if is_instance_valid(GameManager.player_node): GameManager.player_node.global_position = Vector3(float(p.get("x",0)),maxf(1.0,float(p.get("y",1))),float(p.get("z",8)))
    var game_root := get_tree().get_first_node_in_group("game_root")
    if game_root and game_root.has_method("import_extra_save_data"): game_root.import_extra_save_data(parsed.get("extra",{}))
    GameManager.money_changed.emit(GameManager.player_money, 0.0)
    load_completed.emit(slot)
    return true
func list_saves() -> Array:
    var result: Array = []
    for slot in range(1, 4):
        if FileAccess.file_exists(get_save_slot_path(slot)): result.append(slot)
    return result
