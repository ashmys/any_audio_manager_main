@tool
extends Resource
class_name AudioSetting

@export_range(-80.0, 24.0, 0.01, "suffix:dB") var volume_db: float = 0.0
@export_range(0.01, 4.0, 0.1, "or_greater", "suffix:dB") var pitch_scale: float = 1.0
@export var mix_target: AudioStreamPlayer.MixTarget = AudioStreamPlayer.MIX_TARGET_STEREO
##The maximum number of sounds this node can play at the same time. Calling [method AudioStreamPlayer.play] after this value is reached will cut off the oldest sounds.
@export_range(1, 10, 1, "or_greater") var max_polyphony: int = 1

@export_group("2D")
@export_exp_easing("attenuation", "positive_only") var attenuation: float = 1.0
@export_range(1, 4096, 1, "or_greater", "suffix:px") var max_distance_2d: int = 2000
@export_flags_2d_physics() var area_mask_2d: int = 1

@export_group("3D")
@export var attenuation_model: AudioStreamPlayer3D.AttenuationModel = AudioStreamPlayer3D.AttenuationModel.ATTENUATION_INVERSE_DISTANCE
@export_range(0.1, 100, 0.1, "or_greater") var unit_size: float = 10.0
@export_range(-24.0, 6.0, 0.1, "suffix:db") var max_db: float = 3.0
@export_range(0.0, 4096, 0.01, "or_greater", "suffix:m") var max_distance_3d: float = 0.0
@export_flags_3d_physics() var area_mask_3d: int = 1

@export_subgroup("Emission Angle")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var emission_angle_enabled: bool = false
@export_range(0.1, 90.0, 0.01, "suffix:°") var emission_angle_degrees: float = 45.0
@export_range(-80.0, 0.0, 0.01, "suffix:db") var emission_angle_filter_attenuation_db: float = -12.0

@export_subgroup("Attenuation Filter")
@export_range(1, 20500, 1, "prefer_slider", "suffix:hz") var attenuation_filter_cutoff_hz: int = 5000
@export_range(-80.0, 0.0, 0.1, "suffix:db") var attenuation_filter_db: float = -24.0

@export_subgroup("Doppler")
@export var doppler_tracking: AudioStreamPlayer3D.DopplerTracking = AudioStreamPlayer3D.DopplerTracking.DOPPLER_TRACKING_DISABLED

@export_group("2D & 3D")
##Scales the panning strength for this node by multiplying the base [member ProjectSettings.audio/general/2d_panning_strength] or [member ProjectSettings.audio/general/3d_panning_strength] with this factor. Higher values will pan audio from left to right more dramatically than lower values.
@export_range(0.0, 3.0, 0.01, "or_greater") var panning_strength: float = 1.0

@export_group("")
@export var playback_type: AudioServer.PlaybackType = AudioServer.PlaybackType.PLAYBACK_TYPE_DEFAULT

func _init(
	p_volume_db: float = 0.0,
	p_pitch_scale: float = 1.0,
	p_mix_target: AudioStreamPlayer.MixTarget = AudioStreamPlayer.MIX_TARGET_STEREO,
	p_max_polyphony: int = 1,
	p_attenuation: float = 1.0,
	p_max_distance_2d: int = 2000,
	p_area_mask_2d: int = 1,
	p_attenuation_model: AudioStreamPlayer3D.AttenuationModel = AudioStreamPlayer3D.AttenuationModel.ATTENUATION_INVERSE_DISTANCE,
	p_unit_size: float = 10.0,
	p_max_db: float = 3.0,
	p_max_distance_3d: float = 0.0,
	p_area_mask_3d: int = 1,
	p_emission_angle_enabled: bool = false,
	p_emission_angle_degrees: float = 45.0,
	p_emission_angle_filter_attenuation_db: float = -12.0,
	p_attenuation_filter_cutoff_hz: int = 5000,
	p_attenuation_filter_db: float = -24.0,
	p_doppler_tracking: AudioStreamPlayer3D.DopplerTracking = AudioStreamPlayer3D.DopplerTracking.DOPPLER_TRACKING_DISABLED,
	p_panning_strength: float = 1.0,
	p_playback_type: AudioServer.PlaybackType = AudioServer.PlaybackType.PLAYBACK_TYPE_DEFAULT
) -> void:
	volume_db = p_volume_db
	pitch_scale = p_pitch_scale
	mix_target = p_mix_target
	max_polyphony = p_max_polyphony
	attenuation = p_attenuation
	max_distance_2d = p_max_distance_2d
	area_mask_2d = p_area_mask_2d
	attenuation_model = p_attenuation_model
	unit_size = p_unit_size
	max_db = p_max_db
	max_distance_3d = p_max_distance_3d
	area_mask_3d = p_area_mask_3d
	emission_angle_enabled = p_emission_angle_enabled
	emission_angle_degrees = p_emission_angle_degrees
	emission_angle_filter_attenuation_db = p_emission_angle_filter_attenuation_db
	attenuation_filter_cutoff_hz = p_attenuation_filter_cutoff_hz
	attenuation_filter_db = p_attenuation_filter_db
	doppler_tracking = p_doppler_tracking
	panning_strength = p_panning_strength
	playback_type = p_playback_type
