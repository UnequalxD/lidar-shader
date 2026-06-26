#version 450

layout(location = 0) in vec3 vaPosition;
layout(location = 1) in vec2 vaUV0;

out vec2 texCoord;

void main() {
    gl_Position = vec4(vaPosition.xy * 2.0 - 1.0, 0.0, 1.0);
    texCoord = vaUV0;
}