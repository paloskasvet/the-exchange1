extends Node

var _player:   AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
const SR := 44100.0

var _t   := 0.0
var _bt  := 0.0
var _bar := 0
var _btn := 0
var _vol := 0.42

var _pb  := 0.0
var _pp1 := 0.0; var _pp2 := 0.0; var _pp3 := 0.0
var _pm1 := 0.0; var _pm2 := 0.0
var _pa1 := 0.0
var _mel_t := 0.0; var _mel_i := 0; var _mel_env := 0.0
var _kick_t := 100.0; var _kick_amp := 0.0
var _bd_t   := 100.0

const BPM  := 118.0
const BEAT := 60.0 / BPM

const CHORDS := [[110.0,146.8,164.8],[98.0,130.8,155.6],[123.5,164.8,185.0],[82.4,110.0,130.8]]
const BASS   := [55.0, 49.0, 61.7, 41.2]
const MEL    := [220.0,246.9,261.6,293.7,329.6,349.2,392.0,440.0,523.3,587.3]
const MSEQ   := [0,2,4,3,5,2,4,6,5,3,2,4,3,1,2,0,7,5,4,6,5,3,4,2]
const MDUR   := [0.5,0.5,0.5,0.5,1.0,0.5,0.5,0.5,0.5,0.5,0.5,1.0,0.5,0.5,1.0,1.0,0.5,0.5,0.5,0.5,0.5,0.5,0.5,1.0]

func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SR; gen.buffer_length = 0.15
	_player = AudioStreamPlayer.new(); _player.stream = gen
	_player.volume_db = linear_to_db(_vol); add_child(_player)
	_player.play(); _playback = _player.get_stream_playback()
	set_process(true)

func _process(_d: float) -> void:
	if not _playback: return
	var n := _playback.get_frames_available()
	if n < 32: return
	n = mini(n, 2048)
	var buf := PackedVector2Array(); buf.resize(n)
	var dt  := 1.0 / SR

	for i in n:
		_t += dt; _bt += dt; _mel_t += dt; _kick_t += dt; _bd_t += dt
		if _bt >= BEAT:
			_bt -= BEAT; _btn += 1
			var b := _btn % 4
			if b == 0 or b == 2: _kick_t = 0.0; _kick_amp = 0.38
			if b == 1 or b == 3: _bd_t = 0.0
			if _btn % 4 == 0:    _bar = (_bar + 1) % CHORDS.size()
		var mel_dur = MDUR[_mel_i % MDUR.size()] * BEAT
		if _mel_t >= mel_dur:
			_mel_t -= mel_dur; _mel_i = (_mel_i + 1) % MSEQ.size(); _mel_env = 1.0
		_kick_amp = maxf(0.0, _kick_amp - dt * 20.0)

		var chord = CHORDS[_bar]
		var bf    = BASS[_bar]

		_pb  += bf * dt * TAU
		var bass := sin(_pb) * 0.22 + sin(_pb * 0.5) * 0.08

		_pp1 += chord[0] * dt * TAU * 1.0015
		_pp2 += chord[1] * dt * TAU * 0.9992
		_pp3 += chord[2] * dt * TAU * 1.0008
		var pad := (sin(_pp1)*0.5+sin(_pp2)*0.4+sin(_pp3)*0.3) * 0.07 * (0.75+0.25*sin(_t*0.18))

		var mf = MEL[MSEQ[_mel_i % MSEQ.size()] % MEL.size()]
		_pm1 += mf * dt * TAU; _pm2 += mf * 2.0 * dt * TAU
		_mel_env = maxf(0.0, _mel_env - dt * 3.5)
		var tri  := asin(clampf(sin(_pm1), -1.0, 1.0)) * (2.0 / PI)
		var mel  := tri * _mel_env * 0.18

		var arp_note = chord[_btn % chord.size()]
		_pa1 += arp_note * dt * TAU
		var arp := sin(_pa1) * 0.055

		var kick_f := (90.0 * exp(-_kick_t * 30.0) + 40.0)
		var kick   := sin(_kick_t * kick_f * TAU) * _kick_amp * 0.28

		var body   := sin(_bd_t * 220.0 * TAU) * exp(-_bd_t * 15.0) * 0.10

		var s := clampf((bass + pad + mel + arp + kick + body) * 1.1, -1.0, 1.0)
		buf[i] = Vector2(s, s)

	_playback.push_buffer(buf)

