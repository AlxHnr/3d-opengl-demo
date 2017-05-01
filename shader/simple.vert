#version 330 core

layout (location = 0) in vec3 position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec3 localCoords, worldCoords;

void main(void)
{
  vec4 positionWorld = model * vec4(position, 1.0);

  localCoords = position;
  worldCoords = positionWorld.xyz;

  gl_Position = projection * view * positionWorld;
}
