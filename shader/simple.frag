#version 330 core

in vec3 localCoords, worldCoords;
out vec4 color;

void main(void)
{
  vec4 localColor = vec4(localCoords/4, 1.0);
  vec4 worldColor = vec4(worldCoords/15.0/2 + 0.5, 1.0);

  color = worldColor - localColor;
}
