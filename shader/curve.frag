in vec3 viewCoord, lightViewPosition, normal;

uniform vec3 lightColor;
uniform mat4 normalMatrix;

out vec4 color;

void main(void)
{
  vec3 normal = normalize(mat3(normalMatrix) * normal);
  vec3 baseColor = vec3(1.0, 0.75, 0.5);
  vec3 lightDirection = normalize(viewCoord - lightViewPosition );
  float diffuse = max(dot(normal, lightDirection), 0.0)* 0.75;

  vec3 viewDirection = normalize(viewCoord);
  vec3 reflectDirection = reflect(-lightDirection, normal);
  float specular = pow(max(dot(viewDirection, reflectDirection), 0.0), 32);

  color = vec4(((0.4 + diffuse + specular) * lightColor) * baseColor, 1.0);
}
