#version 400
in vec2 in_Position;
uniform mat4 uf_transform_model; // moving objects
uniform mat4 uf_transform_projection; // projecting to screen space
void main(void) {
  gl_Position = uf_transform_projection*uf_transform_model*vec4(in_Position, 0.0, 1.0);
}