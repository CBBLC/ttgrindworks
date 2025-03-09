extends ItemScript

const GAG_USE_BONUS := 0.05
const GAG_NEGLECT_PENALTY := -0.03

var player : Player

var stat_changes : Dictionary[String, float] = {}

var unused_tracks : Array[String]

func on_collect(_item: Item, _object: Node3D) -> void:
	var _player: Player
	if not Util.get_player():
		_player = await Util.s_player_assigned
	else:
		_player = Util.get_player()
	setup(_player)

func on_load(item: Item) -> void:
	on_collect(item, null)

func setup(_player: Player) -> void:
	player = _player
	for track in player.stats.gag_effectiveness.keys():
		stat_changes[track] = 0.0
	BattleService.s_battle_started.connect(battle_started)
	BattleService.s_action_finished.connect(gag_used)
	Util.s_floor_started.connect(on_floor_start)

func on_floor_start(game_floor: GameFloor) -> void:
	game_floor.s_floor_ended.connect(on_floor_end)

func on_floor_end() -> void:
	for track in stat_changes.keys():
		player.stats.gag_effectiveness[track] -= stat_changes[track]
		stat_changes[track] = 0.0
	print("Franz: Floor Ended")

func battle_started(battle: BattleManager) -> void:
	var battle_ui: BattleUI = battle.battle_ui
	battle.s_round_started.connect(func(_actions): unused_tracks = get_unlocked_tracks())
	battle.s_round_ended.connect(round_ended.bind(battle_ui))
	
	unused_tracks = get_unlocked_tracks()
	await battle.s_ui_initialized
	update_track_labels(battle_ui)

func gag_used(gag: ActionScript) -> void:
	if not gag is ToonAttack: return
	
	var track_name : String = ""
	
	if gag is GagSquirt:
		track_name = "Squirt"
	elif gag is GagTrap:
		track_name = "Trap"
	elif gag is GagLure:
		track_name = "Lure"
	elif gag is GagSound:
		track_name = "Sound"
	elif gag is GagThrow:
		track_name = "Throw"
	elif gag is DropBig or gag is DropSmall:
		track_name = "Drop"
	
	if not track_name.is_empty() and unused_tracks.has(track_name):
		unused_tracks.erase(track_name)
		player.stats.gag_effectiveness[track_name] += GAG_USE_BONUS
		stat_changes[track_name] += GAG_USE_BONUS
		Util.get_player().boost_queue.queue_text.callv(
			[str(track_name, " Up!"), Color.GREEN])
		force_battle_stats_update(BattleService.ongoing_battle)
		
	print(player.stats.gag_effectiveness)

func round_ended(battle_ui : BattleUI):
	var track_string := ""
	for track_name in unused_tracks:
		if not track_string.is_empty():
			track_string += ", "
		
		player.stats.gag_effectiveness[track_name] += GAG_NEGLECT_PENALTY
		stat_changes[track_name] += GAG_NEGLECT_PENALTY
		force_battle_stats_update(BattleService.ongoing_battle)
		track_string += track_name
		
	Util.get_player().boost_queue.queue_text.callv(
		[str(track_string, " Down"), Color.RED])
	
	print(player.stats.gag_effectiveness)
	update_track_labels(battle_ui)

func update_track_labels(battle_ui : BattleUI):
	for track_name in get_unlocked_tracks():
		var track : TrackElement
		for child in battle_ui.gag_tracks.get_children():
			if child is TrackElement and child.track.track_name == track_name:
				track = child
		if is_instance_valid(track):
			track.track_label.text = "%s(%+d%%)" % [track_name, stat_changes[track_name]*100]

func get_unlocked_tracks() -> Array[String]:
	var unlocked : Array[String] = []
	for track in player.stats.gags_unlocked:
		if player.stats.gags_unlocked[track] != 0:
			unlocked.append(track)
	return unlocked

func force_battle_stats_update(battle : BattleManager):
	var stats = battle.battle_stats[player]
	if stats is PlayerStats:
		stats.gag_effectiveness = player.stats.gag_effectiveness.duplicate()
