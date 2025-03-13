extends ItemScript
class_name ItemPeteReduction

func on_collect(_item: Item, _object: Node3D) -> void:
	setup()

func on_load(_item: Item) -> void:
	setup()

func setup() -> void:
	BattleService.s_battle_started.connect(battle_started)

func battle_started(battle : BattleManager):
	battle.s_round_ended.connect(round_ended)

func round_ended():
	var player_stats : PlayerStats = Util.get_player().stats
	print(player_stats.gag_balance)
	#var battle_stats = BattleService.ongoing_battle.battle_stats[Util.get_player()]
	for track in player_stats.gag_balance:
		if player_stats.gag_balance[track] == 0:
			player_stats.gags_unlocked[track] -= 1
			#battle_stats.gags_unlocked[track] -= 1
			player_stats.gag_balance[track] = player_stats.gag_cap
	
	for track in BattleService.ongoing_battle.battle_ui.gag_tracks.get_children():
		track.unlocked = Util.get_player().stats.gags_unlocked[track.track.track_name]
		track.refresh()

static func get_voucher_rate() -> float:
	if not Util.get_player():
		return 0
	
	var player : Player = Util.get_player()
	var total_vouchers := 0
	for track in player.stats.gag_vouchers:
		total_vouchers += player.stats.gag_vouchers[track]
	
	var target_vouchers := 12.0
	
	# Stolen from item_script.gd
	var chance := (1.0 - (total_vouchers / target_vouchers)) * 1.35
	return chance
