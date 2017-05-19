in vec3 viewCoord, lightViewPosition, fragPosition;

uniform mat4 model;
uniform mat4 view;
uniform vec3 lightColor;

out vec4 color;

void main(void)
{
  vec3 a = getHeightVec(fragPosition.x, fragPosition.z);
  vec3 b = getHeightVec(fragPosition.x + 0.05, fragPosition.z);
  vec3 c = getHeightVec(fragPosition.x, fragPosition.z + 0.05);
  vec3 baseNormal = normalize(cross(b - a, c - a));
  vec3 normal = normalize(mat3(transpose(inverse(model * view))) * baseNormal);

  vec3 baseColor = vec3(0.5, 0.75, 1.0);
  vec3 lightDirection = normalize(viewCoord - lightViewPosition );
  float diffuse = max(dot(normal, lightDirection), 0.0) * 0.4;

  vec3 viewDirection = normalize(viewCoord);
  vec3 reflectDirection = reflect(-lightDirection, normal);
  float specular = pow(max(dot(viewDirection, reflectDirection), 0.0), 512);

  color = vec4(((0.1 + diffuse + specular) * lightColor) * baseColor, 1.0);
}
