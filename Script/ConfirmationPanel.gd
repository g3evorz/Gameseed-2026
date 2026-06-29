extends Control

# Membuat sinyal kustom untuk didengarkan oleh skrip lain
signal konfirmasi_ya
signal konfirmasi_tidak

@onready var label_pesan = $Panel/Label

func _ready():
	# Pastikan panel tersembunyi saat game baru dimulai
	visible = false

# Fungsi ini yang akan dipanggil untuk memunculkan panel
func tampilkan(pesan: String = "Apakah Anda yakin?"):
	label_pesan.text = pesan
	visible = true

# Fungsi internal saat tombol Ya ditekan
func _on_btn_ya_pressed():
	visible = false
	konfirmasi_ya.emit() # Pancarkan sinyal Ya

# Fungsi internal saat tombol Tidak ditekan
func _on_btn_tidak_pressed():
	visible = false
	konfirmasi_tidak.emit() # Pancarkan sinyal Tidak
