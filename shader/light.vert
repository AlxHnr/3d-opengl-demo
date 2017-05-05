#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 normalAttribute;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 lightPosition;

out vec3 localCoord, worldCoord, viewCoord, lightViewPosition, normal;

void main(void)
{
  vec4 positionWorld = model * vec4(position, 1.0);
  vec4 positionView = view * positionWorld;

  localCoord = position;
  worldCoord = positionWorld.xyz;
  viewCoord = positionView.xyz;
  lightViewPosition = (view * vec4(lightPosition, 1.0)).xyz;
  normal = normalize(mat3(transpose(inverse(view * model))) * normalAttribute);

  gl_Position = projection * positionView;
}
