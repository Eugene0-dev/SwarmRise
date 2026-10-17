extends Panel

@onready var world_size_option_button: OptionButton = $Settings_Horizontal/World_Size/OptionButton
@onready var retile_mode_option_button: OptionButton = $Settings_Horizontal/Retile_Mode/OptionButton

func _ready() -> void:
	for w_size_option in Settings.size:
		world_size_option_button.add_item(w_size_option)
	world_size_option_button.select(Settings.world_size)
	
	for rt_mode_option in Settings.retile_mode:
		retile_mode_option_button.add_item(rt_mode_option)
	retile_mode_option_button.select(Settings.retile)

func _on_world_size_item_selected(index: int) -> void:
	Settings.world_size = index

func _on_retile_mode_item_selected(index: int) -> void:
	Settings.retile = index
