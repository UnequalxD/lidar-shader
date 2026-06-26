#version 450

#define Beam_Amount 400 //[200 400 600 800 1000 1200 1400] Change the amount of beams that fire each frame.
#define Radius_Multiplier 1.0 // [0.4 0.6 0.8 1.0 1.2 1.4 1.6] Change the size of the firing circle.
#define Shape 1 // [2 3 4 5 6] 

//1 = circle
//2 = square
//3 = fullscreen
//4 = scanning circle
//5 = scanning square
//6 = scanning fullscreen



uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform sampler2D gcolor;
uniform sampler2D noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float aspectRatio;
uniform bool is_sneaking;
uniform float frameTimeCounter;

uniform float near;
uniform float far;

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 0) coherent buffer PointBuffer {
    uint index;   // This acts as the "Global Write Head"
    uint count;   // This tracks how many total points are valid
    vec4 positions[2048000];
};

uint hash(uint x) {
    x = ((x >> 16) ^ x) * 0x45d9f3bu;
    x = ((x >> 16) ^ x) * 0x45d9f3bu;
    x = (x >> 16) ^ x;
    return x;
}

float floatHash(uint x) {
    return float(hash(x)) / 4294967295.0;
}

float rgb_to_hue(vec4 rgb) {
    float r = rgb.r;
    float g = rgb.g;
    float b = rgb.b;

    float maxval = max(r, max(g, b));
    float minval = min(r, min(g, b));
    float delta = maxval - minval;

    // Undefined hue (gray); just return 0
    if (delta == 0.0)
        return 0.0;

    float h;

    if (maxval == r) {
        h = (g - b) / delta;
        if (g < b)
            h += 6.0;
    } else if (maxval == g) {
        h = (b - r) / delta + 2.0;
    } else {
        h = (r - g) / delta + 4.0;
    }

    h /= 6.0;
    return h;
}



void main() {
    uint beamAmount = uint(Beam_Amount);
    uint particleAmount = 2048000;
    float radiusDivider = 5.0;

    if (gl_GlobalInvocationID.y > 0 || gl_GlobalInvocationID.x >= beamAmount || !is_sneaking) {
        return;
    }
    
    uint seed = hash((gl_GlobalInvocationID.x + 1)*int(frameTimeCounter*1000.0+1000.0*(gl_GlobalInvocationID.x+1)*(gl_GlobalInvocationID.y+1)));
    vec3 random = texture(noisetex, vec2(floatHash(seed)*1000.0)).rgb;
    vec3 randomrandom = texture(noisetex, vec2(random.r, random.g)).rgb;
    
    vec2 screenPos = vec2(0.0, 0.0);

    #if Shape == 1
    float angle = floatHash(uint(frameTimeCounter*1000.0 * (gl_GlobalInvocationID + 1))) * 6.28318;
    float radius = random.r/radiusDivider * Radius_Multiplier;
    screenPos = vec2(0.5) + vec2(cos(angle) / aspectRatio, sin(angle)) * radius;
    #endif

    #if Shape == 2
    screenPos = vec2(0.5) + vec2(randomrandom.x / aspectRatio - 0.25, randomrandom.y - 0.5)/2.0 * Radius_Multiplier;
    #endif

    #if Shape == 3
    screenPos = vec2(randomrandom.x, randomrandom.y);
    #endif

    #if Shape == 4
    float angle = frameTimeCounter*1.3 + randomrandom.x/14;
    float radius = random.r/radiusDivider * Radius_Multiplier;
    screenPos = vec2(0.5) + vec2(cos(angle) / aspectRatio, sin(angle)) * radius;
    #endif

    #if Shape == 5
    screenPos = vec2(0.5) + vec2(randomrandom.x / aspectRatio - 0.25, (int(frameTimeCounter * 500.0)%1000)/1200.0-0.4+randomrandom.y/40.0)/2.0 * Radius_Multiplier;
    #endif

    #if Shape == 6
    screenPos = vec2(randomrandom.x, (int(frameTimeCounter * 500.0)%1000)/1000);
    #endif

    float depth = texture(depthtex0, screenPos).r;
    if (gl_GlobalInvocationID.x % 2 == 1) {
        depth = texture(depthtex2, screenPos).r;
    }
    float hue = rgb_to_hue(texture(gcolor, screenPos));
    hue = (texture(gcolor, screenPos).r + texture(gcolor, screenPos).g + texture(gcolor, screenPos).b)/3;

    if (depth >= 1.0) return;

    vec4 clipPos = vec4(screenPos * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPosH = gbufferProjectionInverse * clipPos;
    vec3 viewPos = viewPosH.xyz / viewPosH.w;
    vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;

    float minDistanceThreshold = 0.02; 
    for(int i = 0; i < 20; i++) {
        uint checkIdx = (index - 1 - i) % particleAmount;
        if(distance(positions[checkIdx].xyz, worldPos) < minDistanceThreshold) {
            return; 
        }
    }

    uint mySlot = atomicAdd(index, 1) % particleAmount;
    
    positions[mySlot] = vec4(worldPos, hue);

    if (count < particleAmount) {
        atomicAdd(count, 1);
    }
}