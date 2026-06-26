#version 120

uniform sampler2D lightmap;

varying vec2 texcoord;
varying vec4 color;

void main() {
	texcoord = gl_MultiTexCoord0.xy;
	color = gl_Color * texture2D(lightmap, clamp(gl_MultiTexCoord1.xy / vec2(255.0f, 247.0f), 0.5f / 16.0f, 15.5f / 16.0f));

	gl_Position = ftransform();
}