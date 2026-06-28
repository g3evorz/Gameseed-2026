extends Node
class_name EnemyWeaponSpawner

@export var rocket_scene: PackedScene
@export_range(0.0, 1.0) var spawn_chance: float = 0.6
@export var cooldown_duration: float = 1.5
@export var targeting_inaccuracy: float = 30.0
@export var spawn_margin: float = 150.0

@export_group("Zona Terlarang")
@export var min_track_y: float = 100.0
@export var max_track_y: float = 600.0
@export var base_forbidden_radius: float = 110.0
@export var hard_forbidden_radius: float = 70.0
@export var base_safe_gap: float = 180.0
@export var hard_safe_gap: float = 120.0
@export var player_hitbox_height: float = 60.0

var _is_on_cooldown: bool = false
var _active_zones: Array[Dictionary] = []
var forbidden_zone_radius: float
var min_safe_gap: float

func _ready() -> void:
	_connect_existing_enemies()
	get_tree().node_added.connect(_on_node_added)

func _physics_process(_delta: float) -> void:
	var ratio: float = GameManager.get_speed_ratio()
	forbidden_zone_radius = lerp(base_forbidden_radius, hard_forbidden_radius, ratio)
	min_safe_gap = max(lerp(base_safe_gap, hard_safe_gap, ratio), player_hitbox_height + 20.0)

	var now: float = Time.get_ticks_msec() / 1000.0
	_active_zones = _active_zones.filter(func(z): return z.expire_time > now)

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
	if _is_on_cooldown or randf() > spawn_chance or rocket_scene == null:
		return

	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		push_warning("RocketSpawner: tidak ada Camera2D aktif di viewport!")
		return

	var player: Node2D = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		return

	var candidate_y: float = player.global_position.y + randf_range(-targeting_inaccuracy, targeting_inaccuracy)
	var final_y_variant = _resolve_safe_target_y(candidate_y)
	if final_y_variant == null:
		return
	var final_y: float = final_y_variant

	_is_on_cooldown = true
	get_tree().create_timer(cooldown_duration).timeout.connect(_reset_cooldown)

	var rocket_instance = rocket_scene.instantiate()
	get_tree().current_scene.add_child(rocket_instance)
	rocket_instance.global_position = Vector2(cam.get_right_edge_x(spawn_margin), final_y)

	var travel_time: float = rocket_instance.warning_duration + 3.0
	_active_zones.append({"y": final_y, "expire_time": (Time.get_ticks_msec() / 1000.0) + travel_time})

func _resolve_safe_target_y(candidate_y: float):
	candidate_y = clamp(candidate_y, min_track_y, max_track_y)

	for zone in _active_zones:
		var zone_y: float = zone.y
		if abs(candidate_y - zone_y) < forbidden_zone_radius:
			var push_up: float = zone_y - forbidden_zone_radius
			var push_down: float = zone_y + forbidden_zone_radius
			candidate_y = push_up if abs(candidate_y - push_up) < abs(candidate_y - push_down) else push_down
			candidate_y = clamp(candidate_y, min_track_y, max_track_y)

	if not _has_safe_gap(candidate_y):
		return null
	return candidate_y

func _has_safe_gap(new_y: float) -> bool:
	var zones_y: Array[float] = []
	for zone in _active_zones:
		zones_y.append(zone.y)
	zones_y.append(new_y)
	zones_y.sort()

	if zones_y[0] - forbidden_zone_radius - min_track_y >= min_safe_gap:
		return true

	for i in range(zones_y.size() - 1):
		var gap: float = (zones_y[i + 1] - forbidden_zone_radius) - (zones_y[i] + forbidden_zone_radius)
		if gap >= min_safe_gap:
			return true

	if max_track_y - (zones_y[-1] + forbidden_zone_radius) >= min_safe_gap:
		return true

	return false

func _reset_cooldown() -> void:
	_is_on_cooldown = false
