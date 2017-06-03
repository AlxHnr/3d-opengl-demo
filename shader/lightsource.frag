out vec4 finalColor;

uniform vec3 color;

void main(void)
{
  finalColor = vec4(color, 1.0);
}
