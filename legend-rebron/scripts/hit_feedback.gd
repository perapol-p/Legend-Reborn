extends Control
const HIT_DURATION := 0.16
const CRIT_DURATION := 0.22
const KILL_DURATION := 0.28
var player: CharacterBody3D
var remaining := 0.0
var duration := HIT_DURATION
var priority := 0
var sound_cooldown := 0.0
var impact: AudioStreamPlayer
var sounds: Array[AudioStreamWAV] = []
var confirmations := 0
var sounds_played := 0
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 impact = AudioStreamPlayer.new()
 impact.bus = "Effects"
 impact.volume_db = -14.0
 add_child(impact)
 sounds.append(_make_impact(170.0))
 sounds.append(_make_impact(250.0))
 hide()
func bind_combat(body: CharacterBody3D, combat: Node) -> void:
 player = body
 combat.hit_confirmed.connect(confirm_hit)
func confirm_hit(critical: bool, killed: bool) -> void:
 if get_tree().paused or not is_instance_valid(player) or player.run.finished:
  return
 confirmations += 1
 var next_priority := 2 if killed else (1 if critical else 0)
 # A simultaneous normal hit must not erase a kill/critical marker.
 if remaining <= 0.0 or next_priority >= priority:
  priority = next_priority
  duration = KILL_DURATION if killed else (CRIT_DURATION if critical else HIT_DURATION)
  remaining = duration
 show()
 queue_redraw()
 # Several arrows or enemies hit in one instant produce one impact sound.
 if sound_cooldown <= 0.0:
  impact.stream = sounds[1 if critical else 0]
  impact.pitch_scale = 1.08 if killed else 1.0
  impact.play()
  sounds_played += 1
  sound_cooldown = 0.055
func _process(delta: float) -> void:
 if get_tree().paused or (is_instance_valid(player) and player.run.finished):
  remaining = 0.0
  sound_cooldown = 0.0
  impact.stop()
  hide()
  return
 sound_cooldown = maxf(0.0, sound_cooldown - delta)
 remaining = maxf(0.0, remaining - delta)
 if remaining <= 0.0:
  hide()
 else:
  queue_redraw()
func _draw() -> void:
 if remaining <= 0.0:
  return
 var tint := Color("ff665a") if priority == 2 else (Color("ffd36a") if priority == 1 else Color.WHITE)
 tint.a = minf(1.0, remaining / 0.07)
 var center := size * 0.5
 var outer := 13.0 if priority == 0 else 16.0
 for direction in [Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1), Vector2(1,1)]:
  var a: Vector2 = center + direction * 6.0
  var b: Vector2 = center + direction * outer
  draw_line(a,b,Color(0,0,0,tint.a * 0.75),4.5,true)
  draw_line(a,b,tint,2.2,true)
func _make_impact(frequency: float) -> AudioStreamWAV:
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 var bytes := PackedByteArray()
 var count := 1764
 bytes.resize(count * 2)
 var noise := RandomNumberGenerator.new()
 noise.seed = 5713
 for i in count:
  var t := float(i) / stream.mix_rate
  var envelope := exp(-t * 70.0) * minf(1.0, float(i) / 16.0)
  var thud := sin(TAU * frequency * t * (1.0 - t * 3.0))
  var sample := (thud * 0.6 + noise.randf_range(-1.0,1.0) * 0.4) * envelope
  bytes.encode_s16(i * 2, int(clampf(sample,-1.0,1.0) * 24000.0))
 stream.data = bytes
 return stream
func _exit_tree() -> void:
 if is_instance_valid(impact):
  impact.stop()
  impact.stream = null