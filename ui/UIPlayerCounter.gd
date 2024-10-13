class_name UIPlayerCounter
extends Control

@export var player_index := 0

var color_bar: ColorRect
var title_label: Label
var candy_label: Label
var color: Color
var candy_count := 0
var dec_time = 0.0

func _enter_tree() -> void:
	color_bar = get_node("Colorbar")
	title_label = get_node("Label")
	candy_label = get_node("Candy")


func _process(delta: float) -> void:
	var prev_candy_count = candy_count
	candy_count = CookSave.get_count("candy", player_index)
	candy_label.text = str(candy_count)
	if candy_count < prev_candy_count:
		dec_time = 0.1
	if dec_time > 0.0:
		dec_time -= delta
		candy_label.add_theme_color_override("font_color", Color.RED)
	else:
		dec_time = 0.0
		candy_label.remove_theme_color_override("font_color")
	
	
func setup(index: int, _color: Color) -> void:
	player_index = index
	color = _color
	get_node("Colorbar").color = color
	if index == 1 and GhostGame.player_count < 2:
		title_label.text = " GHOST"
	else:
		title_label.text = " P%d" % (player_index + 1)
