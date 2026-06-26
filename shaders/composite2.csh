#version 450

layout(local_size_x = 16, local_size_y = 16) in;

layout(std430, binding = 0) buffer PointBuffer {
    uint index;
    uint count;
    vec4 positions[];
};

layout(std430, binding = 1) buffer DepthBuffer {
    uint depthValues[];
};

layout (rgba8) uniform image2D finalTex;


uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform float viewWidth;


void main() {
    if (gl_GlobalInvocationID.x >= 16 || gl_GlobalInvocationID.y >= 16) return;

    uint threadID = gl_GlobalInvocationID.x + (gl_GlobalInvocationID.y * 16);
    uint totalPoints = min(count, 2048000u);
    ivec2 texSize = imageSize(finalTex);

    for (uint i = threadID; i < totalPoints; i += 256) {
        vec3 relativePos = positions[i].xyz - cameraPosition;
        vec4 viewPos = gbufferModelView * vec4(relativePos, 1.0);
        vec4 clipPos = gbufferProjection * viewPos;

        if (clipPos.w <= 0.0) continue;
        vec3 ndcPos = clipPos.xyz / clipPos.w;
        if (abs(ndcPos.x) > 1.0 || abs(ndcPos.y) > 1.0) continue;

        ivec2 pixelCoord = ivec2((ndcPos.xy * 0.5 + 0.5) * vec2(texSize));
        int bufferIndex = pixelCoord.x + (pixelCoord.y * int(viewWidth));

        uint depthInt = uint(max(0.0, -viewPos.z) * 1000.0); 

        atomicMin(depthValues[bufferIndex], depthInt);

    }
}