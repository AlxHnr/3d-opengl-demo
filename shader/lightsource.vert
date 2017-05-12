layout (location = 0) in vec2 position;

uniform mat4 modelView, projection;

void main(void)
{
  gl_Position = projection * modelView * vec4(position, 0.0, 1.0);
}
