layout (location = 0) in vec3 position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec2 fragmentPosition;

void main(void)
{
  fragmentPosition = position.xy;
  vec3 newPosition = position;

  newPosition.y += position.x * position.x * position.x;

  gl_Position = projection * view * model * vec4(newPosition, 1.0);
}
