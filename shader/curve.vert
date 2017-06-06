layout (location = 0) in vec3 position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 lightPosition;

out vec3 viewCoord, lightViewPosition, normal;

void main(void)
{
  vec2 tangentHorizontal = normalize(vec2(-1.0, 3 * position.x * position.x));
  float cosHorizontal = tangentHorizontal.x;
  float sinHorizontal = tangentHorizontal.y;
  mat3 horizontalRotation = mat3(cosHorizontal, -sinHorizontal, 0,
                                 sinHorizontal, cosHorizontal,  0,
                                 0,             0,              1);

  vec3 rotatedPosition = horizontalRotation * vec3(0.0, position.y, position.z);
  normal = -normalize(rotatedPosition);
  rotatedPosition.x += position.x;
  rotatedPosition.y += position.x * position.x * position.x;

  vec4 positionView = view * model * vec4(rotatedPosition, 1.0);

  viewCoord = positionView.xyz;
  lightViewPosition = (view * vec4(lightPosition, 1.0)).xyz;

  gl_Position = projection * positionView;
}
