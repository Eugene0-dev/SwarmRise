shader_type canvas_item;

render_mode unshaded; 

uniform vec4 shadow_color : source_color = vec4(0.1, 0.1, 0.1, 0.05);
uniform vec2 speed = vec2(12.0, 6.0);
uniform float cloud_scale : hint_range(0.001, 0.05) = 0.001;
uniform float cloud_density : hint_range(0.0, 1.0) = 0.5;
uniform float pixel_size : hint_range(1.0, 32.0) = 4.0; 

varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// 1. Быстрая хэш-функция для генерации псевдослучайного числа от 0 до 1 по координатам
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// 2. Генератор процедурного шума (Value Noise)
float value_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Сглаживание по Эрмиту (Smoothstep-аналог для интерполяции)
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    // Хэшируем 4 угла пиксельного квадрата
    float a = hash(i + vec2(0.0, 0.0));
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    // Смешиваем их между собой
    return mix(a, b, u.x) + 
           (c - a) * u.y * (1.0 - u.x) + 
           (d - b) * u.x * u.y;
}

// 3. Фрактальный шум (FBM) — накладываем слои шума разного масштаба для детализации
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Два октавы (слоя) для облаков более чем достаточно, чтобы не грузить видяху
    v += a * value_noise(p); p = p * 2.0 + shift;a *= 0.5;
    v += a * value_noise(p);
    return v;
}

void fragment() {
    // Округляем координаты для жесткого пиксель-арта
    vec2 pixel_world_pos = floor(world_pos / pixel_size) * pixel_size;
    
    // Движение облаков
    vec2 movement = TIME * speed;
    vec2 uv = (pixel_world_pos + movement) * cloud_scale;
    
    // Получаем рандомный шум вместо синусоид
    float n = fbm(uv);
    
    // Настройка плотности через инспектора
    float threshold = 1.0 - cloud_density;
    float shadow_mask = step(threshold, n);
    
    COLOR = vec4(shadow_color.rgb, shadow_color.a * shadow_mask);
}