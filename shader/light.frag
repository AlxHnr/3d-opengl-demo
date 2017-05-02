#version 330 core

in vec3 localCoord, worldCoord, normal;

uniform vec3 sunColor, sunPosition;

out vec4 color;

void main(void)
{
  vec3 coordColor = vec3(worldCoord/15.0/2 + 0.5) - vec3(localCoord/4);
  vec3 sunDirection = normalize(sunPosition - worldCoord);
  float diffuse = max(dot(normal, sunDirection), 0.0);

  color = vec4(((0.15 + diffuse) * sunColor) * coordColor, 1.0);
}
