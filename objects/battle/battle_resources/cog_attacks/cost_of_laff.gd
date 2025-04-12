extends CogAttack
class_name CostOfLaff

func action() -> void:
	var target : Player = targets[0]
	manager.s_focus_char.emit(target)
	target.set_animation("cringe")
	
	manager.affect_target(target, damage, false)
	
	await manager.sleep(2.25)
