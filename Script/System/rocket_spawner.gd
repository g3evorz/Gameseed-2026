extends Marker2D
class_name RocketSpawner

@export var rocket_scene: PackedScene

# --- Pengaturan Randomizer & Cooldown ---
@export_range(0.0, 1.0) var spawn_chance: float = 0.6 # 60% peluang roket muncul
@export var cooldown_duration: float = 2.5 # Jeda minimal antar roket (detik)
@export var random_y_offset: float = 150.0 # Seberapa jauh roket bisa melenceng ke atas/bawah (pixel)

var _is_on_cooldown: bool = false

func _ready() -> void:
	_connect_existing_enemies()
	get_tree().node_added.connect(_on_node_added)

func _connect_existing_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		_connect_enemy(enemy)

func _on_node_added(node: Node) -> void:
	await get_tree().process_frame 
	if node.is_in_group("Enemy"):
		_connect_enemy(node)

func _connect_enemy(enemy: Node) -> void:
	if enemy.has_signal("obstacle_dropped"):
		if not enemy.obstacle_dropped.is_connected(_spawn_rocket):
			enemy.obstacle_dropped.connect(_spawn_rocket)

func _spawn_rocket(_drop_position: Vector2) -> void:
	# 1. CEK COOLDOWN: Kalau masih jeda, abaikan sinyal ini
	if _is_on_cooldown:
		return
		
	# 2. CEK PELUANG: Kocok dadu, kalau gagal lewati batas, batal spawn
	if randf() > spawn_chance:
		return

	if rocket_scene == null:
		push_warning("RocketSpawner: rocket_scene belum diisi!")
		return
		
	# 3. AKTIFKAN COOLDOWN
	_is_on_cooldown = true
	get_tree().create_timer(cooldown_duration).timeout.connect(_reset_cooldown)
		
	# 4. INSTANSIASI ROKET
	var rocket_instance = rocket_scene.instantiate()
	get_tree().current_scene.add_child(rocket_instance)
	
	# 5. RANDOMIZER POSISI Y
	# Ambil posisi spawner, lalu acak nilai Y-nya ditambah/dikurang offset
	var spawn_pos = global_position
	
	rocket_instance.global_position = spawn_pos

func _reset_cooldown() -> void:
	_is_on_cooldown = false
