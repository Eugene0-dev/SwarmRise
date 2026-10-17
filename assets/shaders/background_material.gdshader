
shader_type canvas_item;

// Твоя фирменная UI палитра по умолчанию
uniform vec4 line_color : source_color = vec4(0.39, 0.61, 0.96, 1.0);  // Голубой UI
uniform vec4 fill_color : source_color = vec4(0.08, 0.08, 0.08, 1.0);  // Тёмный фон
uniform vec4 glitch_color : source_color = vec4(0.96, 0.43, 0.0, 1.0); // Тот самый оранжевый f66e00

uniform float grid_size = 40.0;       // Размер соты
uniform float line_thickness = 1.0;   // Толщина линий
uniform float pixel_size = 1.0;       // Размер пикселя
uniform vec2 camera_offset = vec2(0.0);

// Скорость движения сигналов по каналам
uniform float signal_speed = 2.0;

float pixel_noise(vec2 uv) {
    return fract(sin(dot(floor(uv), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // 1. Сетка и камера
    vec2 pixel_uv = floor((UV / SCREEN_PIXEL_SIZE) / pixel_size) * pixel_size;
    vec2 world_uv = (pixel_uv + camera_offset) / grid_size;
    
    vec2 m = vec2(1.7320508, 1.0); // sqrt(3), 1.0
    vec2 h = m * 0.5;
    
    vec2 a = mod(world_uv, m) - h;
    vec2 b = mod(world_uv - h, m) - h;
    
    vec2 gv = dot(a, a) < dot(b, b) ? a : b;
    vec2 hex_id = floor((world_uv - gv) * 10.0); // ID конкретной ячейки
    
    // 2. Геометрия шестиугольника
    float x = abs(gv.x);
    float y = abs(gv.y);
    float hex_dist = max(x * 0.8660254 + y * 0.5, y); 
    
    float current_thickness = (line_thickness * pixel_size) / grid_size;
    float outer_bound = 0.5;
    bool is_line = hex_dist > (outer_bound - current_thickness) && hex_dist <= outer_bound;
    
    // 3. Текстурный шум подложки
    float noise = pixel_noise(floor(world_uv * grid_size) / pixel_size);
    vec3 base_fill = fill_color.rgb + (noise * 0.02 - 0.01);
    
    // 4. Логика "поиска пути" по каналам
    // Используем синусоиды, направленные по трем осям гексагона (0, 60 и 120 градусов)
    float t = TIME * signal_speed;
    
    // Проекции для движения вдоль ребер
    float channel1 = sin((world_uv.x * 0.866 + world_uv.y * 0.5) * 5.0 - t);
    float channel2 = sin((world_uv.x * -0.866 + world_uv.y * 0.5) * 5.0 + t);
    float channel3 = cos((world_uv.y) * 5.0 - t * 0.7);
    
    // Псевдослучайный выбор активных каналов на основе ID ячейки (чтобы они не текли везде одновременно)
    float cell_random = pixel_noise(hex_id);
    
    // Объединяем волны в ветвящуюся структуру
    float signal = 0.0;
    if (cell_random < 0.33) signal = channel1;
    else if (cell_random < 0.66) signal = channel2;
    else signal = channel3;
    
    // Делаем импульсы тонкими и бегущими (вырезаем только пики волн)
    float signal_mask = smoothstep(0.7, 0.95, signal);
    
    // Дополнительное хаотичное затухание, чтобы ветки "засыхали" и появлялись в других местах
    float pulse_fade = sin(TIME * 0.5 + cell_random * 6.28) * 0.5 + 0.5;
    signal_mask *= step(0.2, pulse_fade); 

    // 5. Финальный покрас
    vec3 final_color = base_fill;
    
    if (is_line) {
        // Смешиваем базовый синий и ползущий оранжевый сигнал
        final_color = mix(line_color.rgb, glitch_color.rgb, signal_mask);
        
        // Добавляем остаточное мягкое свечение в точках, где сигнал только что прошел
        if (signal_mask > 0.1) {
            final_color += glitch_color.rgb * signal_mask * 0.3;
        }
    } else {
        // Слабый оранжевый отсвет внутри активированных ячеек (эффект работы процессора)
        if (signal_mask > 0.6 && pixel_noise(pixel_uv) > 0.96) {
            final_color = mix(final_color, glitch_color.rgb, 0.15);
        }
    }
    
    COLOR = vec4(final_color, 0.6);
}