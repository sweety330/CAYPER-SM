extends Node
class Computer:
    var id: int = 0
    var level: int = 1
    var condition: float = 1.0
    var hourly_revenue: float = 18.0
    var upgrade_cost: int = 350
    var occupied: bool = false
var owned_computers: Array[Computer] = []
var employees: Array[Dictionary] = []
var total_revenue: float = 0.0
var total_expenses: float = 0.0
var day_passed: int = 1
signal business_changed
func _ready() -> void:
    if owned_computers.is_empty():
        for i in range(4): add_computer(false)
        employees = [{"name":"أحمد", "job":"فني", "wage":45}]
func add_computer(charge: bool = true) -> bool:
    if charge and not GameManager.spend_money(650.0): return false
    var pc := Computer.new()
    pc.id = 1
    for old in owned_computers: pc.id = maxi(pc.id, old.id + 1)
    owned_computers.append(pc)
    business_changed.emit()
    return true
func upgrade_computer(computer_id: int) -> bool:
    for pc in owned_computers:
        if pc.id == computer_id:
            if not GameManager.spend_money(float(pc.upgrade_cost)): return false
            pc.level += 1
            pc.hourly_revenue *= 1.30
            pc.upgrade_cost = int(float(pc.upgrade_cost) * 1.55)
            business_changed.emit()
            return true
    return false
func repair_computer(computer_id: int) -> bool:
    for pc in owned_computers:
        if pc.id == computer_id and pc.condition < 1.0:
            if not GameManager.spend_money(120.0): return false
            pc.condition = 1.0
            business_changed.emit()
            return true
    return false
func hire_employee(employee_name: String, job: String, wage: int = 45) -> bool:
    if not GameManager.spend_money(float(wage * 5)): return false
    employees.append({"name":employee_name, "job":job, "wage":wage})
    business_changed.emit()
    return true
func close_day() -> Dictionary:
    var income := 0.0
    var game_root := get_tree().get_first_node_in_group("game_root")
    var reputation_bonus := 1.0
    var business_is_open := true
    if game_root and game_root.has_method("get_cafe_reputation_bonus"): reputation_bonus = game_root.get_cafe_reputation_bonus()
    if game_root and game_root.has_method("is_cafe_open"): business_is_open = game_root.is_cafe_open()
    if business_is_open:
        for pc in owned_computers: income += pc.hourly_revenue * pc.condition * 5.0 * reputation_bonus
    var wages := 0.0
    for employee in employees: wages += float(employee.get("wage", 0)) * 6.0
    var expenses := wages + owned_computers.size() * 18.0 + 120.0
    var profit := income - expenses
    total_revenue += income
    total_expenses += expenses
    GameManager.add_money(profit)
    day_passed += 1
    for pc in owned_computers:
        pc.condition = maxf(0.35, pc.condition - 0.025)
    business_changed.emit()
    return {"income":income, "expenses":expenses, "profit":profit}
func get_stats() -> Dictionary:
    return {"computers":owned_computers.size(), "employees":employees.size(), "revenue":total_revenue, "expenses":total_expenses, "profit":total_revenue-total_expenses, "day":day_passed}
func serialize() -> Dictionary:
    var pcs: Array = []
    for pc in owned_computers: pcs.append({"id":pc.id,"level":pc.level,"condition":pc.condition,"revenue":pc.hourly_revenue,"upgrade_cost":pc.upgrade_cost})
    return {"computers":pcs,"employees":employees,"total_revenue":total_revenue,"total_expenses":total_expenses,"day_passed":day_passed}
func restore(data: Dictionary) -> void:
    owned_computers.clear()
    for item in data.get("computers", []):
        var pc := Computer.new()
        pc.id = int(item.get("id", owned_computers.size()+1))
        pc.level = int(item.get("level", 1))
        pc.condition = clampf(float(item.get("condition", 1.0)), 0.0, 1.0)
        pc.hourly_revenue = float(item.get("revenue", 18.0))
        pc.upgrade_cost = int(item.get("upgrade_cost", 350))
        owned_computers.append(pc)
    employees = data.get("employees", [])
    total_revenue = float(data.get("total_revenue", 0.0))
    total_expenses = float(data.get("total_expenses", 0.0))
    day_passed = int(data.get("day_passed", 1))
    business_changed.emit()
