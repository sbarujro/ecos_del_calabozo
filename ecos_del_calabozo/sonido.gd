extends Node
## Autoload "Sonido": efectos y musica del juego.

const EFECTOS = ["espada", "golpe", "dano", "recoger", "nivel", "puerta", "palanca", "rugido", "muerte", "derrota", "victoria"]

var _streams = {}
var _musica = null
var _musica_actual = ""


func _ready():
    for n in EFECTOS:
        _streams[n] = load("res://audio/%s.wav" % n)
    _streams["musica_sala"] = load("res://audio/musica_sala.wav")
    _streams["musica_jefe"] = load("res://audio/musica_jefe.wav")
    _musica = AudioStreamPlayer.new()
    _musica.volume_db = -9.0
    add_child(_musica)
    # La musica se repite al terminar
    _musica.finished.connect(_musica.play)


func reproducir(nombre):
    var s = _streams.get(nombre)
    if s == null:
        return
    var p = AudioStreamPlayer.new()
    p.stream = s
    p.volume_db = -3.0
    add_child(p)
    p.play()
    p.finished.connect(p.queue_free)


func musica(nombre):
    if nombre == _musica_actual:
        return
    _musica_actual = nombre
    var s = _streams.get("musica_" + nombre)
    if s == null:
        return
    _musica.stream = s
    _musica.play()
