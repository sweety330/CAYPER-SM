extends Node3D

const STREET_LENGTH := 100.0
var player: CharacterBody3D
var sun: DirectionalLight3D
var hud_money: Label
var hud_clock: Label
var hud_level: Label
var hud_notice: Label
var panel: PanelContainer
var panel_title: Label
var panel_body: RichTextLabel
var panel_actions: VBoxContainer
var day_accumulator := 0.0
var npc_clock := 0.0
var notice_timer := 0.0
var touch_id := -1
var touch_origin := Vector2.ZERO
var touch_move := Vector2.ZERO
var inventory := {"coffee": 1, "sandwich": 1, "phone": 1, "repair_kit": 0}
var stats := {"energy": 100.0, "hunger": 80.0, "reputation": 10, "customers": 0, "jobs_done": 0, "talked_to": []}
var quest_progress := {"use_pc": 0, "talk": 0, "buy": 0}
var quest_claimed := {"use_pc": false, "talk": false, "buy": false}
var cafe_open := true
var car_nodes: Array[Node3D] = []
var car_directions: Array[float] = []
var npc_nodes: Array[Node3D] = []
var current_panel_mode := ""

func _ready() -> void:
	add_to_group("game_root")
	_setup_environment()
	AudioManager.play_ambient("res://assets/audio/cafe_ambience.wav")
	_build_neighborhood()
	_build_cafe()
	_build_player()
	_build_hud()
	_connect_signals()
	GameManager.change_state(GameManager.GameState.PLAYING)
	_refresh_hud()
	_notice("أهلاً بيك في حارتك! روح الكافيه وابدأ شغلك.")

func _connect_signals() -> void:
	GameManager.money_changed.connect(func(_amount: float, _delta: float): _refresh_hud())
	EconomyManager.business_changed.connect(_refresh_hud)

func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.PLAYING:
		day_accumulator += delta
		if day_accumulator >= 2.5:
			day_accumulator = 0.0
			_advance_game_minute()
		_update_sun()
		_update_cars(delta)
		_update_npcs(delta)
		_drain_needs(delta)
	if notice_timer > 0.0:
		notice_timer -= delta
		if notice_timer <= 0.0 and is_instance_valid(hud_notice): hud_notice.text = ""

func _setup_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("28618a")
	sky_mat.sky_horizon_color = Color("d7a979")
	sky_mat.ground_bottom_color = Color("252c35")
	sky_mat.ground_horizon_color = Color("a58c70")
	env.sky = sky
	sky.sky_material = sky_mat
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d4c5ac")
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -28, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)

func _build_neighborhood() -> void:
	_box("Ground", Vector3(0,-0.4,0), Vector3(100,0.7,110), Color("b8a68b"), true)
	_box("Road", Vector3(0,-0.02,0), Vector3(14,0.16,105), Color("34383e"), true)
	_box("RoadSideLeft", Vector3(-7.6,0.02,0), Vector3(1.1,0.24,105), Color("d2c4aa"), true)
	_box("RoadSideRight", Vector3(7.6,0.02,0), Vector3(1.1,0.24,105), Color("d2c4aa"), true)
	for z in range(-48, 50, 8):
		_box("LaneMark", Vector3(0,0.07,float(z)), Vector3(0.16,0.035,3.8), Color("f4d77c"), false)
	var building_colors := [Color("d8c4a5"), Color("c8b69d"), Color("e0d4c0"), Color("bda88f"), Color("d4b99a")]
	for side in [-1, 1]:
		for i in range(6):
			var z := -40.0 + float(i) * 16.0
			if side == 1 and i == 2: continue
			if side == -1 and i in [1, 3]: continue
			var h := 8.0 + float((i * 7) % 5)
			var w := 7.0 + float(i % 2) * 1.5
			_building(Vector3(float(side)*18.0,h*0.5,z), Vector3(w,h,11.0), building_colors[(i + side + 5) % building_colors.size()])
	_build_park()
	_build_street_props()
	_build_home()
	_build_market()
	_build_job_board()
	_build_cars()
	_build_npcs()

func _build_park() -> void:
	_box("ParkGrass", Vector3(-23,0.04,16), Vector3(15,0.2,25), Color("668b54"), true)
	for i in range(7):
		var x := -28.0 + float(i % 3) * 4.5
		var z := 7.0 + float(i) * 3.1
		_tree(Vector3(x,0,z))
	_box("ParkBenchSeat", Vector3(-23,0.65,14), Vector3(3.0,0.18,0.7), Color("80573a"), true)
	_box("ParkBenchBack", Vector3(-23,1.2,14.3), Vector3(3.0,0.9,0.16), Color("80573a"), true)

func _build_street_props() -> void:
	for z in [-38.0,-18.0,3.0,24.0,43.0]:
		_lamp(-9.5,z)
		_lamp(9.5,z+5.0)
	for z in [-30.0,20.0,40.0]:
		_box("SidewalkPlanter", Vector3(10.5,0.45,z), Vector3(1.3,0.9,1.3), Color("9b7654"), true)
		_tree(Vector3(10.5,0.9,z))

