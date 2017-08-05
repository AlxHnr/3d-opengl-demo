layout (location = 0) in vec3 position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 lightPosition;

uniform mat4 splineData;

out vec3 viewCoord, lightViewPosition, normal;

void main(void)
{
  int i = 0;
  if(position.x > splineData[3][2]) i = 2;
  else if(position.x > splineData[3][1]) i = 1;
  float xi = position.x - splineData[3][i];
  float xi2 = xi * xi;

  float slope =
    splineData[i][3] * 3.0 * xi2 +
    splineData[i][2] * 2.0 * xi +
    splineData[i][1];

  vec2 tangentHorizontal = normalize(vec2(-1.0, slope));

  float cosHorizontal = tangentHorizontal.x;
  float sinHorizontal = tangentHorizontal.y;
  mat3 horizontalRotation = mat3(cosHorizontal, -sinHorizontal, 0,
                                 sinHorizontal, cosHorizontal,  0,
                                 0,             0,              1);

  vec3 rotatedPosition = horizontalRotation * vec3(0.0, position.y, position.z);
  normal = -normalize(rotatedPosition);

  rotatedPosition.x += position.x;
  rotatedPosition.y +=
    splineData[i][3] * xi2 * xi +
    splineData[i][2] * xi2 +
    splineData[i][1] * xi +
    splineData[i][0];

  vec4 positionView = view * model * vec4(rotatedPosition, 1.0);

  viewCoord = positionView.xyz;
  lightViewPosition = (view * vec4(lightPosition, 1.0)).xyz;

  gl_Position = projection * positionView;
}
