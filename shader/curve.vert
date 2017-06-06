layout (location = 0) in vec3 position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 lightPosition;

out vec3 viewCoord, lightViewPosition, fragPosition;

void main(void)
{
  vec4 positionView = view * model * vec4(position, 1.0);

  viewCoord = positionView.xyz;
  lightViewPosition = (view * vec4(lightPosition, 1.0)).xyz;

  fragPosition = -position;
  fragPosition.x = 0;

  gl_Position = projection * positionView;
}
