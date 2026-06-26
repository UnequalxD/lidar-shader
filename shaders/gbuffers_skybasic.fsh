#version 120


varying float vertexDistance;
varying vec3 position;
varying vec4 color;

uniform int fogShape;
uniform int fogMode;
uniform int renderStage;
uniform int isEyeInWater;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform float viewWidth;
uniform float viewHeight;

void main() {
	if(isEyeInWater != 0) {
		discard;
	}
	
	vec4 albedo = color;
	
	gl_FragData[0] = albedo;
}