func _build_cafe() -> void:
	_box("CafeFloor", Vector3(17,0.12,-5), Vector3(13,0.3,18), Color("554a42"), true)
	_box("CafeBackWall", Vector3(17,2.7,-14), Vector3(13,5.4,0.35), Color("d8c5a8"), true)
	_box("CafeLeftWall", Vector3(10.5,2.7,-5), Vector3(0.35,5.4,18), Color("d8c5a8"), true)
	_box("CafeRightWall", Vector3(23.5,2.7,-5), Vector3(0.35,5.4,18), Color("d8c5a8"), true)
	_box("CafeSign", Vector3(17,5.8,-13.72), Vector3(9,1.1,0.18), Color("102b38"), false)
	_box("CafeSignAccent", Vector3(17,5.8,-13.59), Vector3(6.4,0.13,0.04), Color("4ed4b1"), false)
	_box("CafeCounter", Vector3(17,0.85,-11.2), Vector3(7,1.5,1.1), Color("80553a"), true)
	var cashier := _interactable("Cashier", Vector3(17,1.0,-10.3), Vector3(1.1,1.8,1.0), "cashier", "الكاشير")
	_box("CashierScreen", Vector3(17,1.85,-10.8), Vector3(0.8,0.55,0.08), Color("5bd1b5"), false)
	for i in range(6):
		var x := 12.3 + float(i % 3) * 4.6
		var z := -5.0 + float(i / 3) * 5.4
		_box("Desk", Vector3(x,0.9,z), Vector3(2.0,0.18,1.15), Color("704c36"), true)
		_box("MonitorCase", Vector3(x,1.55,z-0.28), Vector3(1.05,0.92,0.18), Color("17232c"), false)
		_box("MonitorScreen", Vector3(x,1.57,z-0.175), Vector3(0.88,0.69,0.025), Color("328e91"), false)
		_box("Keyboard", Vector3(x,1.03,z+0.12), Vector3(0.85,0.06,0.28), Color("242c32"), false)
		_interactable("Computer_%d" % (i+1), Vector3(x,0.95,z+0.25), Vector3(1.7,1.9,1.6), "computer", "كمبيوتر %d" % (i+1))
		_box("Chair", Vector3(x,0.58,z+1.35), Vector3(0.8,0.18,0.8), Color("34444c"), true)
	_box("CafeWindow", Vector3(23.27,2.8,-4), Vector3(0.06,2.3,4.0), Color("7eb4b5"), false)
	_box("CafeDoorFrame", Vector3(17,1.7,4.0), Vector3(3.0,3.4,0.25), Color("5c4535"), false)
	_box("CafeDoorGlass", Vector3(17,1.65,3.84), Vector3(2.45,3.0,0.06), Color("719da2"), false)
	_interactable("CafeDoor", Vector3(17,1.0,4.8), Vector3(3.0,2.2,1.0), "cashier", "باب الكافيه")
	_box("CafeNeon", Vector3(17,4.9,4.2), Vector3(5.5,0.18,0.1), Color("48d7b4"), false)

func _build_home() -> void:
	_building(Vector3(28,4.2,24), Vector3(10,8.4,12), Color("d9c7aa"))
	_box("HomeDoor", Vector3(28,1.25,17.85), Vector3(2.0,2.5,0.18), Color("704a32"), false)
	_interactable("HomeEntrance", Vector3(28,1.0,18.8), Vector3(3.0,2.2,1.2), "home", "بيتك")
	_box("HomeBalcony", Vector3(28,4.0,17.7), Vector3(5.5,0.22,0.9), Color("8b7964"), true)

func _build_market() -> void:
	_building(Vector3(-18,2.8,-28), Vector3(9,5.6,10), Color("c9b18e"))
	_box("MarketAwning", Vector3(-18,4.4,-22.85), Vector3(9.4,0.55,1.1), Color("b84e3f"), false)
	_interactable("MarketCounter", Vector3(-18,1.0,-21.5), Vector3(3.0,2.0,2.0), "shop", "بقالة عم حسن")

func _build_job_board() -> void:
	_box("JobBoardPost", Vector3(-8.5,1.35,-12), Vector3(0.22,2.7,0.22), Color("68452f"), true)
	_box("JobBoard", Vector3(-8.5,2.45,-12), Vector3(2.6,2.0,0.2), Color("d6c79f"), true)
	_interactable("JobBoardAction", Vector3(-8.5,1.3,-10.8), Vector3(2.8,2.4,1.1), "job_board", "لوحة الوظائف")

