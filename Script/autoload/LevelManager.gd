extends Node

# Kita menyimpan referensi Node (Marker2D), bukan Vector2
var _active_empty_slots: Array[Node2D] = []

func register_empty_slot(slot_node: Node2D) -> void:
	if not _active_empty_slots.has(slot_node):
		_active_empty_slots.append(slot_node)

func unregister_slot(slot_node: Node2D) -> void:
	_active_empty_slots.erase(slot_node)

func get_available_slot_ahead(player_x: float, min_dist: float = 300.0) -> Node2D:
	# Bersihkan slot yang mungkin sudah terhapus (queue_free) dari memori
	_active_empty_slots = _active_empty_slots.filter(func(slot): return is_instance_valid(slot))
	
	var valid_slots = _active_empty_slots.filter(
		func(slot): return slot.global_position.x > (player_x + min_dist)
	)
	
	if valid_slots.is_empty():
		return null
		
	# Urutkan untuk mencari slot yang paling dekat dengan player
	valid_slots.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	var chosen_slot = valid_slots[0]
	
	# Hapus dari daftar agar tidak dibajak oleh dua musuh sekaligus
	unregister_slot(chosen_slot) 
	return chosen_slot
