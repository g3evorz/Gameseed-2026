extends Node
class_name EnemyObstacleSpawner

@export var possible_obstacles: Array[ObstacleData]
@export var current_difficulty: DifficultyConfig
@export var spawn_margin: float = 150.0

@export_group("Zona Terlarang (Temporary Obstacles)")
@export var vertical_spawn_margin: float = 50.0
@export var base_forbidden_radius: float = 110.0
@export var hard_forbidden_radius: float = 70.0
@export var base_safe_gap: float = 180.0
@export var hard_safe_gap: float = 120.0
@export var player_hitbox_height: float = 60.0

var _active_zones: Array[Dictionary] = []
var forbidden_zone_radius: float
var min_safe_gap: float

func _ready() -> void:
	_connect_existing_enemies()
	get_tree().node_added.connect(_on_node_added)

func _physics_process(_delta: float) -> void:
	# Asumsi GameManager masih digunakan untuk mengatur speed ratio
	var ratio: float = GameManager.get_speed_ratio()
	forbidden_zone_radius = lerp(base_forbidden_radius, hard_forbidden_radius, ratio)
	min_safe_gap = max(lerp(base_safe_gap, hard_safe_gap, ratio), player_hitbox_height + 20.0)

	var now: float = Time.get_ticks_msec() / 1000.0
	_active_zones = _active_zones.filter(func(z): return z.expire_time > now)

# --- KONEKSI SINYAL MUSUH ---

func _connect_existing_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		_connect_enemy(enemy)

func _on_node_added(node: Node) -> void:
	await get_tree().process_frame
	if node.is_in_group("Enemy"):
		_connect_enemy(node)

func _connect_enemy(enemy: Node) -> void:
	if enemy.has_signal("obstacle_dropped"):
		if not enemy.obstacle_dropped.is_connected(_on_enemy_obstacle_dropped):
			enemy.obstacle_dropped.connect(_on_enemy_obstacle_dropped)

# --- LOGIKA SPAWN UTAMA ---

func _on_enemy_obstacle_dropped(_drop_position: Vector2) -> void:
	if current_difficulty == null or possible_obstacles.is_empty():
		return

	# 1. Cek peluang utama dari DifficultyConfig
	if randf() > current_difficulty.spawn_chance:
		return

	# 2. Pilih rintangan
	var selected_data = _get_random_obstacle()
	if selected_data == null:
		return

	# 3. Eksekusi
	_execute_spawn(selected_data)

func _get_random_obstacle() -> ObstacleData:
	var valid_obstacles: Array[ObstacleData] = []
	var total_weight: float = 0.0

	# Filter rintangan yang tidak valid untuk situasi saat ini
	for obs in possible_obstacles:
		if obs == null or obs.spawn_behavior == ObstacleData.SpawnBehavior.LEVEL_ONLY:
			continue
			
		if obs.spawn_behavior == ObstacleData.SpawnBehavior.DYNAMIC_PERMANENT and not current_difficulty.allow_permanent_obstacles:
			continue
			
		valid_obstacles.append(obs)
		total_weight += obs.spawn_weight

	if valid_obstacles.is_empty() or total_weight <= 0.0:
		return null

	# Algoritma Weighted Random
	var random_value = randf_range(0.0, total_weight)
	for obs in valid_obstacles:
		random_value -= obs.spawn_weight
		if random_value <= 0.0:
			return obs
			
	return valid_obstacles.back()

func _execute_spawn(obstacle_data: ObstacleData) -> void:
	var player = get_tree().get_first_node_in_group("Player") as Node2D
	var cam = get_viewport().get_camera_2d()
	
	if player == null or cam == null:
		return

	match obstacle_data.spawn_behavior:
		ObstacleData.SpawnBehavior.DYNAMIC_TEMPORARY:
			_spawn_temporary(obstacle_data, player, cam)
		ObstacleData.SpawnBehavior.DYNAMIC_PERMANENT:
			_spawn_permanent(obstacle_data, player)

# --- PENANGANAN TIPE RINTANGAN ---

func _spawn_temporary(obstacle_data: ObstacleData, player: Node2D, cam: Camera2D) -> void:
	var screen_center_y = cam.get_screen_center_position().y
	var visible_rect_size = cam.get_viewport_rect().size / cam.zoom
	var camera_top = screen_center_y - (visible_rect_size.y / 2.0)
	var camera_bottom = screen_center_y + (visible_rect_size.y / 2.0)
	var min_track_y = camera_top + vertical_spawn_margin
	var max_track_y = camera_bottom - vertical_spawn_margin

	# Cek dulu ada ruang aman SECARA UMUM di track, sebelum rocket terlihat di layar.
	# Ini ganti posisi pengecekan lama (yang tadinya dilakukan terhadap kandidat tertentu).
	if not _track_has_room(min_track_y, max_track_y):
		return

	var instance = obstacle_data.obstacle_scene.instantiate()
	if "data" in instance:
		instance.data = obstacle_data

	get_tree().current_scene.add_child(instance)

	var spawn_x = cam.get_right_edge_x(spawn_margin)
	var initial_y = clamp(player.global_position.y, min_track_y, max_track_y)
	instance.global_position = Vector2(spawn_x, initial_y)

	var travel_time: float = obstacle_data.extra_warning_duration
	if "warning_duration" in instance:
		travel_time += instance.warning_duration

	if instance.has_method("initialize_lock_on"):
		# Tipe rocket: serahkan tracking + finalize ke rocket itu sendiri
		instance.initialize_lock_on(
			player, min_track_y, max_track_y,
			Callable(self, "_finalize_target_y"),
			travel_time,
			current_difficulty.targeting_inaccuracy
		)
	else:
		# Fallback untuk tipe obstacle lama yang belum punya lock-on (tetap instan seperti dulu)
		var inaccuracy = current_difficulty.targeting_inaccuracy
		var candidate_y = player.global_position.y + randf_range(-inaccuracy, inaccuracy)
		instance.global_position.y = _finalize_target_y(candidate_y, min_track_y, max_track_y, travel_time)


