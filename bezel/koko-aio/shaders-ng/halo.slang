#version 450
#include "config.inc"
#include "includes/functions.include.slang"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vHALO_SHARPNESS;
layout(location = 2) out float vHALO_POWER;

vec2 radius_blur_adapt(vec2 bsize){
    vec2 r;
    r.x = bsize.x / SCALEMOD_X;
    r.y = r.x *  get_in_aspect();
    return r;
}

void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;

    //Adapt to the old params range
        vHALO_SHARPNESS = vec2(GLOW_SHARP_MAX - HALO_SHARPNESS);
        vHALO_SHARPNESS = vHALO_SHARPNESS/6.0;


//20..1 10...2 prova 5..3
    //Correct aspect
        vHALO_SHARPNESS = radius_blur_adapt(vHALO_SHARPNESS);


   if (HALO_POWER >= 0.0)
      vHALO_POWER = HALO_POWER;
         else
      vHALO_POWER = -HALO_POWER/10.0;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vHALO_SHARPNESS;
layout(location = 2) in float vHALO_POWER;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 4) uniform sampler2D Source;




vec3 blur_px(sampler2D smp, vec2 co, vec2 r, vec4 sourcesize) {
    vec3 c=vec3(0.0);
    float c1 = 0.75;
    float c2 = 1.25;

    //c1=1.0;
    //c2=1.0;
    
    c += texture(smp, co + vec2(0.0, 1.0) * r).rgb * c1;
    c += texture(smp, co + vec2(0.7071, 0.7071) * r).rgb * c2;
    c += texture(smp, co + vec2(1.0, 0.0) * r).rgb * c1 ;
    c += texture(smp, co + vec2(0.7071, -0.7071) * r).rgb * c2;
    c += texture(smp, co + vec2(0.0, -1.0) * r).rgb * c1;
    c += texture(smp, co + vec2(-0.7071, -0.7071) * r).rgb * c2;
    c += texture(smp, co + vec2(-1.0, 0.0) * r).rgb * c1;
    c += texture(smp, co + vec2(-0.7071, 0.7071) * r).rgb * c2;

    //vec3 c0 = texture(smp, co + vec2(0.0, 0.0) * r).rgb;
    //return min(c0, c/8.0);
    return c/8.0;
}




void main() {
    
    if (DO_HALO == 0.0 ) return;
    

    //Pass the right texture unchanged for tighter blurs:
    if (HALO_SHARPNESS >= GLOW_SHARP_MAX) {
        FragColor = vec4( pow(texture(Source, vTexCoord).rgb * vHALO_POWER,  vec3(HALO_GAMMA_OUT)), 1.0) ;
        return;
    }
    
    //pixel_haloed = blur5_x(Source, vTexCoord, params.SourceSize.xy, vHALO_SHARPNESS, 0.0);
    vec3 pixel_haloed = blur_px(Source, vTexCoord, vHALO_SHARPNESS, params.SourceSize) * vHALO_POWER;

    pixel_haloed =  pow(pixel_haloed, vec3(HALO_GAMMA_OUT));
    
    FragColor = vec4(pixel_haloed.rgb, 1.0);
    
}