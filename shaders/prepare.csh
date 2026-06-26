#version 450

layout(local_size_x = 32, local_size_y = 32) in;
layout(std430, binding = 1) buffer DepthBuffer {
    uint depthValues[];
};
uniform float viewWidth;
uniform float viewHeight;
void main() {
    ivec2 pixel = ivec2(gl_GlobalInvocationID.xy);
    // You need a uniform for screen size here
    if (pixel.x < viewWidth && pixel.y < viewHeight) {
        depthValues[pixel.x + pixel.y * int(viewWidth)] = 999999999;
    }
}