func _build_npcs() -> void:
	_npc(Vector3(-5,0,2), "عم محمود", Color("a66b45"), "أهلاً يا ابني، الكافيه بتاعك بقى معروف في المنطقة.")
	_npc(Vector3(4,0,28), "أحمد", Color("547d9c"), "لو محتاج شغل، شوف لوحة الوظائف جنب الشارع.")
	_npc(Vector3(-25,0,-5), "سارة", Color("9b6688"), "البقالة عند عم حسن فيها قهوة وسندوتشات.")
	_npc(Vector3(25,0,-35), "كريم", Color("668d65"), "الجو في الحارة هادي النهارده!")

func _build_cars() -> void:
	for i in range(3):
		var car := Node3D.new()
		car.name = "TrafficCar_%d" % i
		var body_color: Color = [Color("a84237"),Color("d2c7aa"),Color("385d75")][i]
		var body := _mesh_box(Vector3(2.4,0.85,4.0), body_color)
		body.position.y = 0.75
		car.add_child(body)
		var roof := _mesh_box(Vector3(1.8,0.65,2.0), body_color.darkened(0.12))
		roof.position = Vector3(0,1.42,-0.1); car.add_child(roof)
		for x in [-1.0,1.0]:
			for z in [-1.25,1.25]:
				var wheel := _mesh_cylinder(0.38,0.22,Color("202327"))
				wheel.rotation.z = PI/2; wheel.position = Vector3(x,0.48,z); car.add_child(wheel)
		car.position = Vector3(-2.5,0,-35.0 + float(i)*34.0)
		add_child(car); car_nodes.append(car); car_directions.append(1.0 if i % 2 == 0 else -1.0)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/player/player_controller.gd"))
	player.position = Vector3(0,1,12)
	var body := MeshInstance3D.new(); body.name = "Body"
	var capsule := CapsuleMesh.new(); capsule.radius = 0.38; capsule.height = 1.8
	body.mesh = capsule
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color("d7a47a"); body.material_override = mat
	player.add_child(body)
	var collision := CollisionShape3D.new(); var shape := CapsuleShape3D.new()
	shape.radius = 0.38; shape.height = 1.8; collision.shape = shape; player.add_child(collision)
	add_child(player)

func _build_hud() -> void:
	var layer := CanvasLayer.new(); layer.name = "GameHUD"; add_child(layer)
	var top := PanelContainer.new(); top.position = Vector2(16,14)
	top.add_theme_stylebox_override("panel", _panel_style(Color(0.035,0.07,0.09,0.9)))
	layer.add_child(top)
	var top_row := HBoxContainer.new(); top_row.add_theme_constant_override("separation",18); top.add_child(top_row)
	hud_money = Label.new(); hud_money.add_theme_font_size_override("font_size",20); top_row.add_child(hud_money)
	hud_clock = Label.new(); hud_clock.add_theme_font_size_override("font_size",18); top_row.add_child(hud_clock)
	hud_level = Label.new(); hud_level.add_theme_font_size_override("font_size",18); top_row.add_child(hud_level)
	var menu_row := HBoxContainer.new(); menu_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_row.position = Vector2(-450,14); menu_row.add_theme_constant_override("separation",7); layer.add_child(menu_row)
	_button(menu_row,"الكافيه",_open_business,Vector2(100,42))
	_button(menu_row,"الحقيبة",_open_inventory,Vector2(90,42))
	_button(menu_row,"المهام",_open_quests,Vector2(80,42))
	_button(menu_row,"حفظ",_save,Vector2(70,42))
	_button(menu_row,"قائمة",_open_pause,Vector2(75,42))
	hud_notice = Label.new(); hud_notice.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hud_notice.position = Vector2(20,-66); hud_notice.size = Vector2(900,40)
	hud_notice.add_theme_font_size_override("font_size",18); layer.add_child(hud_notice)
	var help := Label.new(); help.text = "WASD حركة • Shift جري • Space قفز • E تفاعل • I الحقيبة"
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); help.position = Vector2(16,-28)
	help.add_theme_font_size_override("font_size",13); layer.add_child(help)
	var actions := VBoxContainer.new(); actions.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.position = Vector2(-155,-230); actions.add_theme_constant_override("separation",7); layer.add_child(actions)
	_button(actions,"تفاعل",_interact_action,Vector2(130,46))
	_button(actions,"قفز",_jump_action,Vector2(130,42))
	_button(actions,"ركض",_sprint_action,Vector2(130,42))
	panel = PanelContainer.new(); panel.visible = false
	panel.set_anchors_preset(Control.PRESET_CENTER); panel.position = Vector2(-245,-225)
	panel.custom_minimum_size = Vector2(490,450)
	panel.add_theme_stylebox_override("panel",_panel_style(Color(0.035,0.06,0.08,0.97)))
	layer.add_child(panel)
	var content := VBoxContainer.new(); content.add_theme_constant_override("separation",9); panel.add_child(content)
	panel_title = Label.new(); panel_title.add_theme_font_size_override("font_size",23); content.add_child(panel_title)
	panel_body = RichTextLabel.new(); panel_body.bbcode_enabled = true; panel_body.fit_content = true
	panel_body.custom_minimum_size = Vector2(450,245); panel_body.scroll_active = true; content.add_child(panel_body)
	var action_scroll := ScrollContainer.new()
	action_scroll.custom_minimum_size = Vector2(0,175)
	action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(action_scroll)
	panel_actions = VBoxContainer.new(); action_scroll.add_child(panel_actions)
	if OS.has_feature("mobile"):
		var mobile_hint := Label.new(); mobile_hint.text = "الموبايل: اسحب يسار الشاشة للحركة ويمينها لتدوير الكاميرا"
		mobile_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); mobile_hint.position = Vector2(18,-90)
		mobile_hint.add_theme_font_size_override("font_size",12); layer.add_child(mobile_hint)

