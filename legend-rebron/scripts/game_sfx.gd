extends Node
const SOUNDS = {
 "sword": preload("res://assets/audio/sfx/sword_attack.ogg"),
 "bow": preload("res://assets/audio/sfx/bow_attack.ogg"),
 "dash": preload("res://assets/audio/sfx/dash.wav"),
 "footstep": preload("res://assets/audio/sfx/footstep.wav"),
 "magic_fireball": preload("res://assets/audio/sfx/wizard_fireball.mp3"),
 "magic_wind": preload("res://assets/audio/sfx/wizard_wind.mp3"),
 "magic_explosion": preload("res://assets/audio/sfx/wizard_explosion.mp3")
}
const GAINS = {"sword":-12.0,"bow":-14.0,"dash":-15.0,"footstep":-23.0,"magic_fireball":-17.0,"magic_wind":-24.0,"magic_explosion":-12.0}
var player: CharacterBody3D
var voices: Array[AudioStreamPlayer] = []
var magic_voices: Array[AudioStreamPlayer] = []
var wind_voice: AudioStreamPlayer
var explosion_voice: AudioStreamPlayer
var cursor := 0
var magic_cursor := 0
var step_timer := 0.0
var wind_timer := 0.0
var played: Dictionary = {}
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 for id in SOUNDS: played[id] = 0
 for i in 8: voices.append(_voice())
 for i in 2: magic_voices.append(_voice())
 explosion_voice = _voice()
 wind_voice = _voice()
 var wind = SOUNDS["magic_wind"].duplicate()
 wind.loop = true
 wind_voice.stream = wind
func _voice() -> AudioStreamPlayer:
 var voice := AudioStreamPlayer.new()
 voice.bus = "Effects"
 add_child(voice)
 return voice
func bind_game(body: CharacterBody3D, combat: Node) -> void:
 player = body
 player.dash_started.connect(func(): play_sound("dash"))
 combat.attack_started.connect(func(id: String):
  if id in ["sword","katana"]: play_sound("sword"))
 combat.bow_released.connect(func(): play_sound("bow"))
 combat.staff_fired.connect(func(): play_sound("magic_fireball"))
 combat.explosion_detonated.connect(func(): play_sound("magic_explosion"))
func play_sound(id: String) -> bool:
 if not SOUNDS.has(id) or get_tree().paused or (is_instance_valid(player) and player.run.finished): return false
 var voice: AudioStreamPlayer
 if id == "magic_fireball":
  voice = magic_voices[magic_cursor]
  magic_cursor = (magic_cursor+1)%magic_voices.size()
 elif id == "magic_explosion": voice = explosion_voice
 elif id == "magic_wind": voice = wind_voice
 else:
  for candidate in voices:
   if not candidate.playing:
    voice = candidate
    break
  if voice == null:
   voice = voices[cursor]
   cursor = (cursor+1)%voices.size()
 voice.stop()
 if id != "magic_wind": voice.stream = SOUNDS[id]
 voice.volume_db = GAINS[id]
 voice.pitch_scale = randf_range(0.94,1.06) if id=="footstep" else 1.0
 voice.play()
 played[id] += 1
 return true
func _stop_all() -> void:
 for voice in voices+magic_voices+[wind_voice,explosion_voice]:
  if is_instance_valid(voice): voice.stop()
func _physics_process(delta: float) -> void:
 if not is_instance_valid(player): return
 if get_tree().paused or player.run.finished:
  _stop_all()
  step_timer = 0.0
  wind_timer = 0.0
  return
 wind_timer -= delta
 if wind_timer <= 0.0:
  wind_timer = 0.1
  var active := false
  for tornado in get_tree().get_nodes_in_group("weapon_tornadoes"):
   if not tornado.is_queued_for_deletion() and tornado.remaining > 0.0:
    active = true
    break
  if active and not wind_voice.playing: play_sound("magic_wind")
  elif not active: wind_voice.stop()
 var speed := Vector2(player.velocity.x,player.velocity.z).length()
 if not player.input_enabled or not player.is_on_floor() or speed < 0.5 or player.dash_remaining > 0.0:
  step_timer = 0.0
  return
 step_timer -= delta
 if step_timer <= 0.0:
  play_sound("footstep")
  var normal_speed: float = player.move_speed*player.speed_multiplier()
  step_timer = 0.28 if speed > normal_speed*1.2 else 0.42
func _exit_tree() -> void:
 _stop_all()
 for voice in voices+magic_voices+[wind_voice,explosion_voice]:
  if is_instance_valid(voice): voice.stream = null
