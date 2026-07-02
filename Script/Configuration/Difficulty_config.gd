class_name DifficultyConfig
extends Resource

@export_group("Activation Threshold")
## Nilai dari 0.0 sampai 1.0. Menentukan di rasio kecepatan berapa config ini aktif.
@export_range(0.0, 1.0) var activation_speed_ratio: float = 0.0

@export_group("Object Spawn Rates")
## Peluang musuh memutuskan untuk menjatuhkan rintangan saat sinyal obstacle_dropped diterima (0.0 - 1.0).
@export_range(0.0, 1.0) var spawn_chance: float = 0.5

@export_group("Level Spawn Interval")

@export var spawn_interval: float = 10.0

@export_group("Difficulty Obstacle Multiplier")

@export var health_multiplier: float = 7.5
@export var damage_multiplier: float = 5.0
@export var default_spawn_weight_multiplier: float = 1.0

@export_group("Targeted Weight Multipliers")
@export var specific_weight_multipliers: Dictionary = {}

@export_group("Targeting & Complexity")
## Tingkat ketidakakuratan musuh saat membidik posisi Y pemain (untuk rintangan TEMPORARY).
## Semakin kecil angkanya, tebakan musuh akan semakin presisi menjepit pemain.
@export var targeting_inaccuracy: float = 45.0

## Menentukan apakah di tingkat kesulitan ini musuh diizinkan menjatuhkan rintangan PERMANENT.
@export var allow_permanent_obstacles: bool = false

@export_group("Enemy State Duration")
@export var overtake_duration: float = 7.5
@export var cooldown_duration: float = 5.0
@export var lurk_time_min: float = 10.0
@export var lurk_time_max: float = 15.0
@export var drop_hold_time: float = 3.0
@export var drop_interval: float = 3.0