func _interact_action() -> void:
	if is_instance_valid(player): player.interact()
func _jump_action() -> void:
	Input.action_press("jump")
	get_tree().create_timer(0.2).timeout.connect(_release_jump)
func _release_jump() -> void:
	Input.action_release("jump")
func _sprint_action() -> void:
	Input.action_press("sprint")
	get_tree().create_timer(0.8).timeout.connect(_release_sprint)
func _release_sprint() -> void:
	Input.action_release("sprint")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and is_instance_valid(player) and not panel.visible:
		player.interact()
	elif event.is_action_pressed("inventory") and not panel.visible:
		_open_inventory()
	elif event.is_action_pressed("menu"):
		if panel.visible: _close_panel()
		else: _open_pause()
	elif event is InputEventScreenTouch:
		var width := get_viewport().get_visible_rect().size.x
		if event.pressed and event.position.x < width * 0.38 and touch_id == -1:
			touch_id = event.index; touch_origin = event.position; touch_move = Vector2.ZERO
		elif not event.pressed and event.index == touch_id:
			touch_id = -1; touch_move = Vector2.ZERO; InputManager.set_controller_input(Vector2.ZERO,Vector2.ZERO)
	elif event is InputEventScreenDrag and event.index == touch_id:
		touch_move = ((event.position-touch_origin)/78.0).limit_length(1.0)
		InputManager.set_controller_input(touch_move,Vector2.ZERO)

func _handle_interaction(kind: String, title: String) -> void:
	match kind:
		"computer":
			_use_computer(title)
		"npc":
			_talk_to_npc(title)
		"cashier":
			AudioManager.play_sfx("door")
			_open_business()
		"shop":
			AudioManager.play_sfx("shop_bell")
			_open_shop()
		"home":
			AudioManager.play_sfx("door")
			_open_home()
		"job_board":
			_open_jobs()
		"car":
			_notice("العربيات في الإصدار ده حركة مرورية للمنظر فقط.")

func _use_computer(title: String) -> void:
	if not cafe_open: _notice("الكافيه مقفول دلوقتي."); return
	if not GameManager.spend_money(8.0): _notice("رصيدك مش كفاية لتشغيل الكمبيوتر."); return
	AudioManager.play_sfx("computer_on")
	AudioManager.play_sfx("computer_typing")
	GameManager.add_money(20.0)
	GameManager.add_experience(35)
	stats.customers = int(stats.customers) + 1
	if int(stats.customers) % 5 == 0:
		stats.reputation = mini(100,int(stats.reputation)+1)
		_notice("سمعة الكافيه زادت نقطة بسبب نشاط العملاء!")
	quest_progress.use_pc = int(quest_progress.use_pc) + 1
	stats.energy = maxf(0.0,float(stats.energy)-2.0)
	_notice("استخدمت %s وكسبت 12 جنيه صافي + خبرة." % title)
	_refresh_hud()

func _talk_to_npc(title: String) -> void:
	quest_progress.talk = int(quest_progress.talk) + 1
	GameManager.add_experience(10)
	var lines := {"عم محمود":"ربنا يوسع رزقك يا ابني. خليك محافظ على سمعة الكافيه.","أحمد":"أنا بدور على شغل، شوف لوحة الوظائف يمكن تلاقي حاجة.","سارة":"القهوة والسندوتشات عند عم حسن، وأسعارها كويسة.","كريم":"الحارة بتنور بالليل، بس خلي بالك من وقتك."}
	_show_panel("كلام مع %s" % title, str(lines.get(title,"أهلاً بيك يا باشا!")), [])

