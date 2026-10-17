
shader_type canvas_item;

// --- НАСТРОЙКИ ВЕТРА ---
uniform float sway_speed : hint_range(0.0, 10.0) = 2.5;
uniform float sway_strength : hint_range(0.0, 10.0) = 1.5; 
uniform float phase_offset : hint_range(0.0, 10.0) = 0.5;

// ЗАДАЙ ЗДЕСЬ ВЫСОТУ ТВОЕГО ТАЙЛА/СПРАЙТА ДЕРЕВА В ПИКСЕЛЯХ
// Если дерево нарисовано на одном тайле 8x8, оставь 8.0.
// Если оно высокое (например, 2 тайла в высоту) — поставь 16.0.
uniform float tile_height_pixels = 8.0; 

// --- НАСТРОЙКИ СЕКСУАЛЬНОСТИ И ОБЪЕМА ---
uniform float de_saturation : hint_range(0.0, 1.0) = 0.15; 
uniform float volume_shadow : hint_range(0.0, 1.0) = 0.25; 
uniform float light_gradient : hint_range(0.0, 1.0) = 0.2; 

varying vec2 world_pos;
varying float local_y_factor;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
    
    // ЖЕСТКИЙ ФИКС КОРНЕЙ ПО КООРДИНАТАМ ВЕРШИН
    // В Godot координаты VERTEX идут от 0 (верх) до tile_height_pixels (низ)
    // Переводим это в нормализованный фактор от 0.0 (низ, корни) до 1.0 (верх, макушка)
    local_y_factor = 1.0 - (VERTEX.y / tile_height_pixels);
    
    // Защита от вылета за границы (на случай кастомных мешей)
    local_y_factor = clamp(local_y_factor, 0.0, 1.0);
    
    // Возводим в куб, чтобы у корней качание гасилось моментально и жестко
    float sway_factor = pow(local_y_factor, 3.0);
    
    float phase = world_pos.x * phase_offset + world_pos.y * 0.3;
    
    // Качаем макушку, корни гарантированно получают множитель 0.0
    VERTEX.x += sin(TIME * sway_speed + phase) * sway_strength * sway_factor;
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    if (tex_color.a > 0.0) {
        // 1. ЦВЕТОКОРРЕКЦИЯ
        float luminance = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
        tex_color.rgb = mix(tex_color.rgb, vec3(luminance), de_saturation);
        
        // 2. ОБЪЕМ КРОНЫ (Привязанный к локальному фактору высоты, чтобы не ломался в атласе)
        // Делаем фейковую тень ближе к нижней части кроны
        float shadow_map = smoothstep(0.8, 0.2, local_y_factor);
        tex_color.rgb -= shadow_map * volume_shadow;
        
        // 3. ВЕРТИКАЛЬНЫЙ ГРАДИЕНТ
        // Плавное затемнение к корням
        tex_color.rgb -= (1.0 - local_y_factor) * light_gradient;
        
        // Подсветка макушки
        if (local_y_factor > 0.75) {
            tex_color.rgb += (local_y_factor - 0.75) * 0.2;
        }
    }
    
    COLOR = tex_color;
}