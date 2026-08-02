extends Node

@export var button: Button
@export var audio_setting: AudioSetting

func _ready() -> void:
	button.connect(&"pressed",_on_button_pressed)
	
	#AudioManager._play(&"click",AudioManager.AudioType.OMNI,null,&"Music",-1,null,true)

func _on_button_pressed() -> void:
	audio_setting.volume_db = randf_range(0,10.0)
	audio_setting.pitch_scale = randf_range(0.5,1.5)
	
	AudioManager.play(&"click",-1,audio_setting)
