#version 330 core

in vec2 fragmentPosition;

out vec4 color;

void main(void)
{
  int max_iteration = 300;

  int iteration = 0;
  float x = 0.0;
  float y = 0.0;
  float x2 = x * x;
  float y2 = y * y;
  while((x2 + y2 < (1 << 16)) && iteration < max_iteration)
  {
    y = 2 * x * y + fragmentPosition.y;
    x = x2 - y2 + fragmentPosition.x;

    x2 = x * x;
    y2 = y * y;
    iteration++;
  }

  if(iteration == max_iteration)
  {
    color = vec4(0.0, 0.0, 0.0, 1.0);
  }
  else
  {
    float percent = float(iteration)/float(max_iteration);
    color = vec4(mod(percent + 0.33, 1.0),
                 mod(percent + 1.234, 1.0),
                 mod(percent + 0.67, 1.0),
                 1.0);
  }
}
