shader_type canvas_item;

// Цвет и толщина контура
uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.0;

void fragment() {
    // Размер одного пикселя текстуры
    vec2 ps = TEXTURE_PIXEL_SIZE * outline_width;
    
    // Берем альфу текущего пикселя оригинального спрайта
    float base_alpha = texture(TEXTURE, UV).a;
    
    // Если мы находимся внутри спрайта — делаем его прозрачным
    if (base_alpha > 0.1) {
        COLOR = vec4(0.0);
    } else {
        // Проверяем соседние пиксели (крестом + по диагонали для плавности)
        float outline_alpha = 0.0;
        
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, -ps.y)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(0.0, ps.y)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-ps.x, 0.0)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(ps.x, 0.0)).a);
        
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-ps.x, -ps.y)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(ps.x, -ps.y)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(-ps.x, ps.y)).a);
        outline_alpha = max(outline_alpha, texture(TEXTURE, UV + vec2(ps.x, ps.y)).a);
        
        // Если рядом есть пиксель спрайта — рисуем контур
        if (outline_alpha > 0.0) {
            COLOR = outline_color;
        } else {
            COLOR = vec4(0.0);
        }
    }
}