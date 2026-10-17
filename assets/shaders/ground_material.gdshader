shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_linear_mipmap;

uniform float relief_strength : hint_range(0.0, 1.0) = 0.25;
// Теперь этот параметр регулирует, сколько раз шум повторится на весь мир.
// 1.0 — шум растянут ровно ОДИН раз на всю карту 2048х2048.
uniform float noise_freq : hint_range(0.1, 20.0) = 4.0; 
uniform vec2 light_dir = vec2(0.7, -0.7);

varying vec2 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // РАЗМЕР ТВОЕГО МИРА В ПИКСЕЛЯХ
    // 2048 тайлов * 16 пикселей (замени 16 на свой размер тайла, если он другой, например 32)
    float world_size_in_pixels = 2048.0 * 8.0; 
    
    // Переводим мировые пиксельные координаты в идеальный глобальный UV (от 0.0 до 1.0 на весь мир)
    vec2 global_uv = world_pos / world_size_in_pixels;
    
    // Масштабируем этот глобальный UV с помощью частоты шума
    vec2 noise_uv = global_uv * noise_freq;
    
    // Шаг смещения для расчета наклона ландшафта (в глобальных UV)
    float delta = 0.001; 
    
    float height = texture(noise_tex, noise_uv).r;
    float height_x = texture(noise_tex, noise_uv + vec2(delta, 0.0)).r;
    float height_y = texture(noise_tex, noise_uv + vec2(0.0, delta)).r;
    
    float slope_x = height - height_x;
    float slope_y = height - height_y;
    vec2 slope = vec2(slope_x, slope_y);
    
    float lighting = dot(normalize(slope + 0.0001), normalize(light_dir));
    float intensity = length(slope) * lighting * relief_strength * 10.0;
    
    tex_color.rgb += intensity;

    COLOR = tex_color;
}