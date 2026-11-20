extends StaticBody3D
@export_enum("computer", "npc", "cashier", "shop", "home", "job_board", "car") var interaction_kind := "computer"
@export var display_name := "عنصر تفاعلي"
signal used(kind: String, title: String)
func interact() -> void:
    used.emit(interaction_kind, display_name)
