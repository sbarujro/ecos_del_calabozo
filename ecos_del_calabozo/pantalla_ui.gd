class_name PantallaUI
extends CanvasLayer
## Base de todas las pantallas con botones (menu, pausa, inventario, game over...).
## Las pantallas hijas definen titulo, texto y botones en _configurar().

signal accion(nombre)

var titulo = ""
var texto = ""
var botones = []      # lista de [etiqueta, nombre_de_la_accion]
var opaco = false

var _etiqueta_texto = null
var _primer_boton = null


# Las pantallas hijas sobrescriben este metodo
func _configurar():
    pass


func _ready():
    layer = 20
    _configurar()

    var fondo = ColorRect.new()
    if opaco:
        fondo.color = Color(0.05, 0.05, 0.1, 1.0)
    else:
        fondo.color = Color(0.0, 0.0, 0.0, 0.82)
    fondo.size = Vector2(960, 540)
    add_child(fondo)

    var centro = CenterContainer.new()
    centro.size = Vector2(960, 540)
    fondo.add_child(centro)

    var caja = VBoxContainer.new()
    caja.add_theme_constant_override("separation", 14)
    centro.add_child(caja)

    caja.add_child(_crear_etiqueta(titulo, 44))
    _etiqueta_texto = _crear_etiqueta(texto, 20)
    caja.add_child(_etiqueta_texto)

    for b in botones:
        var boton = _crear_boton(b[0], b[1])
        caja.add_child(boton)
        if _primer_boton == null:
            _primer_boton = boton
    call_deferred("_enfocar")


func _enfocar():
    if _primer_boton != null:
        _primer_boton.grab_focus()


func actualizar(nuevo_texto):
    _etiqueta_texto.text = nuevo_texto


func _crear_etiqueta(contenido, tam):
    var l = Label.new()
    l.text = contenido
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", tam)
    l.add_theme_color_override("font_color", Color.WHITE)
    l.add_theme_color_override("font_outline_color", Color.BLACK)
    l.add_theme_constant_override("outline_size", 6)
    return l


func _crear_boton(etiqueta, clave):
    var b = Button.new()
    b.text = etiqueta
    b.custom_minimum_size = Vector2(260, 46)
    b.add_theme_font_size_override("font_size", 20)
    b.add_theme_stylebox_override("normal", _estilo(Color.html("283593")))
    b.add_theme_stylebox_override("hover", _estilo(Color.html("3949ab")))
    b.add_theme_stylebox_override("pressed", _estilo(Color.html("1a237e")))
    b.add_theme_stylebox_override("focus", _estilo(Color.html("5c6bc0")))
    b.pressed.connect(func(): accion.emit(clave))
    return b


func _estilo(color):
    var sb = StyleBoxFlat.new()
    sb.bg_color = color
    sb.set_border_width_all(3)
    sb.border_color = Color.html("c5cae9")
    sb.set_corner_radius_all(2)
    return sb
