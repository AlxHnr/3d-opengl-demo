layout (location = 0) in vec3 position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 lightPosition;

uniform mat4 splineData;

out vec3 viewCoord, lightViewPosition, normal;

void main(void)
{
  float slope = 0.0;
  vec2 tangentHorizontal = normalize(vec2(-1.0, slope));

  float cosHorizontal = tangentHorizontal.x;
  float sinHorizontal = tangentHorizontal.y;
  mat3 horizontalRotation = mat3(cosHorizontal, -sinHorizontal, 0,
                                 sinHorizontal, cosHorizontal,  0,
                                 0,             0,              1);

  vec3 rotatedPosition = horizontalRotation * vec3(0.0, position.y, position.z);
  normal = -normalize(rotatedPosition);

  int spline_index;
  float xi;

  if(position.x > splineData[2][1])
  {
    spline_index = 1;
    xi = position.x - splineData[2][1];
  }
  else
  {
    spline_index = 0;
    xi = position.x - splineData[2][0];
  }
  xi = position.x;

  rotatedPosition.x += position.x;
  rotatedPosition.y +=
    splineData[spline_index][0] * xi * xi * xi +
    splineData[spline_index][1] * xi * xi +
    splineData[spline_index][2] * xi +
    splineData[spline_index][3];

  vec4 positionView = view * model * vec4(rotatedPosition, 1.0);

  viewCoord = positionView.xyz;
  lightViewPosition = (view * vec4(lightPosition, 1.0)).xyz;

  gl_Position = projection * positionView;
}