func _open_business() -> void:
	var stats_data: Dictionary = EconomyManager.get_stats()
	var body := "[b]إدارة CAYPER Cyber Cafe[/b]\nحالة الكافيه: %s\nالأجهزة: %d\nالموظفين: %d\nإجمالي الإيرادات: %.0f جنيه\nإجمالي المصروفات: %.0f جنيه\nصافي الأرباح: %.0f جنيه\nسمعة المكان: %d" % ["مفتوح" if cafe_open else "مغلق",stats_data.computers,stats_data.employees,stats_data.revenue,stats_data.expenses,stats_data.profit,stats.reputation]
	var actions: Array = [
		{"text":"شراء كمبيوتر (650 جنيه)","call":func(): _buy_computer()},
		{"text":"ترقية جهاز (350+ جنيه)","call":func(): _upgrade_computer()},
		{"text":"إصلاح الأجهزة (120 جنيه)","call":func(): _repair_computer()},
		{"text":"تعيين موظف (225 جنيه)","call":func(): _hire_employee()},
		{"text":"فتح / إغلاق الكافيه","call":func(): cafe_open = not cafe_open; _notice("الكافيه " + ("اتفتح" if cafe_open else "اتقفل")); _open_business()},
		{"text":"عرض تقرير الأرباح","call":func(): _show_business_report()}
	]
	_show_panel("إدارة الكافيه",body,actions)

func _buy_computer() -> void:
	if EconomyManager.add_computer(true):
		AudioManager.play_sfx("money")
		_notice("اشتريت جهاز جديد. تقدر تستخدمه دلوقتي.")
	else:
		_notice("مش معاك 650 جنيه.")
	_open_business()
	_refresh_hud()
func _upgrade_computer() -> void:
	if EconomyManager.owned_computers.is_empty():
		_notice("مفيش أجهزة للترقية.")
		return
	var pc = EconomyManager.owned_computers[0]
	if EconomyManager.upgrade_computer(pc.id):
		_notice("تمت ترقية الكمبيوتر الأول.")
	else:
		_notice("رصيدك مش كفاية للترقية.")
	_open_business()
	_refresh_hud()
func _repair_computer() -> void:
	var repaired := false
	for pc in EconomyManager.owned_computers:
		if pc.condition < 1.0 and EconomyManager.repair_computer(pc.id):
			repaired = true
			break
	_notice("تم إصلاح جهاز." if repaired else "الأجهزة سليمة أو الرصيد غير كافٍ.")
	_open_business(); _refresh_hud()
func _hire_employee() -> void:
	if EconomyManager.hire_employee("موظف جديد","مساعد",45):
		_notice("تم تعيين موظف جديد.")
	else:
		_notice("محتاج 225 جنيه لتعيين موظف.")
	_open_business()
	_refresh_hud()
func _show_business_report() -> void:
	var data: Dictionary = EconomyManager.get_stats()
	_show_panel("تقرير الأرباح", "الإيرادات التراكمية: %.0f جنيه\nالمصروفات التراكمية: %.0f جنيه\nصافي الربح: %.0f جنيه\nعدد الأجهزة: %d\nعدد الموظفين: %d\nيتم إغلاق الحساب تلقائياً عند بداية يوم جديد." % [data.revenue,data.expenses,data.profit,data.computers,data.employees], [{"text":"رجوع للإدارة","call":_open_business}])

func _open_inventory() -> void:
	var body := "[b]الحقيبة الشخصية[/b]\nقهوة: %d\nسندوتش: %d\nعدة صيانة: %d\nالطاقة: %.0f%%\nالجوع: %.0f%%\n\nاستخدم الأكل لاستعادة الطاقة." % [inventory.coffee,inventory.sandwich,inventory.repair_kit,stats.energy,stats.hunger]
	var actions: Array = [
		{"text":"شرب قهوة","call":func(): _consume_item("coffee")},
		{"text":"أكل سندوتش","call":func(): _consume_item("sandwich")},
		{"text":"استخدام عدة الصيانة","call":_use_repair_kit},
		{"text":"حفظ اللعبة","call":_save}
	]
	_show_panel("الحقيبة",body,actions)
func _consume_item(item: String) -> void:
	if int(inventory.get(item,0)) <= 0:
		_notice("العنصر مش موجود في الحقيبة.")
		return
	inventory[item] = int(inventory[item])-1
	if item == "coffee":
		stats.energy = minf(100.0,float(stats.energy)+25.0)
	else:
		stats.hunger = minf(100.0,float(stats.hunger)+35.0)
		stats.energy = minf(100.0,float(stats.energy)+10.0)
	_open_inventory(); _notice("استخدمت العنصر.")
func _use_repair_kit() -> void:
	if int(inventory.repair_kit) <= 0:
		_notice("مفيش عدة صيانة في الحقيبة.")
		return
	for pc in EconomyManager.owned_computers:
		if pc.condition < 1.0:
			pc.condition = 1.0
			inventory.repair_kit = int(inventory.repair_kit)-1
			EconomyManager.business_changed.emit()
			_notice("استخدمت عدة الصيانة وأصلحت جهازاً.")
			_open_inventory()
			return
	_notice("كل الأجهزة سليمة، احتفظ بعدة الصيانة.")

