class_name UIPlayerCounter
extends Control

@export var player_index := 0

var color_bar: ColorRect
var title_label: Label
var candy_label: Label
var color: Color

func _enter_tree() -> void:
	color_bar = get_node("Colorbar")
	title_label = get_node("Label")
	candy_label = get_node("Candy")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var candy_count = CookSave.get_count("candy", player_index)
	candy_label.text = str(candy_count)
	
	
func setup(index: int, color: Color) -> void:
	self.player_index = index
	self.color = color
	get_node("Colorbar").color = color
	title_label.text = " P%d" % (player_index + 1)
