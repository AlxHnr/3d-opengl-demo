#version 330 core

in vec3 viewCoord, sunViewPosition, normal;

uniform vec3 sunColor;

out vec4 color;

void main(void)
{
  vec3 baseColor = vec3(1.0, 1.0, 1.0);
  vec3 sunDirection = normalize(viewCoord - sunViewPosition );
  float diffuse = max(dot(normal, sunDirection), 0.0);

  vec3 viewDirection = normalize(viewCoord);
  vec3 reflectDirection = reflect(sunDirection, normal);
  float specular = pow(max(dot(viewDirection, reflectDirection), 0.0), 32);

  color = vec4(((0.1 + diffuse) * sunColor) * baseColor, 1.0);
}
