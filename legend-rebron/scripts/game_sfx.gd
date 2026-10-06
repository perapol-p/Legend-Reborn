extends Node
const SOUNDS = {
	"sword": preload("res://assets/audio/sfx/sword_attack.ogg"),
	"bow": preload("res://assets/audio/sfx/bow_attack.ogg"),
	"dash": preload("res://assets/audio/sfx/dash.wav"),
	"footstep": preload("res://assets/audio/sfx/footstep.wav")
}
const GAINS := {"sword":-12.0,"bow":-14.0,"dash":-15.0,"footstep":-23.0}
var player: CharacterBody3D
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
var step_timer := 0.0
var played: Dictionary = {"sword":0,"bow":0,"dash":0,"footstep":0}
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var voice := AudioStreamPlayer.new()
		voice.bus = "Effects"
		add_child(voice)
		voices.append(voice)
func bind_game(body: CharacterBody3D, combat: Node) -> void:
	player = body
	player.dash_started.connect(func(): play_sound("dash"))
	combat.attack_started.connect(func(id: String):
		if id in ["sword","katana"]:
			play_sound("sword")
	)
	combat.bow_released.connect(func(): play_sound("bow"))
func play_sound(id: String) -> bool:
	if not SOUNDS.has(id) or get_tree().paused or (is_instance_valid(player) and player.run.finished):
		return false
	var voice: AudioStreamPlayer
	for candidate in voices:
		if not candidate.playing:
			voice = candidate
			break
	if voice == null:
		voice = voices[cursor]
		cursor = (cursor + 1) % voices.size()
	voice.stop()
	voice.stream = SOUNDS[id]
	voice.volume_db = GAINS[id]
	voice.pitch_scale = randf_range(0.94,1.06) if id == "footstep" else randf_range(0.98,1.02)
	voice.play()
	played[id] += 1
	return true
func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	if get_tree().paused or player.run.finished:
		for voice in voices:
			voice.stop()
		step_timer = 0.0
		return
	var speed := Vector2(player.velocity.x,player.velocity.z).length()
	if not player.input_enabled or not player.is_on_floor() or speed < 0.5 or player.dash_remaining > 0.0:
		step_timer = 0.0
		return
	step_timer -= delta
	if step_timer <= 0.0:
		play_sound("footstep")
		var normal_speed: float = player.move_speed * player.speed_multiplier()
		step_timer = 0.28 if speed > normal_speed * 1.2 else 0.42

func _exit_tree() -> void:
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
