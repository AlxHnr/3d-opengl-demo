in vec3 viewCoord, lightViewPosition, normal;

uniform vec3 color, lightColor;
uniform mat4 normalMatrix;

out vec4 colorOut;

void main(void)
{
  vec3 normal = normalize(mat3(normalMatrix) * normal);
  vec3 lightDirection = normalize(viewCoord - lightViewPosition);
  float diffuse = max(dot(normal, lightDirection), 0.0) * 0.75;

  vec3 viewDirection = normalize(viewCoord);
  vec3 reflectDirection = reflect(-lightDirection, normal);
  float specular = pow(max(dot(viewDirection, reflectDirection), 0.0), 32);

  colorOut = vec4(((0.2 + diffuse + specular) * lightColor) * color, 1.0);
}
