#version 330 core

uniform sampler2D uTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uIntensity;

in vec2 vTexCoord;
out vec4 fragColor;

// Sepia filter
vec4 sepia(vec4 color) {
    float r = color.r;
    float g = color.g;
    float b = color.b;
    
    float tr = 0.393 * r + 0.769 * g + 0.189 * b;
    float tg = 0.349 * r + 0.686 * g + 0.168 * b;
    float tb = 0.272 * r + 0.534 * g + 0.131 * b;
    
    return vec4(tr, tg, tb, color.a);
}

// Grayscale filter
vec4 grayscale(vec4 color) {
    float average = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
    return vec4(average, average, average, color.a);
}

// Invert filter
vec4 invert(vec4 color) {
    return vec4(1.0 - color.r, 1.0 - color.g, 1.0 - color.b, color.a);
}

// Pixelate filter
vec4 pixelate(vec4 color) {
    float pixelSize = uIntensity;
    vec2 uv = vTexCoord;
    uv = floor(uv * uResolution / pixelSize) * pixelSize / uResolution;
    return texture(uTexture, uv);
}

void main() {
    vec4 color = texture(uTexture, vTexCoord);
    
    // Apply filters based on uniform values
    // This is a simplified version - in a real implementation,
    // you would have separate shaders for each filter
    
    fragColor = color;
}