
extends Control

@onready var time_label: Label = $Time_Label
@onready var date_label: Label = $Date_Label

func _ready() -> void:
	Global.tick.connect(_on_tick)
	
func _on_tick() -> void:
	time_label.text = "hour: %d" % Global.hour
	date_label.text = "%d/%d/%d" % [Global.year, Global.month, Global.day]
	queue_redraw()
