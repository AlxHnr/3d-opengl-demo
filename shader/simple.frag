#version 330 core

in vec3 coords;
out vec4 color;

void main(void)
{
  float avg = (coords.r + coords.g + coords.b)/3.0;

  color = vec4(0.0, 0.0, 0.0, 1.0);
  color.r = avg/3.0 + 0.33;
  color.g = avg/3.0 + 0.66;
}
