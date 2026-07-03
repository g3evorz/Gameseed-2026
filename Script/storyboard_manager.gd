extends CanvasLayer

@onready var gambar_storyboard = $GambarStoryboard
@onready var teks_dialog = $KotakDialog/TextDialog
@onready var timer_teks = $TimerTeks

# Struktur data cerita Anda
var halaman_cerita = [
	{
		"gambar": preload("res://Assets/Scene/Scene - 1.png"), 
		"teks": "You tried to make a quick profit. Instead, the market crashed. One plummeting chart on a tablet, and all your savings were completely wiped out."
	},
	{
		"gambar": preload("res://Assets/Scene/Scene - 2.png"),
		"teks": "Desperate and broke, you stood before the giant doors of a massive loan corporation. You needed a miracle to save your ruined finances."
	},
	{
		"gambar": preload("res://Assets/Scene/Scene - 3.png"),
		"teks": "A shady deal was made. You got the cash, but it came with a heavy price. If you failed to pay them back, they would take your beloved antique train."
	},
	{
		"gambar": preload("res://Assets/Scene/Scene - 4.png"),
		"teks": "But you didn't use the money wisely. You gambled it all on crypto. You watched the monitor in horror as the coin briefly spiked... before crashing to zero."
	},
	{
		"gambar": preload("res://Assets/Scene/Scene - 5.png"),
		"teks": "Now, the Debt Collector is coming. Unwilling to lose your only prized asset, you sneak into the station. It's time to fire up the engines and blast off into space!"
	}
]

var indeks_halaman_sekarang: int = 0
var sedang_mengetik: bool = false

func _ready():
	# Memastikan text label mereset jumlah karakter yang terlihat
	AudioManager.putar_musik(AudioManager.musik_prolog)
	teks_dialog.visible_characters = 0
	
	# Sambungkan sinyal timer lewat kode
	timer_teks.timeout.connect(_on_timer_teks_timeout)
	
	# Mulai cerita dari halaman pertama
	buka_halaman(0)

func buka_halaman(indeks: int):
	indeks_halaman_sekarang = indeks
	var data_sekarang = halaman_cerita[indeks]
	
	# Pasang gambar dan teks
	gambar_storyboard.texture = data_sekarang["gambar"]
	teks_dialog.text = data_sekarang["teks"]
	
	# Mulai efek typewriter
	teks_dialog.visible_characters = 0
	sedang_mengetik = true
	timer_teks.start()

# Fungsi ini dipanggil setiap kali timer berdetak (misal: setiap 0.05 detik)
func _on_timer_teks_timeout():
	if teks_dialog.visible_characters < teks_dialog.get_total_character_count():
		teks_dialog.visible_characters += 1
		
		# (Opsional) Putar SFX "tut tut tut" ala Undertale di sini
		# AudioManager.putar_sfx(AudioManager.sfx_bicara) 
	else:
		# Teks sudah selesai diketik semua
		sedang_mengetik = false
		timer_teks.stop()

# Menangani input pemain untuk lanjut atau skip
func _input(event):
	# Gunakan klik kiri mouse atau tombol konfirmasi (misal: Spasi/Enter)
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		
		if sedang_mengetik:
			# Jika pemain tidak sabar, selesaikan ketikan secara instan
			teks_dialog.visible_characters = teks_dialog.get_total_character_count()
			sedang_mengetik = false
			timer_teks.stop()
		else:
			# Jika teks sudah selesai, lanjut ke halaman berikutnya
			indeks_halaman_sekarang += 1
			
			if indeks_halaman_sekarang < halaman_cerita.size():
				buka_halaman(indeks_halaman_sekarang)
			else:
				akhiri_storyboard()

func akhiri_storyboard():
	# Masukkan kode transisi ke Main Menu atau Gameplay di sini
	ScoreManager.sudah_lihat_intro = true
	ScoreManager.save_game_data() # Wajib disimpan ke hard drive!
	
	# Pindah ke gameplay utama
	SceneTransition.pindah_scene("res://Scenes/main.tscn")
