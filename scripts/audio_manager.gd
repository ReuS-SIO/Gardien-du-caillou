extends Node
## Autoload "Audio" : effets sonores et musiques.
## Pour remplacer un son, dépose ton fichier (wav / ogg / mp3) et change le chemin ci-dessous,
## ou garde le même nom de fichier dans assets/audio/ et relance l'import.

const SFX := {
	"jump": "res://assets/audio/sfx/jump.wav",
	"double_jump": "res://assets/audio/sfx/double_jump.wav",
	"attack": "res://assets/audio/sfx/attack.wav",
	"throw": "res://assets/audio/sfx/throw.wav",
	"hit_enemy": "res://assets/audio/sfx/hit_enemy.wav",
	"enemy_die": "res://assets/audio/sfx/enemy_die.wav",
	"player_hurt": "res://assets/audio/sfx/player_hurt.wav",
	"player_die": "res://assets/audio/sfx/player_die.wav",
	"heal": "res://assets/audio/sfx/heal.wav",
	"respawn": "res://assets/audio/sfx/respawn.wav",
	"wave_start": "res://assets/audio/sfx/wave_start.wav",
	"wave_clear": "res://assets/audio/sfx/wave_clear.wav",
	"boss_appear": "res://assets/audio/sfx/boss_appear.wav",
	"boss_enraged": "res://assets/audio/sfx/boss_enraged.wav",
	"boss_die": "res://assets/audio/sfx/boss_die.wav",
	"spit": "res://assets/audio/sfx/spit.wav",
	"splash": "res://assets/audio/sfx/splash.wav",
	"javelin_stick": "res://assets/audio/sfx/javelin_stick.wav",
	"upgrade": "res://assets/audio/sfx/upgrade.wav",
	"victory": "res://assets/audio/sfx/victory.wav",
	"ui_click": "res://assets/audio/sfx/ui_click.wav",
	"ui_hover": "res://assets/audio/sfx/ui_hover.wav",
	"charge_windup": "res://assets/audio/sfx/charge_windup.wav",
	"slam": "res://assets/audio/sfx/slam.wav",
}

const MUSIC := {
	"menu": "res://assets/audio/music/menu.wav",
	"zone_0": "res://assets/audio/music/zone_0.wav",
	"zone_1": "res://assets/audio/music/zone_1.wav",
	"zone_2": "res://assets/audio/music/zone_2.wav",
	"zone_3": "res://assets/audio/music/zone_3.wav",
	"zone_4": "res://assets/audio/music/zone_4.wav",
	"boss": "res://assets/audio/music/boss.wav",
}

const POOL_SIZE := 12

## Volumes en décibels (0 = plein volume, -80 = silence).
var sfx_volume_db := -4.0
var music_volume_db := -14.0
var sfx_enabled := true
var music_enabled := true

var _pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _music_player: AudioStreamPlayer
var _current_music := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)


func _exit_tree() -> void:
	stop_all()


## Coupe tout (effets et musique) et libère les flux en cache, par ex. avant de quitter.
func stop_all() -> void:
	for p in _pool:
		p.stop()
		p.stream = null
	_music_player.stop()
	_music_player.stream = null
	_current_music = ""
	_streams.clear()


## Joue un effet ; pitch_variation ajoute une légère variation aléatoire pour éviter la répétition.
func play(sfx_name: String, pitch_variation: float = 0.06, volume_offset_db: float = 0.0) -> void:
	if not sfx_enabled:
		return
	var stream := _get_stream(SFX, sfx_name)
	if stream == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = sfx_volume_db + volume_offset_db
			p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
			p.play()
			return
	# tous les lecteurs sont occupés : on réutilise le premier
	_pool[0].stream = stream
	_pool[0].volume_db = sfx_volume_db + volume_offset_db
	_pool[0].play()


func play_music(music_name: String) -> void:
	if music_name == _current_music and _music_player.playing:
		return
	_current_music = music_name
	if not music_enabled:
		return
	var stream := _get_stream(MUSIC, music_name)
	if stream == null:
		return
	_make_looping(stream)
	_music_player.stream = stream
	_music_player.volume_db = music_volume_db
	_music_player.play()


func stop_music() -> void:
	_current_music = ""
	_music_player.stop()


func set_music_volume(db: float) -> void:
	music_volume_db = db
	_music_player.volume_db = db


func _get_stream(table: Dictionary, key: String) -> AudioStream:
	if not table.has(key):
		push_warning("Son inconnu : %s" % key)
		return null
	if not _streams.has(key + "|" + str(table == MUSIC)):
		var path: String = table[key]
		if not ResourceLoader.exists(path):
			push_warning("Fichier audio absent : %s" % path)
			return null
		_streams[key + "|" + str(table == MUSIC)] = load(path)
	return _streams[key + "|" + str(table == MUSIC)]


## Active la boucle quel que soit le format (les WAV importés ne bouclent pas par défaut).
func _make_looping(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			var bytes_per_sample := 2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1
			var channels := 2 if wav.stereo else 1
			wav.loop_end = wav.data.size() / (bytes_per_sample * channels)
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true


## Branche un clic sur tous les boutons d'une arborescence (menus, panneaux).
func hook_buttons(root: Node) -> void:
	for node in root.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if not button.pressed.is_connected(_on_button_pressed):
			button.pressed.connect(_on_button_pressed)
		if not button.mouse_entered.is_connected(_on_button_hover):
			button.mouse_entered.connect(_on_button_hover)
			button.focus_entered.connect(_on_button_hover)


func _on_button_pressed() -> void:
	play("ui_click", 0.0)


func _on_button_hover() -> void:
	play("ui_hover", 0.0, -6.0)
