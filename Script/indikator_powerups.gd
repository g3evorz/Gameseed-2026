extends TextureRect

@onready var timer_durasi = $TimerDurasi

# Waktu (dalam detik) kapan ikon mulai berkedip sebelum habis
@export var waktu_mulai_kedip: float = 3.0 

func _ready():
	hide()
	timer_durasi.timeout.connect(_on_timer_durasi_timeout)
	
	# [BARU] Hubungkan signal dari GameManager langsung ke fungsi aktifkan_ikon di skrip ini
	GameManager.power_up_diaktifkan.connect(aktifkan_ikon)

func _process(delta):
	# Hanya jalankan efek jika timer sedang berjalan
	if not timer_durasi.is_stopped():
		var sisa_waktu = timer_durasi.time_left
		
		# Jika waktu tersisa kurang dari batas kedip (misal 3 detik terakhir)
		if sisa_waktu <= waktu_mulai_kedip:
			# --- LOGIKA KEDIP ARKADE ---
			# Menggunakan sisa_waktu untuk menentukan apakah ikon harus tampil atau sembunyi.
			# Semakin kecil angkanya (misal * 10 atau * 15), kedipannya makin cepat.
			var kecepatan_kedip = 10 
			if int(sisa_waktu * kecepatan_kedip) % 2 == 0:
				modulate.a = 1.0 # Muncul pekat
			else:
				modulate.a = 0.0 # Transparan / Hilang
		else:
			# Jika waktu masih banyak, ikon tampil solid 100%
			modulate.a = 1.0

# Fungsi untuk dipanggil saat pemain mengambil Power Up
func aktifkan_ikon(durasi: float, tekstur_ikon: Texture2D):
	texture = tekstur_ikon
	timer_durasi.wait_time = durasi
	timer_durasi.start()
	
	modulate.a = 1.0
	show()

func _on_timer_durasi_timeout():
	# Sembunyikan ikon saat durasi habis
	hide()
