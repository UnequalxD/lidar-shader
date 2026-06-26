#version 450
in vec2 texCoord;
uniform sampler2D sfinalTex;
out vec4 fragColor;

void main() {
    fragColor = texture(sfinalTex, texCoord);
}