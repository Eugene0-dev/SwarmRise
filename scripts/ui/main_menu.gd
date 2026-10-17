extends Control

@onready var background: WorldMap = $"../../WorldMap"
@onready var play_button: Button = $Panel/VBoxContainer/Play
@onready var quit_button: Button = $Panel/VBoxContainer/Quit
@onready var load_button: Button = $Panel/VBoxContainer/Load
@onready var settings_button: Button = $Panel/VBoxContainer/Settings
@onready var github_button: TextureButton = $Github_Button

@onready var settings_panel: Panel = $Settings_Panel
var is_settings_active: bool = false
@onready var load_panel: Panel = $Load_Panel
var is_load_active: bool = false

func _on_play_pressed() -> void:
	for thread in background.threads:
		WorkerThreadPool.wait_for_task_completion(thread)
	get_tree().change_scene_to_file("res://scenes/world.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_github_button_pressed() -> void:
	OS.shell_open("https://github.com/Eugene0-dev/TeamTestProject")

func _on_load_pressed() -> void:
	var pos: Vector2
	pos.y = 0
	var screen_width = get_viewport().get_visible_rect().size.x
	if is_load_active: pos.x = screen_width
	else: pos.x = screen_width - load_panel.size.x
	create_tween().tween_property(load_panel, "position", pos, 1.0).set_trans(Tween.TRANS_EXPO)
	is_load_active = !is_load_active

func _on_settings_pressed() -> void:
	var pos: Vector2
	pos.y = 0
	if is_settings_active: pos.x = -settings_panel.size.x
	else: pos.x = 0
	create_tween().tween_property(settings_panel, "position", pos, 1.0).set_trans(Tween.TRANS_EXPO)
	is_settings_active = !is_settings_active
