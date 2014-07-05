#version 400
uniform sampler2D fbo_texture;
varying vec2 f_texcoord;
uniform vec2 winsize;

#define distortion 0.1

vec2 radialDistortion(vec2 coord){
  vec2 cc = coord - vec2(0.5);
  float dist = dot(cc, cc) * distortion;
  return coord + cc * (1.0 - dist) * dist;
}

void main(void) {
  vec2 texcoord=radialDistortion(f_texcoord);
  vec2 delta=vec2(0.5,0.5)/winsize;
  gl_FragColor = vec4(texture2D(fbo_texture, texcoord+delta).r,
                      texture2D(fbo_texture, texcoord).g,
                      texture2D(fbo_texture, texcoord-delta).b,
                      1
                      );
  vec2 d=delta*0.5;
  gl_FragColor += vec4(texture2D(fbo_texture, texcoord+delta+d).r,
                      texture2D(fbo_texture, texcoord+d).g,
                      texture2D(fbo_texture, texcoord-delta+d).b,
                      1
                      );
  gl_FragColor += vec4(texture2D(fbo_texture, texcoord+delta-d).r,
                      texture2D(fbo_texture, texcoord-d).g,
                      texture2D(fbo_texture, texcoord-delta-d).b,
                      1
                      );
  d=delta*1.5;
  gl_FragColor += vec4(texture2D(fbo_texture, texcoord+delta+d).r,
                      texture2D(fbo_texture, texcoord+d).g,
                      texture2D(fbo_texture, texcoord-delta+d).b,
                      1
                      );
  gl_FragColor += vec4(texture2D(fbo_texture, texcoord+delta-d).r,
                      texture2D(fbo_texture, texcoord-d).g,
                      texture2D(fbo_texture, texcoord-delta-d).b,
                      1
                      );
  gl_FragColor /= 5.0;
}