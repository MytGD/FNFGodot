#include <godot_cpp/classes/canvas_item.hpp>
#include <godot_cpp/variant/transform2d.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {
    class FunkinSprite: public CanvasItem(
        GDCLASS(FunkinSprite,CanvasItem)
    )
}