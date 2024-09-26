class_name UIPlayerCounter
extends PanelContainer

@export var player_index := 0

var title_box: PanelContainer
var title_label: Label
var candy_label: Label

func _ready() -> void:
	title_box = get_node("TitleBox")
	title_label = title_box.get_node("Label")
	title_label.text = "Player %d" % (player_index + 1)
	candy_label = get_node("Candy")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var candy_count = CookSave.get_count("candy", player_index)
	candy_label.text = str(candy_count)
