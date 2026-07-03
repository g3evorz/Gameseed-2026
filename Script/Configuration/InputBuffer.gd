extends Node
class_name InputBuffer

@export var default_buffer_time: float = 0.15

# Dictionary untuk melacak action apa saja yang sedang di-buffer
var active_buffers: Dictionary = {}

func _physics_process(delta: float) -> void:
	# Kurangi waktu setiap frame dan hapus action jika waktunya habis
	var actions_to_remove = []
	
	for action in active_buffers.keys():
		active_buffers[action] -= delta
		if active_buffers[action] <= 0.0:
			actions_to_remove.append(action)
			
	for action in actions_to_remove:
		active_buffers.erase(action)

# Panggil ini saat pemain menekan tombol
func set_buffer(action_name: String, time: float = default_buffer_time) -> void:
	active_buffers[action_name] = time

# Panggil ini untuk mengecek apakah input masih valid
func is_buffered(action_name: String) -> bool:
	return active_buffers.has(action_name)

# Panggil ini setelah aksi berhasil dieksekusi agar tidak terpicu 2 kali
func consume(action_name: String) -> void:
	if active_buffers.has(action_name):
		active_buffers.erase(action_name)
