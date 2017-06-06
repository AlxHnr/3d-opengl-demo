layout (location = 0) in vec3 position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 lightPosition;

out vec3 viewCoord, lightViewPosition, normal;

void main(void)
{
  vec3 a = getHeightVec(position.x, position.z);
  vec3 b = getHeightVec(position.x + 0.05, position.z);
  vec3 c = getHeightVec(position.x, position.z + 0.05);
  normal = normalize(cross(b - a, c - a));

  vec4 positionView = view * model * vec4(a, 1.0);

  viewCoord = positionView.xyz;
  lightViewPosition = (view * vec4(lightPosition, 1.0)).xyz;

  gl_Position = projection * positionView;
}
