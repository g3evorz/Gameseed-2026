class_name DifficultyConfig
extends Resource

@export_group("Spawn Rates")
## Peluang musuh memutuskan untuk menjatuhkan rintangan saat sinyal obstacle_dropped diterima (0.0 - 1.0).
@export_range(0.0, 1.0) var spawn_chance: float = 0.5

@export_group("Targeting & Complexity")
## Tingkat ketidakakuratan musuh saat membidik posisi Y pemain (untuk rintangan TEMPORARY).
## Semakin kecil angkanya, tebakan musuh akan semakin presisi menjepit pemain.
@export var targeting_inaccuracy: float = 45.0

## Menentukan apakah di tingkat kesulitan ini musuh diizinkan menjatuhkan rintangan PERMANENT.
@export var allow_permanent_obstacles: bool = false
