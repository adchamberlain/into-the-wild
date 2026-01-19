extends CanvasLayer
## Heads-up display showing time and other info.

@export var time_manager_path: NodePath

@onready var time_label: Label = $TimeContainer/TimeLabel
@onready var period_label: Label = $TimeContainer/PeriodLabel

var time_manager: Node


func _ready() -> void:
	if time_manager_path:
		time_manager = get_node(time_manager_path)
		time_manager.time_changed.connect(_on_time_changed)
		time_manager.period_changed.connect(_on_period_changed)
		_update_display()


func _update_display() -> void:
	if time_manager:
		time_label.text = time_manager.get_time_string()
		period_label.text = time_manager.get_period_name()


func _on_time_changed(_hour: int, _minute: int) -> void:
	_update_display()


func _on_period_changed(period: String) -> void:
	period_label.text = period