func _spawn_permanent(obstacle_data: ObstacleData, player: Node2D) -> void:
	var target_slot: Node2D = LevelManager.get_available_slot_ahead(player.global_position.x)
	
	if target_slot != null:
		var instance = obstacle_data.obstacle_scene.instantiate()
		if "data" in instance:
			instance.data = obstacle_data
			
		# PENTING: Jadikan rintangan sebagai child dari slot di Level Chunk,
		# agar ia otomatis ikut bergerak ke kiri mengikuti kecepatan dunia!
		target_slot.add_child(instance)
		
		# Reset posisi relatif karena sekarang dia ada di dalam slot
		instance.position = Vector2.ZERO

# --- LOGIKA ZONA AMAN ---

func _resolve_safe_target_y(candidate_y: float, min_track_y: float, max_track_y: float):
	candidate_y = clamp(candidate_y, min_track_y, max_track_y)

	for zone in _active_zones:
		var zone_y: float = zone.y
		if abs(candidate_y - zone_y) < forbidden_zone_radius:
			var push_up: float = zone_y - forbidden_zone_radius
			var push_down: float = zone_y + forbidden_zone_radius
			candidate_y = push_up if abs(candidate_y - push_up) < abs(candidate_y - push_down) else push_down
			candidate_y = clamp(candidate_y, min_track_y, max_track_y)

	if not _has_safe_gap(candidate_y, min_track_y, max_track_y):
		return null
	return candidate_y

func _get_sorted_zone_bounds(min_track_y: float, max_track_y: float, extra_y = null) -> Array[float]:
	var zones_y: Array[float] = []
	for zone in _active_zones:
		zones_y.append(zone.y)
	if extra_y != null:
		zones_y.append(extra_y)
	zones_y.sort()

	var bounds: Array[float] = [min_track_y]
	for y in zones_y:
		bounds.append(y - forbidden_zone_radius)
		bounds.append(y + forbidden_zone_radius)
	bounds.append(max_track_y)
	return bounds

func _has_any_gap_at_least(bounds: Array[float], required_size: float) -> bool:
	var i := 0
	while i < bounds.size() - 1:
		if bounds[i + 1] - bounds[i] >= required_size:
			return true
		i += 2
	return false

func _largest_gap(bounds: Array[float]) -> Dictionary:
	var best_start: float = bounds[0]
	var best_end: float = bounds[1]
	var best_size: float = best_end - best_start
	var i := 2
	while i < bounds.size() - 1:
		var size: float = bounds[i + 1] - bounds[i]
		if size > best_size:
			best_size = size
			best_start = bounds[i]
			best_end = bounds[i + 1]
		i += 2
	return {"start": best_start, "end": best_end, "size": best_size}

# --- Tiga pemakai, masing-masing cuma 1-2 baris sekarang ---
func _has_safe_gap(new_y: float, min_track_y: float, max_track_y: float) -> bool:
	var bounds = _get_sorted_zone_bounds(min_track_y, max_track_y, new_y)
	return _has_any_gap_at_least(bounds, min_safe_gap)

func _track_has_room(min_track_y: float, max_track_y: float) -> bool:
	var bounds = _get_sorted_zone_bounds(min_track_y, max_track_y)
	return _has_any_gap_at_least(bounds, min_safe_gap)

func _find_largest_gap_center(min_track_y: float, max_track_y: float) -> float:
	var bounds = _get_sorted_zone_bounds(min_track_y, max_track_y)
	var gap = _largest_gap(bounds)
	return clamp((gap.start + gap.end) / 2.0, min_track_y, max_track_y)
	

func _finalize_target_y(candidate_y: float, min_track_y: float, max_track_y: float, extra_travel_time: float) -> float:
	var resolved = _resolve_safe_target_y(candidate_y, min_track_y, max_track_y)
	if resolved == null:
		resolved = _find_largest_gap_center(min_track_y, max_track_y)

	_active_zones.append({
		"y": resolved,
		"expire_time": (Time.get_ticks_msec() / 1000.0) + extra_travel_time
	})
	return resolved
