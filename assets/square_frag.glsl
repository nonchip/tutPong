#version 400
out vec4 gl_FragColor;
void main(void) {
  gl_FragColor = vec4(1.0,1.0,1.0,1.0);
  float scanline=mod(floor(gl_FragCoord.y+0.5),2);
  if(scanline<0.9){
    gl_FragColor*=0.5;
  }
}