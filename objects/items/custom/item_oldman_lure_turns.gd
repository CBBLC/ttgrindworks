extends ItemScript

var starting_turn_count := 1

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(battle_started)
	BattleService.s_battle_ending.connect(battle_ended)

func battle_started(battle : BattleManager) -> void:
	battle.s_round_ended.connect(round_ended.bind(battle))
	battle.s_status_effect_added.connect(effect_added)
	starting_turn_count = Util.get_player().stats.turns

func battle_ended() -> void:
	Util.get_player().stats.turns = starting_turn_count

func round_ended(battle : BattleManager) -> void:
	var prev_turn_count = Util.get_player().stats.turns
	print(get_num_cogs_lured(battle))
	Util.get_player().stats.turns = get_num_cogs_lured(battle) + starting_turn_count
	battle.battle_ui.refresh_turns()
	
	for i in range(prev_turn_count, Util.get_player().stats.turns):
		add_turn_box(battle.battle_ui)
	
	for i in range(Util.get_player().stats.turns, prev_turn_count):
		remove_turn_box(battle.battle_ui)

func get_num_cogs_lured(battle : BattleManager) -> int:
	var count := 0
	for effect in battle.status_effects:
		if effect is StatusLured:
			count += 1
	return count

func add_turn_box(battle_ui : BattleUI) -> void:
	var gag_order_menu = battle_ui.gag_order_menu
	
	var panel = gag_order_menu.gag_panel.duplicate()
	gag_order_menu.add_child(panel)
	gag_order_menu.panels.append(panel)
	
	panel.get_node('GagIcon').mouse_entered.connect(
		gag_order_menu.hover_slot.bind(gag_order_menu.panels.find(panel)))
	panel.get_node('GagIcon').mouse_exited.connect(gag_order_menu.stop_hover)
	panel.get_node('GeneralButton').disabled = true
	panel.get_node('GeneralButton').hide()
	panel.get_node('GeneralButton').pressed.connect(
		gag_order_menu.cancel_gag.bind(gag_order_menu.panels.find(panel)))

func remove_turn_box(battle_ui : BattleUI) -> void:
	var gag_order_menu = battle_ui.gag_order_menu
	# Don't delete the only remaining gag panel
	if gag_order_menu.panels.size() <= 1: return
	
	var panel = gag_order_menu.panels.pop_at(gag_order_menu.panels.size()-1)
	panel.queue_free()

func effect_added(effect : StatusEffect) -> void:
	if effect is StatusLured:
		var target = effect.target
		var all_effects = effect.manager.status_effects
		var effect_count = 0
		for e in all_effects:
			if (e.target == target and 
			not e is StatusLured and
			e.quality == StatusEffect.EffectQuality.NEGATIVE):
				effect_count += 1
		
		effect.rounds = effect_count + 1
