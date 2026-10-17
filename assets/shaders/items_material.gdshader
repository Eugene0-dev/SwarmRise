shader_type canvas_item;

// Настройки покачивания
uniform float wobble_speed : hint_range(0.0, 10.0) = 3.0;
uniform float wobble_amount : hint_range(0.0, 0.1) = 0.03;

// Настройки блика
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 0.6);
uniform float shine_speed : hint_range(0.0, 5.0) = 1.5;
uniform float shine_size : hint_range(0.0, 1.0) = 0.15;

// Настройки обводки
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);
uniform float outline_width : hint_range(0.0, 5.0) = 1.0;

void vertex() {
	// Делаем так, чтобы предмет качался сильнее сверху, а снизу оставался на месте
	// UV.y идет от 0 (верх) до 1 (низ), поэтому (1.0 - UV.y) дает максимальный эффект вверху
	float offset = sin(TIME * wobble_speed) * wobble_amount * (1.0 - UV.y);
	VERTEX.x += offset * (1.0 / TEXTURE_PIXEL_SIZE.x);
}

void fragment() {
	vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
	vec4 current_color = texture(TEXTURE, UV);
	
	// --- ЛОГИКА ОБВОДКИ ---
	float alpha = current_color.a;
	// Проверяем 4 соседних пикселя (крестом)
	alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
	alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
	alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
	
	vec4 final_color = current_color;
	
	// Если сам пиксель прозрачный, но рядом есть текстура — рисуем обводку
	if (current_color.a == 0.0 && alpha > 0.0) {
		final_color = outline_color;
	} else if (current_color.a > 0.0) {
		// --- ЛОГИКА БЛИКА (работает только внутри предмета) ---
		// Магия синуса для создания движущейся по диагонали линии
		float shine_line = sin((UV.x + UV.y) * 2.0 + TIME * shine_speed);
		// Если попали в диапазон линии блика — плавно смешиваем цвета
		if (shine_line > 1.0 - shine_size) {
			float factor = (shine_line - (1.0 - shine_size)) / shine_size;
			final_color.rgb = mix(current_color.rgb, shine_color.rgb, factor * shine_color.a);
		}
	}
	
	COLOR = final_color;
}