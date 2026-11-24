@tool
extends Node

enum AudioType { OMNI, TWO_D, THREE_D, ALL }
const default_audio_bus: Array[StringName] = [&"Master", &"Music", &"SFX", &"Ambience"]
static var default_audio_setting: AudioSetting = AudioSetting.new()

@export var audio_library: AudioLibrary = null
@export var audio_setting_library: AudioSettingLibrary = null

@export_group("Omni")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var omni_enabled: bool = true
@export_range(0, 10, 1, "or_greater") var max_omni: int = 10

@export_group("2D")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var audio_2d_enabled: bool = false
@export_range(0, 10, 1, "or_greater") var max_2d: int = 10

@export_group("3D")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var audio_3d_enabled: bool = false
@export_range(0, 10, 1, "or_greater") var max_3d: int = 10

var _library_cache: Dictionary = {}
var _active_players: Dictionary = {}
var _loop_players: Dictionary = {}

var _pool_omni: Array[AudioStreamPlayer] = []
var _pool_2d: Array[AudioStreamPlayer2D] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []

var _unique_key: StringName = &""

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_initialize_resources()

func _initialize_resources() -> void:
	if not audio_library:
		push_error("Initialization failed: AudioLibrary is missing.")
		return
	_cache_library_entries()
	_initialize_pools()

func _cache_library_entries() -> void:
	for entry in audio_library.entries:
		if not entry.key:
			continue
		_library_cache[entry.key] = entry

func _initialize_pools() -> void:
	if omni_enabled:
		_build_pool(AudioStreamPlayer, _pool_omni, max_omni)
	if audio_2d_enabled:
		_build_pool(AudioStreamPlayer2D, _pool_2d, max_2d)
	if audio_3d_enabled:
		_build_pool(AudioStreamPlayer3D, _pool_3d, max_3d)

func _build_pool(type: Variant, pool: Array, count: int) -> void:
	for i in count:
		var player: Node = type.new()
		add_child(player)
		pool.append(player)

func is_playing(key: StringName) -> bool:
	var instances: Array = _active_players.get(key, [])
	for player: Node in instances:
		if is_instance_valid(player) and player.is_playing():
			return true
	var loop_player: Node = _loop_players.get(key)
	if is_instance_valid(loop_player) and loop_player.is_playing():
		return true
	return false

func play_once(key: StringName, setting_index: int = -1, audio_setting: AudioSetting = null, bus: StringName = default_audio_bus[2], loop: bool = false) -> void:
	if is_playing(key):
		return
	play(key, setting_index, audio_setting, bus, loop)

func play(key: StringName, setting_index: int = -1, audio_setting: AudioSetting = null, bus: StringName = default_audio_bus[2], loop: bool = false) -> void:
	_play(key, AudioType.OMNI, null, setting_index, audio_setting, bus, loop)

func play_2d(key: StringName, pos: Vector2, setting_index: int = -1, audio_setting: AudioSetting = null, bus: StringName = default_audio_bus[2], loop: bool = false) -> void:
	_play(key, AudioType.TWO_D, pos, setting_index, audio_setting, bus, loop)

func play_3d(key: StringName, pos: Vector3, setting_index: int = -1, audio_setting: AudioSetting = null, bus: StringName = default_audio_bus[2], loop: bool = false) -> void:
	_play(key, AudioType.THREE_D, pos, setting_index, audio_setting, bus, loop)

func play_unique(key: StringName, setting_index: int = -1, audio_setting: AudioSetting = null, bus: StringName = default_audio_bus[1]) -> void:
	if key == _unique_key and is_playing(key):
		return
	if is_playing(_unique_key):
		_stop(_unique_key, -1, AudioType.ALL, null, 0.0, &"")
	_unique_key = key
	_play(key, AudioType.OMNI, null, setting_index, audio_setting, bus, true)

func stop(key: StringName, count: int = 1, bus: StringName = &"") -> void:
	_stop(key, count, AudioType.ALL, null, 0.0, bus)

func stop_2d(key: StringName, count: int = 1, pos: Vector2 = Vector2.ZERO, radius: float = 0.0, bus: StringName = &"") -> void:
	_stop(key, count, AudioType.TWO_D, pos, radius, bus)

