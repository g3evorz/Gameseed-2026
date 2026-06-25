extends Node2D

# Referensi ke wadah semua spawner rintangan
@onready var spawners_container: Node2D = $Spawners

func _ready() -> void:
	# Memicu semua spawner rintangan saat chunk baru saja dimuat ke arena
	trigger_all_spawners()

func _process(delta: float) -> void:

	position.x -= GameManager.current_world_speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# Membersihkan memori saat chunk sudah tidak terlihat
	#print("Level Chunk [", name, "] Terhapus!")
	queue_free()

func trigger_all_spawners() -> void:
	# Keamanan: Pastikan container spawner ada
	if not spawners_container:
		return
		
	# Looping ke semua spawner dan panggil fungsinya
	for spawner in spawners_container.get_children():
		if spawner.has_method("spawn_obstacle"):
			spawner.spawn_obstacle()
