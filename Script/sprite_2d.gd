extends Sprite2D

func _ready():
	stretch_to_border()

# Jika kamu ingin sprite menyesuaikan ukuran saat layar di-resize, 
# kamu bisa memanggil fungsi ini di dalam _process, atau menggunakan signal "size_changed" dari viewport.
# func _process(delta):
# 	stretch_to_border()

func stretch_to_border():
	# 1. Dapatkan ukuran batas dunia (Viewport / Layar)
	var border_size = get_viewport_rect().size
	
	# 2. Pastikan Sprite memiliki texture sebelum melakukan perhitungan
	if texture:
		# Dapatkan ukuran asli dari gambar (texture)
		var texture_size = texture.get_size()
		
		# 3. Hitung skala yang dibutuhkan agar pas dengan border
		var scale_x = border_size.x / texture_size.x
		var scale_y = border_size.y / texture_size.y
		
		# 4. Terapkan skala baru ke Sprite
		scale = Vector2(scale_x, scale_y)
		
		# 5. (Opsional) Posisikan Sprite tepat di tengah layar
		global_position = border_size / 2.0