func stop_3d(key: StringName, count: int = 1, pos: Vector3 = Vector3.ZERO, radius: float = 0.0, bus: StringName = &"") -> void:
	_stop(key, count, AudioType.THREE_D, pos, radius, bus)

func stop_bus(bus: StringName) -> void:
	var keys: Array = _active_players.keys()
	keys.append_array(_loop_players.keys())
	for key: StringName in keys:
		_stop(key, -1, AudioType.ALL, null, 0.0, bus)

func stop_all() -> void:
	var keys: Array = _active_players.keys()
	keys.append_array(_loop_players.keys())
	for key: StringName in keys:
		_stop(key, -1, AudioType.ALL, null, 0.0, &"")

func _play(key: StringName, type: AudioType, pos: Variant, setting_index: int = -1, audio_setting: AudioSetting = null, bus: StringName = default_audio_bus[0], loop: bool = false) -> void:
	var entry: Resource = _library_cache.get(key)
	if not entry:
		push_error("Audio key not found: %s" % key)
		return
	var stream: AudioStream = _load_stream_from_entry(entry)
	if stream == null:
		push_error("Failed to load audio for key: %s" % key)
		return
	if loop:
		_play_loop(key, type, pos, bus, setting_index, audio_setting, stream)
	else:
		_play_single(key, type, pos, bus, setting_index, audio_setting, stream)

func _play_loop(key: StringName, type: AudioType, pos: Variant, bus: StringName, setting_index: int, audio_setting: AudioSetting, stream: AudioStream) -> void:
	if is_playing(key):
		return
	var player: Node = _create_player(type)
	if not player:
		push_error("Failed to create loop player for type: %s" % type)
		return
	player.stream = stream
	player.bus = bus
	_apply_settings(player, setting_index, audio_setting)
	_apply_stream_settings(player, true, pos)
	_loop_players[key] = player
	player.play()

func _play_single(key: StringName, type: AudioType, pos: Variant, bus: StringName, setting_index: int, audio_setting: AudioSetting, stream: AudioStream) -> void:
	var player: Node = _request_available_player(type)
	if not player:
		push_error("No player found for AudioType: %s" % type)
		return
	player.stream = stream
	player.bus = bus
	_apply_settings(player, setting_index, audio_setting)
	_apply_stream_settings(player, false, pos)
	_track_active_instance(key, player)
	player.play()

func _create_player(type: AudioType) -> Node:
	var player: Node
	if type == AudioType.TWO_D:
		player = AudioStreamPlayer2D.new()
	elif type == AudioType.THREE_D:
		player = AudioStreamPlayer3D.new()
	else:
		player = AudioStreamPlayer.new()
	add_child(player)
	return player

func _load_stream_from_entry(entry: Resource) -> AudioStream:
	if not entry.path:
		push_error("No path for audio entry")
		return null
	var stream: AudioStream = ResourceLoader.load(entry.path)
	if not stream:
		push_error("Failed to load audio at: %s" % entry.path)
		return null
	return stream

func _apply_settings(player: Node, setting_index: int, audio_setting: AudioSetting) -> void:
	if setting_index < 0:
		if not audio_setting:
			_apply_audio_settings(player, default_audio_setting)
			return
		_apply_audio_settings(player, audio_setting)
		return
	if not audio_setting_library:
		push_warning("There is no audio_setting_library")
		return
	if audio_setting_library.entries.is_empty():
		push_warning("audio_setting_library is empty")
		return
	_apply_audio_settings(player, audio_setting_library.entries[setting_index])

func _apply_audio_settings(player: Node, settings: AudioSetting) -> void:
	player.volume_db = settings.volume_db
	player.pitch_scale = settings.pitch_scale
	player.max_polyphony = settings.max_polyphony
	player.playback_type = settings.playback_type
	if player is AudioStreamPlayer:
		player.mix_target = settings.mix_target
		return
	if player is AudioStreamPlayer2D:
		player.attenuation = settings.attenuation
		player.max_distance = settings.max_distance_2d
		player.area_mask = settings.area_mask_2d
		player.panning_strength = settings.panning_strength
		return
	if player is AudioStreamPlayer3D:
		player.attenuation_model = settings.attenuation_model
		player.unit_size = settings.unit_size
		player.max_db = settings.max_db
		player.max_distance = settings.max_distance_3d
		player.area_mask = settings.area_mask_3d
		player.emission_angle_enabled = settings.emission_angle_enabled
		player.emission_angle_degrees = settings.emission_angle_degrees
		player.emission_angle_filter_attenuation_db = settings.emission_angle_filter_attenuation_db
		player.attenuation_filter_cutoff_hz = settings.attenuation_filter_cutoff_hz
		player.attenuation_filter_db = settings.attenuation_filter_db
		player.doppler_tracking = settings.doppler_tracking
		player.panning_strength = settings.panning_strength
		return

