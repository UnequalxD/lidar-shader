#version 120

uniform sampler2D texture;

uniform float viewWidth;
uniform float viewHeight;

uniform int fogShape;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

varying vec2 texcoord;
varying vec4 color;



void main() {
	vec4 albedo = texture2D(texture, texcoord) *0.8;
	
	gl_FragData[0] = albedo;
}