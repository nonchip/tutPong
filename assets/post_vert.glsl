#version 400
in vec2 in_Position;
uniform sampler2D fbo_texture;
varying vec2 f_texcoord;
void main(void) {
  gl_Position = vec4((in_Position*2)-vec2(1,1), 0.0, 1.0);
  f_texcoord=in_Position;
}