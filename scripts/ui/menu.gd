extends Control

@export var world_map: WorldMap

@onready var cont_button: Button
@onready var exit_button: Button
@onready var main_menu_button: Button
@onready var save_button: Button
@onready var seed_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	cont_button = $Panel/VBoxContainer/Continue_Button
	exit_button = $Panel/VBoxContainer/Exit_Button
	main_menu_button = $Panel/VBoxContainer/Main_Menu_Button
	save_button = $Panel/VBoxContainer/Save_Button
	seed_label = $Seed_Label
	if world_map:
		seed_label.text = "Seed:%d" % world_map.world_seed

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("esc"): switch_visibility()

func switch_visibility() -> void:
	visible = !visible 
	get_tree().paused = visible

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_continue_button_pressed() -> void:
	switch_visibility()

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_save_button_pressed() -> void:
	Global.emit_signal("save_game")
