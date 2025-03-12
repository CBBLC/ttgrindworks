extends ItemScript

var cost_action : CostOfLaff

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(on_battle_started)

func on_battle_started(battle : BattleManager) -> void:
	battle.s_round_started.connect(on_round_started)
	battle.s_action_started.connect(gag_used)
	battle.s_round_ended.connect(round_ended)
	print("Battle Started")

func on_round_started(actions : Array[BattleAction]):
	var last_toon_idx = -1;
	for i in range(actions.size()):
		if actions[i] is ToonAttack and i > last_toon_idx:
			last_toon_idx = i
	
	if last_toon_idx == -1: return
	
	cost_action = CostOfLaff.new()
	cost_action.action_name = ""
	cost_action.accuracy = Globals.ACCURACY_GUARANTEE_HIT
	cost_action.ignore_stats = true
	cost_action.attack_lines = []
	cost_action.user = Util.get_player()
	cost_action.target_type = cost_action.ActionTarget.SELF
	cost_action.targets.append(Util.get_player())
	cost_action.store_boost_text("Cost of Laff", Color.RED)
	cost_action.damage = 0
	
	# Inject self-damage action to after all gags are used.
	BattleService.ongoing_battle.inject_battle_action(cost_action, last_toon_idx+1)

func gag_used(gag : BattleAction) -> void:
	if gag is ToonAttack:
		if cost_action:
			cost_action.damage += gag.price
		print(gag.price)

func round_ended():
	var regen_amt := 0
	for track in Util.get_player().stats.gag_regeneration:
		if Util.get_player().stats.gags_unlocked[track] > 0:
			regen_amt += Util.get_player().stats.gag_regeneration[track]
	Util.get_player().quick_heal(regen_amt)
