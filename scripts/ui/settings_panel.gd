extends Panel

@onready var world_size_option_button: OptionButton = $Settings_Horizontal/World_Size/OptionButton

func _ready() -> void:
	for w_size_option in Settings.size:
		world_size_option_button.add_item(w_size_option)
	world_size_option_button.select(Settings.world_size)


func _on_option_button_item_selected(index: int) -> void:
	Settings.world_size = index
