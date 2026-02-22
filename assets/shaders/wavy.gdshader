shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_freq : hint_range(0.0, 100.0) = 10.0;
uniform float wave_amp : hint_range(0.0, 0.1) = 0.005;

uniform float chromatic_aberration : hint_range(0.0, 0.02) = 0.003;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;

uniform vec4 shift_color : source_color = vec4(1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.15;
uniform float invert_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	float wave = sin(uv.y * wave_freq + TIME * wave_speed) * wave_amp;
	wave += cos(uv.x * wave_freq * 0.5 + TIME * wave_speed * 0.8) * wave_amp;
	
	vec2 distorted_uv = uv + vec2(wave, wave);
	
	float r = texture(screen_texture, distorted_uv + vec2(chromatic_aberration, 0.0)).r;
	float g = texture(screen_texture, distorted_uv).g;
	float b = texture(screen_texture, distorted_uv - vec2(chromatic_aberration, 0.0)).b;
	
	vec4 color = vec4(r, g, b, 1.0);
	
	vec3 inverted_rgb = 1.0 - color.rgb;
	color.rgb = mix(color.rgb, inverted_rgb, invert_amount);
	
	color.rgb = mix(color.rgb, shift_color.rgb, tint_strength);
	
	float dist = distance(uv, vec2(0.5));
	color.rgb *= smoothstep(0.8, 0.8 - vignette_intensity, dist);
	
	COLOR = color;
}