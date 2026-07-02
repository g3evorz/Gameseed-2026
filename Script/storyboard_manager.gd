extends CanvasLayer

@onready var gambar_storyboard = $GambarStoryboard
@onready var teks_dialog = $KotakDialog/TextDialog
@onready var timer_teks = $TimerTeks

# Struktur data cerita Anda
var halaman_cerita = [
	{
		"gambar": preload("res://Assets/Scene/Scene - 1.png"), # Ganti dengan path gambar asli Anda
		"teks": "The story begins you tries to make a quick profit, but the stock market crashes instead. All of your savings are completely wiped out, Your tablet screen only shows a plummeting chart along with a massive red number indicating their heavy financial loss."
	},
	{
		"gambar": preload("res://Assets/Scene/Scene - 2.png"),
		"teks": "Desperate and completely out of money, You visits a massive loan corporation. You stand in front of the giant building doors, hoping to find an instant solution to save your ruined financial situation.."
	},
	{
		"gambar": preload("res://Assets/Scene/Scene - 3.png"),
		"teks": "Inside the building, You meets with a company representative and agrees to a shady deal. You successfully secure a cash loan, but with a heavy condition: you must put up their beloved antique train as collateral if you fail to repay the debt."
	},
	{
		"gambar": preload("res://Assets/Scene/Scene - 4.png"),
		"teks": "Instead of using the money wisely, You gambles it all back on the Crypto market. Along with a few other people, you stare anxiously at a TV screen. Your hopes are completely crushed when the digital coin chart, which initially went up a little, suddenly plummets and loses all of its value."
	},
	{
		"gambar": preload("res://Assets/Scene/Scene - 5.png"),
		"teks": "Now, the debt collector is coming to repossess the train. Unwilling to lose your one and only prized asset, You sneaks into the station quietly. You fire up the train's engine and immediately blast off into space to escape the debt collector's pursuit."
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
	SceneTransition.pindah_scene("res://Scenes/Upgradable.tscn")
