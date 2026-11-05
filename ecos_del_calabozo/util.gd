class_name Util
extends RefCounted
## Utilidades: construye un SpriteFrames a partir de una lista de imagenes.


static func frames(definicion):
    var sf = SpriteFrames.new()
    if sf.has_animation("default"):
        sf.remove_animation("default")
    for nombre in definicion:
        var d = definicion[nombre]
        sf.add_animation(nombre)
        sf.set_animation_speed(nombre, d.get("vel", 6.0))
        sf.set_animation_loop(nombre, d.get("bucle", true))
        for ruta in d["archivos"]:
            sf.add_frame(nombre, load(ruta))
    return sf
