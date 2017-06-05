layout (location = 0) in vec3 position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform float time;

out vec2 fragmentPosition;

void main(void)
{
  fragmentPosition = position.xy;
  vec3 newPosition = position;

  newPosition.z += cos(position.x * 10.0 + time/3.0)/5.0;
  newPosition.y += sin(position.x * 10.0 + time/3.0)/3.0 *
    position.x * position.x;

  gl_Position = projection * view * model * vec4(newPosition, 1.0);
}
