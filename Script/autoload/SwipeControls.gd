extends Node

var minimum_drag_distance = 100 
var swipe_start_position = Vector2.ZERO 

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start_position = event.position
		else:
			_calculate_swipe(event.position)

func _calculate_swipe(swipe_end_position: Vector2):
	var swipe_distance = swipe_end_position - swipe_start_position
	
	if abs(swipe_distance.y) > minimum_drag_distance:
		if swipe_distance.y < 0:
			# Panggil fungsi penipu input untuk aksi UP Anda (misal: "move_up" atau "lompat")
			_trigger_action("ui_up") 
		else:
			# Panggil fungsi penipu input untuk aksi DOWN Anda (misal: "move_down" atau "menunduk")
			_trigger_action("ui_down")

# Fungsi ini yang menjembatani swipe dengan Input Map bawaan Godot
func _trigger_action(action_name: String):
	# 1. Simulasikan aksi ditekan ke dalam sistem Godot
	Input.action_press(action_name)
	
	# 2. Simulasikan aksi dilepas pada frame berikutnya
	# call_deferred sangat penting di sini agar Godot punya waktu (1 frame) 
	# untuk mendaftarkan status "is_action_just_pressed" di script karakter Anda.
	Input.call_deferred("action_release", action_name)
