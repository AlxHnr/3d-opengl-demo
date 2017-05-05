#version 330 core

in vec3 viewCoord, lightViewPosition, normal;

uniform vec3 lightColor;

out vec4 color;

void main(void)
{
  vec3 baseColor = vec3(1.0, 1.0, 1.0);
  vec3 lightDirection = normalize(viewCoord - lightViewPosition );
  float diffuse = max(dot(normal, lightDirection), 0.0);

  vec3 viewDirection = normalize(viewCoord);
  vec3 reflectDirection = reflect(lightDirection, normal);
  float specular = pow(max(dot(viewDirection, reflectDirection), 0.0), 32);

  color = vec4(((0.1 + diffuse + specular) * lightColor) * baseColor, 1.0);
}
