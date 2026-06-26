#version 120


uniform sampler2D lightmap;

uniform mat4 gbufferModelViewInverse;

uniform int entityId;

varying vec2 texcoord;
varying vec4 color;

const vec3 lightPos = vec3(0.16169041669088866, 0.8084520834544432, -0.5659164584181102); // normalize(vec3(0.2f, 1.0f, -0.7f)), values from Beta 1.7.3
const float ambientBrightness = 0.4f;
const float lightBrightness = 0.6f;

void main() {
	color = gl_Color * texture2D(lightmap, (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy);
	texcoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();
}