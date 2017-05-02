#version 330 core

layout (location = 0) in vec3 position;
layout (location = 1) in vec3 normalAttribute;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec3 localCoord, worldCoord, normal;

void main(void)
{
  vec4 positionWorld = model * vec4(position, 1.0);

  localCoord = position;
  worldCoord = positionWorld.xyz;
  normal = normalize(mat3(transpose(inverse(model))) * normalAttribute);

  gl_Position = projection * view * positionWorld;
}
