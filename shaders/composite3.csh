#version 450
layout(local_size_x = 32, local_size_y = 32) in;

layout (rgba8) uniform image2D finalTex;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse;
uniform vec2 screenSize;
uniform sampler2D gcolor;
uniform float frameTimeCounter;
uniform sampler2D noisetex;
uniform sampler2D colortex7;
uniform float viewWidth;

uniform float near;
uniform float far;

layout(std430, binding = 0) coherent buffer PointBuffer {
    uint index;
    uint count;
    vec4 positions[];
};

layout(std430, binding = 1) buffer DepthBuffer {
    uint depthValues[];
};

void main() {
    if (gl_GlobalInvocationID.x >= 16 || gl_GlobalInvocationID.y >= 16) return;

    uint threadID = gl_GlobalInvocationID.x + (gl_GlobalInvocationID.y * 16);
    
    uint totalPoints = min(count, 2048000u);
    for (uint i = threadID; i < totalPoints; i += 256) {
        vec4 particle = positions[i];
        vec3 worldPos = particle.xyz;

        vec3 relativePos = worldPos - cameraPosition;
        vec4 viewPos = gbufferModelView * vec4(relativePos, 1.0);
        vec4 clipPos = gbufferProjection * viewPos;

        if (clipPos.w <= 0.0) continue;

        vec3 ndcPos = clipPos.xyz / clipPos.w;

        if (abs(ndcPos.x) > 1.0 || abs(ndcPos.y) > 1.0) continue;

        vec2 screenCoord = ndcPos.xy * 0.5 + 0.5;
        ivec2 texSize = imageSize(finalTex);
        ivec2 pixelCoord = ivec2(screenCoord * vec2(texSize));

        uint depthInt = uint(max(0.0, -viewPos.z) * 1000.0);
        uint pixelDepth = depthValues[pixelCoord.x + pixelCoord.y * int(viewWidth)];

        vec4 color = vec4(1.0,1.0,1.0,1.0);
        color = vec4(particle[3]);

        if (depthInt <= pixelDepth) {
            imageStore(finalTex, pixelCoord, color);
        }
    }
}