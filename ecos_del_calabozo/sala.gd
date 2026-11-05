class_name Sala
extends Node2D
## Una sala del calabozo: mapa de tiles, paredes, puerta, enemigos y objetos.

signal jefe_derrotado(posicion)

const ESCENA_GOBLIN = preload("res://goblin.tscn")
const ESCENA_ORCO = preload("res://orco.tscn")
const ESCENA_OBJETO = preload("res://objeto.tscn")
const ESCENA_COFRE = preload("res://cofre.tscn")
const ESCENA_PALANCA = preload("res://palanca.tscn")
const ESCENA_PUERTA = preload("res://puerta.tscn")

var numero = 1
var jugador = null
var puerta = null

@onready var _mapa = $Mapa
@onready var _paredes = $Paredes
@onready var _puertas = $Puertas
@onready var _objetos = $Objetos
@onready var _enemigos = $Enemigos


func _ready():
    _construir_mapa()
    _construir_paredes()
    _crear_puerta()
    _poblar()
    if numero == 3:
        Sonido.musica("jefe")
        Sonido.reproducir("rugido")
    else:
        Sonido.musica("sala")
    # Los enemigos esperan quietos (INACTIVOS) un instante y se activan al entrar el jugador
    var temporizador = Timer.new()
    temporizador.wait_time = 0.8
    temporizador.one_shot = true
    temporizador.timeout.connect(_activar_enemigos)
    add_child(temporizador)
    temporizador.start()


func _activar_enemigos():
    for e in _enemigos.get_children():
        e.activar()


# ---------- Mapa de tiles ----------
func _construir_mapa():
    var tileset = TileSet.new()
    tileset.tile_size = Vector2i(Cfg.CELDA, Cfg.CELDA)
    var fuente = TileSetAtlasSource.new()
    fuente.texture = load("res://assets/tiles.png")
    fuente.texture_region_size = Vector2i(Cfg.CELDA, Cfg.CELDA)
    for i in range(3):
        fuente.create_tile(Vector2i(i, 0))
    tileset.add_source(fuente, 0)
    _mapa.tile_set = tileset

    for x in range(Cfg.COLUMNAS):
        for y in range(Cfg.FILAS):
            var en_puerta = x == Cfg.COLUMNAS - 1 and y >= Cfg.FILA_PUERTA_INI and y <= Cfg.FILA_PUERTA_FIN
            var borde = x == 0 or y == 0 or y == Cfg.FILAS - 1 or x == Cfg.COLUMNAS - 1
            if borde and not en_puerta:
                _mapa.set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
            else:
                _mapa.set_cell(Vector2i(x, y), 0, Vector2i((x + y) % 2, 0))
    if numero == 2:
        _mapa.modulate = Color(0.85, 0.9, 1.1)
    elif numero == 3:
        _mapa.modulate = Color(1.15, 0.8, 0.8)


func _construir_paredes():
    var c = Cfg.CELDA
    var rects = [
        Rect2(0, 0, Cfg.ANCHO, c),
        Rect2(0, Cfg.ALTO - c, Cfg.ANCHO, c),
        Rect2(0, 0, c, Cfg.ALTO),
        Rect2(Cfg.ANCHO - c, 0, c, Cfg.PUERTA_Y - Cfg.PUERTA_MEDIO),
        Rect2(Cfg.ANCHO - c, Cfg.PUERTA_Y + Cfg.PUERTA_MEDIO, c, Cfg.ALTO - Cfg.PUERTA_Y - Cfg.PUERTA_MEDIO),
    ]
    for r in rects:
        var cuerpo = StaticBody2D.new()
        cuerpo.position = r.position + r.size / 2.0
        var forma = CollisionShape2D.new()
        var caja = RectangleShape2D.new()
        caja.size = r.size
        forma.shape = caja
        cuerpo.add_child(forma)
        _paredes.add_child(cuerpo)


func _crear_puerta():
    puerta = ESCENA_PUERTA.instantiate()
    puerta.position = Vector2(Cfg.ANCHO - Cfg.CELDA / 2.0, Cfg.PUERTA_Y)
    _puertas.add_child(puerta)


# ---------- Puntos de aparicion de enemigos y objetos ----------
func _poblar():
    match numero:
        1:
            _enemigo(ESCENA_GOBLIN, Vector2(800, 200))
            _enemigo(ESCENA_GOBLIN, Vector2(900, 500))
            _objeto("pocion", Vector2(300, 160))
            _objeto("llave", Vector2(1150, 600))
            _objeto("moneda", Vector2(600, 120))
            _objeto("moneda", Vector2(600, 580))
            _objeto("moneda", Vector2(450, 352))
        2:
            _enemigo(ESCENA_GOBLIN, Vector2(600, 150))
            _enemigo(ESCENA_GOBLIN, Vector2(600, 550))
            _enemigo(ESCENA_GOBLIN, Vector2(950, 250))
            _enemigo(ESCENA_GOBLIN, Vector2(950, 450))
            _objeto("llave", Vector2(1150, 600))
            _objeto("moneda", Vector2(300, 500))
            _objeto("moneda", Vector2(300, 220))
            _objeto("moneda", Vector2(700, 352))
            var palanca = ESCENA_PALANCA.instantiate()
            palanca.position = Vector2(200, 150)
            palanca.activada.connect(_on_palanca)
            _objetos.add_child(palanca)
        3:
            var orco = _enemigo(ESCENA_ORCO, Vector2(950, 352))
            orco.jefe_derrotado.connect(func(p): jefe_derrotado.emit(p))
            _objeto("pocion", Vector2(200, 160))
            _objeto("moneda", Vector2(640, 120))
            _objeto("moneda", Vector2(640, 580))


func _enemigo(escena, pos):
    var e = escena.instantiate()
    e.position = pos
    # El enemigo entrega su XP directamente al jugador
    e.murio.connect(jugador.ganar_xp)
    e.murio.connect(func(_xp): _soltar(e.global_position))
    _enemigos.add_child(e)
    return e


func _objeto(tipo, pos):
    var o = ESCENA_OBJETO.instantiate()
    o.tipo = tipo
    o.position = pos
    _objetos.add_child(o)


# Los enemigos al morir pueden soltar una pocion o una moneda
func _soltar(pos):
    if randf() < 0.3:
        var tipo = "moneda"
        if randf() < 0.4:
            tipo = "pocion"
        call_deferred("_objeto", tipo, pos)


func _on_palanca():
    call_deferred("_agregar_cofre")


func _agregar_cofre():
    var cofre = ESCENA_COFRE.instantiate()
    cofre.position = Vector2(1100, 120)
    _objetos.add_child(cofre)


func soltar_llave(pos):
    call_deferred("_objeto", "llave", pos)
