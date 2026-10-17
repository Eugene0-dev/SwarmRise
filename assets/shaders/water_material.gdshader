shader_type canvas_item;

uniform vec4 water_color : source_color = vec4(0.2, 0.5, 0.9, 0.6);
uniform float speed : hint_range(0.0, 10.0) = 1.5;

// === ТВОИ ПАРАМЕТРЫ ДЛЯ ТЕКСТУРЫ ===
uniform float scale_x : hint_range(0.01, 2.0) = 0.12;
uniform float scale_y : hint_range(0.01, 2.0) = 0.35;
uniform float pixel_size : hint_range(1.0, 32.0) = 4.0;

// === НОВЫЕ ПАРАМЕТРЫ ИСКРИВЛЕНИЯ ГЕОМЕТРИИ ===
// Это самые важные параметры. Рекомендую начать с этих значений.
uniform float wobble_strength : hint_range(0.0, 10.0) = 3.0; // Амплитуда покачивания границы
uniform float wobble_frequency : hint_range(0.0, 50.0) = 20.0; // Частота изгибов вдоль ребра тайла
varying vec2 world_pos;

void vertex() {
	// Сначала получаем мировую позицию вершины до искажений
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	
	// === МАГИЯ ИСКРИВЛЕНИЯ ВЕРШИН ===
	// Мы смещаем X и Y каждой вершины, используя волновую функцию.
	// world_pos.x * world_pos.y заставляет волны идти не просто по прямой, а более хаотично.
	
	vec2 wobble_offset;
	wobble_offset.x = sin(TIME * speed + world_pos.y * wobble_frequency) * wobble_strength;
	wobble_offset.y = cos(TIME * speed + world_pos.x * wobble_frequency) * wobble_strength;
	
	// Применяем смещение к VERTEX (это позиция вершины в координатах тайла)
	// Важно! Мы смещаем не текстуру внутри квадрата, а сам квадрат целиком.
	VERTEX += wobble_offset;
	
	// Обновляем world_pos уже с учетом смещения для fragment()
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// === ТВОЙ ОРИГИНАЛЬНЫЙ ФРАГМЕНТНЫЙ ШЕЙДЕР БЕЗ ИЗМЕНЕНИЙ ===
	// Он просто берет уже искаженные координаты и рисует на них воду.
	vec2 pixel_world_pos = floor(world_pos / pixel_size) * pixel_size;
	
	float t = TIME * speed;
	
	float cx = pixel_world_pos.x * scale_x;
	float cy = pixel_world_pos.y * scale_y;
	
	float wave1 = sin(cx + t) + cos(cy + t * 0.4);
	float wave2 = sin(cx * 0.7 - cy * 1.3 + t * 1.3) * 0.8;
	float micro_noise = sin(cx * 2.1 + cy * 1.7 - t * 0.8) * 0.4;
	
	float noise = (wave1 + wave2 + micro_noise) / 2.2;
	
	vec4 final_color = water_color;
	if (noise > 0.6) {
		final_color.rgb += 0.15;
	} else if (noise < -0.65) {
		final_color.rgb -= 0.05;
	}
	
	COLOR = final_color;
}