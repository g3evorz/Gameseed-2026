extends Area2D

@export var data: ObstacleData
@export var damage_tabrakan: int = 200
@export var kekuatan_slow: float = 0.7 

var current_hp: int

func _ready():
	current_hp = data.max_hp
	
func take_damage(damage_amount: int):
	current_hp -= damage_amount
	
	#print("CURRENT HP : ", current_hp)
	
	if current_hp <= 0:
		die()

func _on_body_entered(body):
	
	if body.is_in_group("Player"):
		if body.has_method("terima_damage"):
			body.terima_damage(damage_tabrakan)
		elif body.get_parent() and body.get_parent().has_method("terima_damage"):
			body.get_parent().terima_damage(damage_tabrakan)
			
		GameManager.terapkan_efek_ram(kekuatan_slow)
			
		# 3. Hancurkan obstacle
		die()

# DESTROY OBJECT

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	print("Platform Terhapus !")
	queue_free()	

func die():
	queue_free()