func _open_shop() -> void:
	_show_panel("بقالة عم حسن","اختار اللي محتاجه. المشتريات بتتضاف للحقيبة فوراً.",[
		{"text":"شراء قهوة (20 جنيه)","call":func(): _buy_item("coffee",20)},
		{"text":"شراء سندوتش (35 جنيه)","call":func(): _buy_item("sandwich",35)},
		{"text":"شراء عدة صيانة (120 جنيه)","call":func(): _buy_item("repair_kit",120)}
	])
func _buy_item(item: String, price: int) -> void:
	if not GameManager.spend_money(float(price)):
		_notice("رصيدك مش كفاية.")
		return
	inventory[item] = int(inventory.get(item,0))+1
	AudioManager.play_sfx("cash_register")
	quest_progress.buy = int(quest_progress.buy)+1
	_notice("تم الشراء وإضافة المنتج للحقيبة."); _open_shop(); _refresh_hud()

func _open_home() -> void:
	_show_panel("بيتك","مكانك الخاص للراحة واستعادة الطاقة.\nالطاقة الحالية: %.0f%%" % stats.energy,[
		{"text":"الراحة حتى الصباح","call":_sleep_until_morning},
		{"text":"حفظ اللعبة","call":_save}
	])
func _sleep_until_morning() -> void:
	var report := EconomyManager.close_day()
	for key in ["job_delivery","job_cleaning","job_technician"]: stats[key] = false
	quest_progress = {"use_pc":0,"talk":0,"buy":0}
	quest_claimed = {"use_pc":false,"talk":false,"buy":false}
	stats.talked_to = []
	GameManager.game_time_minutes = 420
	stats.energy = 100.0
	stats.hunger = maxf(25.0,float(stats.hunger)-15.0)
	_notice("ارتحت وصحيت الساعة 07:00. صافي اليوم: %.0f جنيه." % report.profit)
	_close_panel()

func _open_jobs() -> void:
	_show_panel("لوحة الوظائف","اختار شغلانة متاحة في الحارة. كل مهمة بتتعمل مرة واحدة في اليوم.",[
		{"text":"توصيل طلب — مكافأة 120 جنيه","call":func(): _do_job("delivery",120)},
		{"text":"تنضيف الكافيه — مكافأة 90 جنيه","call":func(): _do_job("cleaning",90)},
		{"text":"مساعدة فني — مكافأة 160 جنيه","call":func(): _do_job("technician",160)}
	])
func _do_job(job: String, reward: int) -> void:
	var key := "job_"+job
	if bool(stats.get(key,false)):
		_notice("أنجزت المهمة دي النهارده بالفعل.")
		return
	stats[key] = true; stats.jobs_done = int(stats.jobs_done)+1
	GameManager.add_money(float(reward)); GameManager.add_experience(60)
	_notice("أنجزت المهمة وكسبت %d جنيه." % reward); _open_jobs(); _refresh_hud()

func _open_quests() -> void:
	var body := "[b]مهام البداية[/b]\n1. استخدم 3 أجهزة كمبيوتر: %d/3\n2. اتكلم مع شخصين: %d/2\n3. اشتري منتجين: %d/2\n\nكل مهمة مكتملة تمنحك 100 جنيه وخبرة." % [mini(int(quest_progress.use_pc),3),mini(int(quest_progress.talk),2),mini(int(quest_progress.buy),2)]
	var actions: Array = []
	if int(quest_progress.use_pc)>=3 and not quest_claimed.use_pc: actions.append({"text":"استلام مكافأة استخدام الكمبيوتر","call":func(): _claim_quest("use_pc")})
	if int(quest_progress.talk)>=2 and not quest_claimed.talk: actions.append({"text":"استلام مكافأة المحادثات","call":func(): _claim_quest("talk")})
	if int(quest_progress.buy)>=2 and not quest_claimed.buy: actions.append({"text":"استلام مكافأة التسوق","call":func(): _claim_quest("buy")})
	_show_panel("المهام اليومية",body,actions)
func _claim_quest(key: String) -> void:
	if bool(quest_claimed.get(key,false)):
		return
	quest_claimed[key] = true; GameManager.add_money(100.0); GameManager.add_experience(100)
	_notice("استلمت 100 جنيه ومكافأة خبرة!"); _open_quests()

func _open_pause() -> void:
	GameManager.pause_game()
	_show_panel("القائمة الرئيسية","اللعبة متوقفة مؤقتاً.\nتقدر تحفظ تقدمك أو تحمل آخر حفظ.",[
		{"text":"متابعة اللعب","call":func(): GameManager.resume_game(); _close_panel()},
		{"text":"حفظ الخانة 1","call":func(): _save_slot(1)},
		{"text":"حفظ الخانة 2","call":func(): _save_slot(2)},
		{"text":"حفظ الخانة 3","call":func(): _save_slot(3)},
		{"text":"تحميل الخانة 1","call":func(): _load_game(1)},
		{"text":"تحميل الخانة 2","call":func(): _load_game(2)},
		{"text":"تحميل الخانة 3","call":func(): _load_game(3)},
		{"text":"إعدادات الصوت","call":_open_settings}
	])
