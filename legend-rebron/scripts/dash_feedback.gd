extends Control
var player: CharacterBody3D
var wind := 0.0
var elapsed := 0.0
var ready_flash := 0.0
var ready_sound: AudioStreamPlayer
func _ready() -> void:
 process_mode = Node.PROCESS_MODE_ALWAYS
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ready_sound = AudioStreamPlayer.new()
 ready_sound.bus = "Effects"
 ready_sound.volume_db = -28.0
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 var bytes := PackedByteArray()
 bytes.resize(1102 * 2)
 for i in 1102:
  var t := float(i) / 22050.0
  var envelope := sin(PI * float(i) / 1102.0) * exp(-t * 40.0)
  bytes.encode_s16(i * 2, int(sin(TAU * 1100.0 * t) * envelope * 16000.0))
 stream.data = bytes
 ready_sound.stream = stream
 add_child(ready_sound)
func bind_player(body: CharacterBody3D) -> void:
 player = body
 player.dash_ready.connect(_on_ready)
func _on_ready() -> void:
 if player.input_enabled and not player.run.finished and not get_tree().paused:
  ready_flash = 0.22
  ready_sound.play()
func _process(delta: float) -> void:
 if not is_instance_valid(player):
  return
 if get_tree().paused or player.run.finished or not player.input_enabled:
  wind = 0.0
  ready_flash = 0.0
  ready_sound.stop()
  hide()
  return
 show()
 elapsed += delta
 wind = move_toward(wind, 1.0 if player.dash_remaining > 0.0 else 0.0, delta * (35.0 if player.dash_remaining > 0.0 else 10.0))
 ready_flash = maxf(0.0, ready_flash - delta)
 queue_redraw()
func _draw() -> void:
 if not is_instance_valid(player):
  return
 # Sparse lines stay in the side margins; the center and horizon stay clear.
 if wind > 0.0:
  for side in [-1.0,1.0]:
   for i in 6:
    var phase := fposmod(elapsed * 3.5 + float(i) * 0.173, 1.0)
    var height := size.y * (0.13 + float(i) * 0.145)
    var x := lerpf(size.x * 0.17, -size.x * 0.025, phase)
    var point := Vector2(x if side < 0.0 else size.x - x, height)
    var length := lerpf(18.0,65.0,phase)
    var inward := Vector2(-side * length, (size.y * 0.5 - height) * 0.06)
    var alpha := wind * sin(PI * phase) * 0.22
    draw_line(point, point + inward, Color(0.8,0.92,1.0,alpha),1.5,true)
 var center := size * 0.5 + Vector2(0,42)
 var ready: bool = player.dash_recovery <= 0.0
 var progress := clampf(1.0 - player.dash_recovery / maxf(player.dash_cooldown,0.001),0.0,1.0)
 draw_arc(center,8.0,-PI * 0.5,PI * 1.5,32,Color(0,0,0,0.45),3.5,true)
 draw_arc(center,8.0,-PI * 0.5,PI * 1.5,32,Color(0.7,0.78,0.8,0.16),1.5,true)
 if progress > 0.01:
  draw_arc(center,8.0,-PI * 0.5,-PI * 0.5 + TAU * progress,32,Color(0.65,0.92,1.0,0.38 if ready else 0.8),1.5,true)
 if ready_flash > 0.0:
  var ratio := ready_flash / 0.22
  draw_arc(center,lerpf(16.0,8.0,ratio),0,TAU,32,Color(0.75,0.95,1.0,ratio * 0.65),1.5,true)
func _exit_tree() -> void:
 if is_instance_valid(ready_sound):
  ready_sound.stop()
  ready_sound.stream = null