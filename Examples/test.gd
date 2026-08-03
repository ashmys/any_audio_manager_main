extends Node

@export var music_setting: AudioSetting
@export var button_sfx: Button
@export var button_music: Button
@export var button_unique: Button
@export var button_stop_all: Button

var audio_setting: AudioSetting = AudioSetting.new()

const musics: Array[StringName] = [&"Gypsy-Doo-Wop",&"Balance"]

func _ready() -> void:
	button_sfx.connect(&"pressed",_on_button_sfx_pressed)
	button_music.connect(&"pressed",_on_button_music_pressed)
	button_unique.connect(&"pressed",_on_button_unique_pressed)
	button_stop_all.connect(&"pressed",_on_button_stop_all_pressed)
	
	#AudioManager._play(&"click",AudioManager.AudioType.OMNI,null,&"Music",-1,null,true)

func _on_button_sfx_pressed() -> void:
	audio_setting.volume_db = randf_range(0,10.0)
	audio_setting.pitch_scale = randf_range(0.5,1.5)
	
	AudioManager.play(&"click",-1,audio_setting)

func _on_button_music_pressed() -> void:
	AudioManager.play(&"Balance", -1, music_setting, &"Music", true)

func _on_button_unique_pressed() -> void:
	AudioManager.play_unique(musics[randi_range(0, musics.size() - 1)])

func _on_button_stop_all_pressed() -> void:
	AudioManager.stop_all()