func _apply_stream_settings(player: Node, loop: bool, pos: Variant) -> void:
	var stream: AudioStream = player.stream
	if stream is AudioStreamWAV:
		if loop:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = loop
	if player is AudioStreamPlayer2D:
		player.global_position = pos
	elif player is AudioStreamPlayer3D:
		player.global_position = pos

func _request_available_player(type: AudioType) -> Node:
	var pool: Array = _get_pool_by_type(type)
	if pool.is_empty():
		return null
	for i in pool.size():
		if not pool[i].is_playing():
			var player: Node = pool.pop_at(i)
			pool.append(player)
			return player
	var oldest: Node = pool.pop_front()
	oldest.stop()
	pool.append(oldest)
	return oldest

func _get_pool_by_type(type: AudioType) -> Array:
	if type == AudioType.TWO_D:
		return _pool_2d
	if type == AudioType.THREE_D:
		return _pool_3d
	return _pool_omni

func _track_active_instance(key: StringName, player: Node) -> void:
	var list: Array = _active_players.get(key, [])
	if player not in list:
		list.append(player)
		_active_players[key] = list

func _stop(key: StringName, count: int = 1, type: AudioType = AudioType.ALL, pos: Variant = null, radius: float = 0.0, bus: StringName = &"") -> void:
	var instances: Array = _active_players.get(key, [])
	var remaining: int = _stop_instances(instances, count, type, pos, radius, bus)
	if instances.is_empty():
		_active_players.erase(key)
	_stop_loop_player(key, remaining, type, pos, radius, bus)

func _stop_instances(instances: Array, count: int, type: AudioType, pos: Variant, radius: float, bus: StringName) -> int:
	var remaining: int = count
	for i in range(instances.size() - 1, -1, -1):
		if remaining == 0:
			break
		var player: Node = instances[i]
		if not is_instance_valid(player):
			instances.remove_at(i)
			continue
		if not _matches_stop_filters(player, type, pos, radius, bus):
			continue
		player.stop()
		instances.remove_at(i)
		if remaining > 0:
			remaining -= 1
	return remaining

func _stop_loop_player(key: StringName, remaining: int, type: AudioType, pos: Variant, radius: float, bus: StringName) -> void:
	if remaining == 0:
		return
	var loop_player: Node = _loop_players.get(key)
	if not is_instance_valid(loop_player):
		_loop_players.erase(key)
		return
	if not _matches_stop_filters(loop_player, type, pos, radius, bus):
		return
	loop_player.stop()
	loop_player.queue_free()
	_loop_players.erase(key)

func _matches_stop_filters(player: Node, type: AudioType, pos: Variant, radius: float, bus: StringName) -> bool:
	if not _matches_type(player, type):
		return false
	if bus != &"" and player.bus != bus:
		return false
	if pos == null or radius <= 0.0:
		return true
	return _is_within_radius(player, pos, radius)

func _matches_type(player: Node, type: AudioType) -> bool:
	if type == AudioType.ALL:
		return true
	if type == AudioType.TWO_D:
		return player is AudioStreamPlayer2D
	if type == AudioType.THREE_D:
		return player is AudioStreamPlayer3D
	return player is AudioStreamPlayer

func _is_within_radius(player: Node, pos: Variant, radius: float) -> bool:
	if player is AudioStreamPlayer:
		return true
	if player is AudioStreamPlayer2D and pos is Vector2:
		return player.global_position.distance_to(pos) <= radius
	if player is AudioStreamPlayer3D and pos is Vector3:
		return player.global_position.distance_to(pos) <= radius
	return false
