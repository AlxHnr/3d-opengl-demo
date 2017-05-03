#version 330 core

layout (location = 0) in vec3 position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 sunPosition;
uniform float time;

out vec3 viewCoord, sunViewPosition, normal;

vec3 getHeightVec(float x, float z)
{
  return vec3(x, sin(time + x * 5) *
                 cos(time + z * 5)/5.0, z);
}

void main(void)
{
  vec3 a = getHeightVec(position.x, position.z);
  vec3 b = getHeightVec(position.x + 0.05, position.z);
  vec3 c = getHeightVec(position.x, position.z + 0.05);
  vec3 baseNormal = normalize(cross(b - a, c - a));

  mat4 modelView = view * model;
  vec4 positionView = modelView * vec4(a, 1.0);

  viewCoord = positionView.xyz;
  sunViewPosition = (view * vec4(sunPosition, 1.0)).xyz;

  /* Compute normals. */
  normal = normalize(mat3(transpose(inverse(modelView))) * baseNormal);

  gl_Position = projection * positionView;
}
