// SHADER
shader_type canvas_item;

uniform float speed = 2.0;
uniform float frequency = 10.0;
uniform float amplitude = 0.02;
uniform float is_mirage_f = 0.0;

void fragment() {
	vec2 uv = UV;
	uv.x += sin(uv.y * frequency + TIME * speed) * amplitude * is_mirage_f;
	vec4 tex = texture(TEXTURE, uv);
	COLOR = vec4(tex.rgb, tex.a * COLOR.a);
	COLOR.a *= mix(1.0, 0.4, is_mirage_f);
}