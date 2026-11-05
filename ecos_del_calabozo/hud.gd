class_name HUD
extends CanvasLayer
## Interfaz: barra de vida, nivel/XP, monedas, llave, inventario, mensajes y pantallas.

var _barra_vida
var _txt_vida
var _txt_nivel
var _txt_monedas
var _txt_llave
var _txt_sala
var _txt_mensaje
var _panel_inv
var _txt_inv
var _pantalla
var _txt_pantalla
var _msg_id = 0


func _ready():
    layer = 10

    var fondo = ColorRect.new()
    fondo.color = Color(0.2, 0.0, 0.0)
    fondo.position = Vector2(20, 12)
    fondo.size = Vector2(200, 18)
    add_child(fondo)

    _barra_vida = ColorRect.new()
    _barra_vida.color = Color(0.85, 0.1, 0.1)
    _barra_vida.position = Vector2(20, 12)
    _barra_vida.size = Vector2(200, 18)
    add_child(_barra_vida)

    _txt_vida = _crear_label(Vector2(26, 10), 14, self)
    _txt_nivel = _crear_label(Vector2(20, 36), 16, self)
    _txt_monedas = _crear_label(Vector2(20, 60), 16, self)
    _txt_llave = _crear_label(Vector2(20, 84), 16, self)
    _txt_sala = _crear_label(Vector2(830, 12), 18, self)

    _txt_mensaje = _crear_label(Vector2(0, 478), 18, self)
    _txt_mensaje.size = Vector2(960, 30)
    _txt_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    _panel_inv = ColorRect.new()
    _panel_inv.color = Color(0, 0, 0, 0.85)
    _panel_inv.position = Vector2(340, 175)
    _panel_inv.size = Vector2(280, 190)
    _panel_inv.visible = false
    add_child(_panel_inv)
    _txt_inv = _crear_label(Vector2(20, 14), 18, _panel_inv)

    _pantalla = ColorRect.new()
    _pantalla.color = Color(0, 0, 0, 0.82)
    _pantalla.position = Vector2.ZERO
    _pantalla.size = Vector2(960, 540)
    _pantalla.visible = false
    add_child(_pantalla)
    _txt_pantalla = _crear_label(Vector2.ZERO, 22, _pantalla)
    _txt_pantalla.size = Vector2(960, 540)
    _txt_pantalla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _txt_pantalla.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _crear_label(pos, tam, padre):
    var l = Label.new()
    l.position = pos
    l.add_theme_font_size_override("font_size", tam)
    l.add_theme_color_override("font_color", Color.WHITE)
    l.add_theme_color_override("font_outline_color", Color.BLACK)
    l.add_theme_constant_override("outline_size", 4)
    padre.add_child(l)
    return l


func actualizar_vida(v, vmax):
    _barra_vida.size = Vector2(200.0 * float(v) / float(vmax), 18)
    _txt_vida.text = "%d / %d" % [v, vmax]


func actualizar_xp(xp, nivel, necesaria):
    _txt_nivel.text = "Nivel %d   XP %d/%d" % [nivel, xp, necesaria]


func actualizar_inventario(inv):
    var pociones = inv.get("pocion", 0)
    var llaves = inv.get("llave", 0)
    var monedas = inv.get("moneda", 0)
    _txt_monedas.text = "Monedas: %d" % monedas
    _txt_llave.text = "Llave: %s" % ("sí" if llaves > 0 else "no")
    _txt_inv.text = "INVENTARIO\n\nPociones: %d\nLlaves: %d\nMonedas: %d\n\n[P] Usar poción\n[I] Cerrar" % [pociones, llaves, monedas]


func actualizar_sala(n, total):
    _txt_sala.text = "Sala %d/%d" % [n, total]


func alternar_inventario():
    _panel_inv.visible = not _panel_inv.visible


func mostrar_mensaje(texto):
    _msg_id += 1
    var id = _msg_id
    _txt_mensaje.text = texto
    await get_tree().create_timer(2.5).timeout
    if id == _msg_id:
        _txt_mensaje.text = ""


func mostrar_pantalla(titulo, cuerpo):
    _txt_pantalla.text = titulo + "\n\n" + cuerpo
    _pantalla.visible = true
    _panel_inv.visible = false


func ocultar_pantalla():
    _pantalla.visible = false
