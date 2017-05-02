#version 330 core

in vec3 localCoord, worldCoord, viewCoord, sunViewPosition, normal;

uniform vec3 sunColor;

out vec4 color;

void main(void)
{
  vec3 coordColor = vec3(worldCoord/30.0 + 0.5) - vec3(localCoord/4);
  vec3 sunDirection = normalize(sunViewPosition - viewCoord);
  float diffuse = max(dot(normal, sunDirection), 0.0);

  color = vec4(((0.15 + diffuse) * sunColor) * coordColor, 1.0);
}