func _open_settings() -> void:
	_show_panel("إعدادات الصوت","اختار مستوى الصوت الرئيسي. الإعداد بيُطبق فوراً.",[
		{"text":"الصوت 100%","call":func(): _set_master_volume(1.0)},
		{"text":"الصوت 75%","call":func(): _set_master_volume(0.75)},
		{"text":"الصوت 50%","call":func(): _set_master_volume(0.5)},
		{"text":"الصوت 25%","call":func(): _set_master_volume(0.25)},
		{"text":"كتم الصوت","call":func(): _set_master_volume(0.0)},
		{"text":"رجوع","call":_open_pause}
	])
func _set_master_volume(value: float) -> void:
	AudioManager.set_volume("master",value)
	_notice("تم تحديث مستوى الصوت.")

func _save() -> void:
	_save_slot(1)
func _save_slot(slot: int) -> void:
	if SaveManager.save_game(slot):
		AudioManager.play_sfx("money")
		_notice("تم حفظ تقدمك في الخانة %d." % slot)
	else:
		_notice("فشل الحفظ، راجع مساحة التخزين.")
func _load_game(slot: int) -> void:
	if SaveManager.load_game(slot):
		_notice("تم تحميل الخانة %d." % slot)
		_refresh_hud()
		_close_panel()
	else:
		_notice("الخانة %d فاضية أو ملف الحفظ غير صالح." % slot)

func _show_panel(title: String, body: String, actions: Array) -> void:
	GameManager.change_state(GameManager.GameState.MENU_OPEN)
	current_panel_mode = title
	panel_title.text = title; panel_body.text = body
	for child in panel_actions.get_children(): child.queue_free()
	for action in actions: _add_panel_button(str(action["text"]),action["call"])
	_add_panel_button("إغلاق",_close_panel)
	panel.visible = true
	if not OS.has_feature("mobile"): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func _add_panel_button(label_text: String, callback: Callable) -> void:
	var button := Button.new(); button.text = label_text; button.custom_minimum_size = Vector2(0,38)
	button.pressed.connect(func(): AudioManager.play_sfx("ui_click"); callback.call())
	panel_actions.add_child(button)
func _close_panel() -> void:
	panel.visible = false
	GameManager.resume_game()
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _notice(message: String) -> void:
	hud_notice.text = message; notice_timer = 4.0
func _refresh_hud() -> void:
	if not is_instance_valid(hud_money): return
	hud_money.text = "💰 %.0f جنيه" % GameManager.player_money
	hud_clock.text = "اليوم %d  |  %s" % [EconomyManager.day_passed,GameManager.get_time_string()]
	hud_level.text = "المستوى %d" % GameManager.player_level

func _advance_game_minute() -> void:
	GameManager.game_time_minutes += 1
	if GameManager.game_time_minutes >= 1440:
		GameManager.game_time_minutes = 0
		var report := EconomyManager.close_day()
		for key in ["job_delivery","job_cleaning","job_technician"]: stats[key] = false
		quest_progress = {"use_pc": 0, "talk": 0, "buy": 0}
		quest_claimed = {"use_pc": false, "talk": false, "buy": false}
		stats.talked_to = []
		_notice("بدأ يوم جديد. صافي أرباح الكافيه: %.0f جنيه." % report.profit)
	_refresh_hud()
func _drain_needs(delta: float) -> void:
	stats.hunger = maxf(0.0,float(stats.hunger)-delta*0.018)
	stats.energy = maxf(0.0,float(stats.energy)-delta*0.008)
func _update_sun() -> void:
	if not is_instance_valid(sun): return
	var hour := float(GameManager.game_time_minutes)/60.0
	sun.rotation_degrees.x = -((hour-6.0)/12.0)*180.0-15.0
	sun.light_energy = 0.18 if hour < 5.5 or hour > 19.0 else (0.65 if hour < 7.0 or hour > 17.0 else 1.15)
func _update_cars(delta: float) -> void:
	for i in range(car_nodes.size()):
		var car := car_nodes[i]
		car.position.z += car_directions[i]*delta*2.0
		if car.position.z > 52.0: car.position.z = -52.0
		if car.position.z < -52.0: car.position.z = 52.0
func _update_npcs(delta: float) -> void:
	npc_clock += delta
	for i in range(npc_nodes.size()):
		var npc := npc_nodes[i]
		var home: Vector3 = npc.get_meta("home_position",npc.position)
		var phase: float = float(npc.get_meta("wander_phase", float(i)))
		npc.position.x = home.x + sin(npc_clock*0.32+float(phase))*0.65
		npc.position.z = home.z + cos(npc_clock*0.24+float(phase))*0.45
		npc.rotation.y = sin(npc_clock*0.2+float(phase))*0.18

