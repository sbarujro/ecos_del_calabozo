class_name HUD
extends CanvasLayer
## Interfaz durante el juego: barra de vida, nivel y XP, monedas, llave y mensajes.

var _barra_vida = null
var _barra_xp = null
var _txt_vida = null
var _txt_nivel = null
var _txt_monedas = null
var _icono_llave = null
var _txt_sala = null
var _txt_mensaje = null
var _msg_id = 0


func _ready():
    layer = 10

    _icono(Vector2(10, 4), "res://assets/icono_corazon.png")
    _rect(Vector2(52, 10), Vector2(204, 22), Color(0.07, 0.0, 0.0))
    _barra_vida = _rect(Vector2(54, 12), Vector2(200, 18), Color(0.85, 0.1, 0.1))
    _txt_vida = _label(Vector2(60, 10), 14)

    _txt_nivel = _label(Vector2(52, 36), 16)
    _rect(Vector2(52, 60), Vector2(204, 12), Color(0.0, 0.05, 0.15))
    _barra_xp = _rect(Vector2(54, 62), Vector2(200, 8), Color(0.3, 0.65, 1.0))

    _icono(Vector2(10, 76), "res://assets/moneda_idle_0.png")
    _txt_monedas = _label(Vector2(50, 84), 18)
    _icono_llave = _icono(Vector2(10, 112), "res://assets/llave_idle_0.png")
    _icono_llave.visible = false

    _txt_sala = _label(Vector2(820, 12), 18)

    _txt_mensaje = _label(Vector2(0, 490), 18)
    _txt_mensaje.size = Vector2(960, 30)
    _txt_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _rect(pos, tam, color):
    var r = ColorRect.new()
    r.position = pos
    r.size = tam
    r.color = color
    add_child(r)
    return r


func _icono(pos, ruta):
    var t = TextureRect.new()
    t.texture = load(ruta)
    t.position = pos
    add_child(t)
    return t


func _label(pos, tam):
    var l = Label.new()
    l.position = pos
    l.add_theme_font_size_override("font_size", tam)
    l.add_theme_color_override("font_color", Color.WHITE)
    l.add_theme_color_override("font_outline_color", Color.BLACK)
    l.add_theme_constant_override("outline_size", 4)
    add_child(l)
    return l


func actualizar_vida(v, vmax):
    _barra_vida.size = Vector2(200.0 * float(v) / float(vmax), 18)
    _txt_vida.text = "%d / %d" % [v, vmax]


func actualizar_xp(xp, nivel, necesaria):
    _txt_nivel.text = "Nivel %d" % nivel
    _barra_xp.size = Vector2(200.0 * float(xp) / float(necesaria), 8)


func actualizar_inventario(inv):
    _txt_monedas.text = "x %d" % inv.get("moneda", 0)
    _icono_llave.visible = inv.get("llave", 0) > 0


func actualizar_sala(n, total):
    _txt_sala.text = "Sala %d/%d" % [n, total]


func mostrar_mensaje(texto):
    _msg_id += 1
    var id = _msg_id
    _txt_mensaje.text = texto
    await get_tree().create_timer(3.0).timeout
    if id == _msg_id:
        _txt_mensaje.text = ""
