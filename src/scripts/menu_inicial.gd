extends Control

@onready var play_button: Button = $PlayButton
@onready var config_button: Button = $ConfigButton
@onready var quit_button: Button = $QuitButton
@onready var note_text: Label = $Note
@onready var config_panel: Panel = $ConfigPanel

var nts = ["DA", "5HT", "NA"]
var params = ["Beta", "Alpha", "Gamma"]
#var modulations = ["Openness", "Conscientiousness", "Extraversion", "Agreeableness", "Neuroticism", "UAI", "IDV"]

func _ready():
	config_panel.visible = false
	show_menu(true)

func show_menu(visibilidade: bool):
	play_button.visible = visibilidade
	config_button.visible = visibilidade
	quit_button.visible = visibilidade
	note_text.visible = visibilidade

func _update_global_setting(value: float, setting_name: String):
	GlobalSettings.set(setting_name, value)
	
	var label = get_node("%Label_" + setting_name + "_Value") as Label
	label.text = "%.3f" % value

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/simulation_world.tscn")

func _on_config_button_pressed():
	show_menu(false)
	config_panel.visible = true
	
	for nt in nts:
		for p in params:
			_sync_ui_element("%s_%s" % [p, nt])
	
	#for m in modulations:
	#	_sync_ui_element("Mod_%s" % m)

func _sync_ui_element(base_name: String):
	var slider = get_node("%Slider_" + base_name + "_Value") as HSlider
	var label = get_node("%Label_" + base_name + "_Value") as Label
	
	if base_name in GlobalSettings:
		var current_val = GlobalSettings.get(base_name)
		slider.value = current_val
		label.text = str(snapped(current_val, 0.001))
		
		if not slider.value_changed.is_connected(_update_global_setting):
			slider.value_changed.connect(_update_global_setting.bind(base_name))

func _on_back_button_pressed():
	config_panel.visible = false
	show_menu(true)

func _on_quit_button_pressed():
	get_tree().quit()