func _interactable(node_name: String, pos: Vector3, size: Vector3, kind: String, label: String) -> StaticBody3D:
	var node := StaticBody3D.new(); node.name = node_name; node.position = pos
	node.set_script(load("res://scripts/world_interactable.gd"))
	node.set("interaction_kind",kind); node.set("display_name",label)
	node.connect("used",Callable(self,"_handle_interaction"))
	var shape_node := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size
	shape_node.shape = shape; node.add_child(shape_node); add_child(node)
	return node
func _building(pos: Vector3, size: Vector3, color: Color) -> void:
	_box("Building",pos,size,color,true)
	for floor_index in range(1,int(size.y/2.4)+1):
		for side in [-1,1]:
			_box("Window",pos+Vector3(float(side)*size.x*0.28,-size.y*0.5+float(floor_index)*2.15,-size.z*0.5-0.08),Vector3(1.0,1.15,0.07),Color("66818a"),false)
	_box("RoofRim",pos+Vector3(0,size.y*0.5+0.12,0),Vector3(size.x+0.3,0.25,size.z+0.3),color.darkened(0.13),false)
func _tree(pos: Vector3) -> void:
	_box("TreeTrunk",pos+Vector3(0,1.1,0),Vector3(0.4,2.2,0.4),Color("70492f"),true)
	var crown := MeshInstance3D.new(); var sphere := SphereMesh.new(); sphere.radius = 1.35; sphere.height = 2.7
	crown.mesh = sphere; crown.position = pos+Vector3(0,3.0,0)
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color("3d7548"); crown.material_override = mat; add_child(crown)
func _lamp(x: float, z: float) -> void:
	_box("LampPole",Vector3(x,2.4,z),Vector3(0.12,4.8,0.12),Color("34383a"),true)
	_box("LampHead",Vector3(x,4.9,z),Vector3(0.75,0.25,0.65),Color("ffe3a0"),false)
func _npc(pos: Vector3, npc_name: String, color: Color, dialogue: String) -> void:
	var npc := StaticBody3D.new(); npc.name = "NPC_"+npc_name; npc.position = pos
	npc.set_script(load("res://scripts/world_interactable.gd")); npc.set("interaction_kind","npc"); npc.set("display_name",npc_name)
	npc.connect("used",Callable(self,"_handle_interaction"))
	var mesh := MeshInstance3D.new(); var capsule := CapsuleMesh.new(); capsule.radius = 0.34; capsule.height = 1.7
	mesh.mesh = capsule; var mat := StandardMaterial3D.new(); mat.albedo_color = color; mesh.material_override = mat; npc.add_child(mesh)
	var col := CollisionShape3D.new(); var cshape := CapsuleShape3D.new(); cshape.radius = 0.34; cshape.height = 1.7; col.shape = cshape; npc.add_child(col)
	mesh.position.y = 0.85
	col.position.y = 0.85
	npc.set_meta("dialogue",dialogue); npc.set_meta("home_position",pos); npc.set_meta("wander_phase",float(npc_nodes.size()))
	add_child(npc); npc_nodes.append(npc)
func _box(label: String, pos: Vector3, size: Vector3, color: Color, collision: bool) -> Node3D:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
	root.name = label; root.position = pos
	var visual := _mesh_box(size,color); root.add_child(visual)
	if collision:
		var col := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size; col.shape = shape; root.add_child(col)
	add_child(root); return root
func _mesh_box(size: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size; visual.mesh = mesh
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.roughness = 0.88; visual.material_override = mat
	return visual
func _mesh_cylinder(radius: float, height: float, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new(); var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius; mesh.height = height; visual.mesh = mesh
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; visual.material_override = mat; return visual
func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = color
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12; style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	style.content_margin_left = 12; style.content_margin_right = 12; style.content_margin_top = 10; style.content_margin_bottom = 10
	return style
func _button(parent: Node, label: String, callback: Callable, minimum: Vector2) -> void:
	var button := Button.new(); button.text = label; button.custom_minimum_size = minimum; button.pressed.connect(callback); parent.add_child(button)

func get_player_speed_multiplier() -> float:
	if float(stats.energy) < 15.0 or float(stats.hunger) < 10.0: return 0.68
	return 1.0
func get_cafe_reputation_bonus() -> float:
	return 1.0 + float(stats.reputation) * 0.005
func is_cafe_open() -> bool:
	return cafe_open
func export_extra_save_data() -> Dictionary:
	return {"inventory":inventory,"stats":stats,"quest_progress":quest_progress,"quest_claimed":quest_claimed,"cafe_open":cafe_open}
func import_extra_save_data(data: Dictionary) -> void:
	inventory = data.get("inventory",inventory)
	stats = data.get("stats",stats)
	quest_progress = data.get("quest_progress",quest_progress)
	quest_claimed = data.get("quest_claimed",quest_claimed)
	cafe_open = bool(data.get("cafe_open",true))
	_refresh_hud()