func set_volume(v: float) -> void:
	_vol = clampf(v, 0.0, 1.0)
	if _player: _player.volume_db = linear_to_db(_vol) if _vol > 0.001 else -80.0

func play_cash() -> void:
	var sr := 22050
	var dur := 0.55
	var n := int(sr * dur)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sr; wav.stereo = false
	var data := PackedByteArray(); data.resize(n * 2)
	for i in n:
		var t := float(i) / float(sr)
		# "cha" — mechanical clunk: low filtered noise burst
		var clunk := sin(t * 180.0 * TAU) * exp(-t * 40.0) * 0.5
		# "ching" — two bell tones at 1047 Hz and 1319 Hz (C6, E6)
		var bell1 := sin(t * 1047.0 * TAU) * exp(-t * 7.0) * 0.45
		var bell2 := sin(t * 1319.0 * TAU) * exp(-t * 9.0) * 0.30
		# bell delayed 55 ms
		var td := maxf(t - 0.055, 0.0)
		var bell3 := sin(td * 1568.0 * TAU) * exp(-td * 11.0) * 0.20
		var s := clampf(clunk + bell1 + bell2 + bell3, -1.0, 1.0)
		var sample := int(s * 32767)
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	wav.data = data
	var p := AudioStreamPlayer.new(); p.stream = wav
	p.volume_db = linear_to_db(0.55); add_child(p); p.play()
	p.finished.connect(p.queue_free)

func play_purchase() -> void:
	var sr  := 22050
	var dur := 0.80
	var n   := int(sr * dur)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sr; wav.stereo = false
	var data := PackedByteArray(); data.resize(n * 2)
	for i in n:
		var t   := float(i) / float(sr)
		# "ka" — mechanical drawer thunk
		var thump := sin(t * 75.0 * TAU) * exp(-t * 55.0) * 0.55
		var click := (randf() * 2.0 - 1.0) * exp(-t * 140.0) * 0.32
		# "ching" — sharp metallic bell (delayed 0.018s)
		var tc := maxf(t - 0.018, 0.0)
		var b1 := sin(tc * 1319.0 * TAU) * exp(-tc * 4.2) * 0.52
		var b2 := sin(tc * 1760.0 * TAU) * exp(-tc * 5.8) * 0.36
		var b3 := sin(tc * 2093.0 * TAU) * exp(-tc * 8.0) * 0.22
		var b4 := sin(tc * 2637.0 * TAU) * exp(-tc * 11.0) * 0.12
		var s   := clampf(thump + click + b1 + b2 + b3 + b4, -1.0, 1.0)
		var sample := int(s * 32767)
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	wav.data = data
	var p := AudioStreamPlayer.new(); p.stream = wav
	p.volume_db = linear_to_db(0.72); add_child(p); p.play()
	p.finished.connect(p.queue_free)

func play_ring() -> void:
	var sr  := 22050
	var dur := 1.15
	var n   := int(sr * dur)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sr; wav.stereo = false
	var data := PackedByteArray(); data.resize(n * 2)
	for i in n:
		var t  := float(i) / float(sr)
		var s  := 0.0
		# Two ring bursts: 0–0.42 s and 0.62–1.04 s
		var bt := -1.0
		if   t < 0.42:                    bt = t
		elif t >= 0.62 and t < 1.04:      bt = t - 0.62
		if bt >= 0.0:
			var env := 1.0
			if   bt < 0.02:  env = bt / 0.02
			elif bt > 0.36:  env = maxf(0.0, (0.42 - bt) / 0.06)
			# Dual-tone bell: 400 Hz + 450 Hz + 2nd harmonics for mechanical timbre
			var mod  := 0.85 + 0.15 * sin(t * 8.0 * TAU)
			var tone := sin(t * 400.0 * TAU) \
					  + sin(t * 450.0 * TAU) \
					  + sin(t * 800.0 * TAU) * 0.25 \
					  + sin(t * 900.0 * TAU) * 0.25
			s = clampf(tone * 0.28 * env * mod, -1.0, 1.0)
		var sample := int(s * 32767)
		data[i * 2]     = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	wav.data = data
	var p := AudioStreamPlayer.new(); p.stream = wav
	p.volume_db = linear_to_db(0.65); add_child(p); p.play()
	p.finished.connect(p.queue_free)
