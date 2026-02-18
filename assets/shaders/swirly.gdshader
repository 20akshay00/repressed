shader_type canvas_item;

uniform vec4 color_deep : source_color = vec4(0.05, 0.02, 0.1, 1.0);
uniform vec4 color_mid : source_color = vec4(0.2, 0.1, 0.3, 1.0);
uniform vec4 color_high : source_color = vec4(0.1, 0.3, 0.4, 1.0);

uniform vec2 world_pos; // Pass Camera2D.get_screen_center_position() here
uniform float speed = 0.5;

void fragment() {
    // Parallax: Mix Screen UV with World Position
    // We multiply world_pos by a small decimal to control how "far back" it feels
    float py = SCREEN_UV.y + (world_pos.y * 0.0005); 
    float px = SCREEN_UV.x + (world_pos.x * 0.0001);
    
    float t = TIME * speed;
    
    // Create horizontal "Delirium Strata"
    float noise = sin(py * 10.0 + t);
    noise += sin(py * 20.0 - t * 0.5) * 0.5;
    noise += sin(px * 5.0 + py * 5.0); // Adds some swirly diagonal distortion
    
    // Normalize noise to 0.0 - 1.0
    float mask = smoothstep(-1.0, 1.0, noise);
    
    // COLOR GRADIENT: Change the color based on absolute height (world_pos.y)
    // As you go UP, world_pos.y becomes smaller (more negative)
    float height_factor = clamp(-world_pos.y * 0.0001, 0.0, 1.0);
    vec3 current_base = mix(color_deep.rgb, color_mid.rgb, height_factor);
    vec3 final_color = mix(current_base, color_high.rgb, mask * 0.5);
    
    // Add a "vignette" so the edges of the screen are darker
    float vignette = distance(SCREEN_UV, vec2(0.5));
    final_color *= (1.0 - vignette * 0.8);
    
    COLOR = vec4(final_color, 1.0);
}