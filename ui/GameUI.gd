extends Control

var ui_counters: Control
var ui_pause: Control
var is_paused := true
var time_since_pause = 0.0

func _ready() -> void:
	ui_counters = get_node("Counters")
	ui_pause = get_node("UIPause")
	set_paused(false)


func _process(delta: float) -> void:
	time_since_pause += delta
	if time_since_pause > 1.0:
		for i in range(CookInput.player_count):
			if CookInput.get_input(i).start_fired or CookInput.get_input(i).back_fired:
				set_paused(not is_paused)
			
			
func set_paused(on: bool) -> void:
	if is_paused == on:
		return
	is_paused = on
	ui_counters.visible = not on
	ui_pause.visible = on
	GhostGame.set_paused(on)
	time_since_pause = 0.0
	if on:
		ui_pause.get_node("Buttons").grab_focus()
		ui_pause.get_node("Buttons/BtnRestart").visible = GhostGame.player_count < 2
		CookMusic.play("GhostTitle", false, CookMusic.position)
	else:
		CookMusic.play("GhostGameplay", false, CookMusic.position)
	
	
func continue_game() -> void:
	set_paused(false)
	
	
func quit() -> void:
	GhostGame.to_title()
	
	
func restart() -> void:
	GhostGame.restart_level()
