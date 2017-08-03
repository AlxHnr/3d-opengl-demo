layout (location = 0) in vec3 position;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform vec3 lightPosition;

out vec3 viewCoord, lightViewPosition, normal;

void main(void)
{
  vec2 c0 = vec2(-0.7, -0.8);
  vec2 c1 = vec2(-1.0,  1.0);
  vec2 c2 = vec2( 0.6,  0.6);
  vec2 c3 = vec2( 0.8, -0.5);
  float t = (position.x + 1.0)/2.0;

  vec2 _01   = mix(c0,    c1,    t);
  vec2 _12   = mix(c1,    c2,    t);
  vec2 _23   = mix(c2,    c3,    t);
  vec2 _0112 = mix(_01,   _12,   t);
  vec2 _1223 = mix(_12,   _23,   t);
  vec2 pos   = mix(_0112, _1223, t);

  vec2 direction = _1223 - _0112;
  float slope = direction.y/direction.x;
  if(slope < -5.0)
  {
    slope = -slope;
  }

  vec2 tangentHorizontal = normalize(vec2(-1.0, slope));

  float cosHorizontal = tangentHorizontal.x;
  float sinHorizontal = tangentHorizontal.y;
  mat3 horizontalRotation = mat3(cosHorizontal, -sinHorizontal, 0,
                                 sinHorizontal, cosHorizontal,  0,
                                 0,             0,              1);

  vec3 rotatedPosition = horizontalRotation * vec3(0.0, position.y, position.z);
  normal = -normalize(rotatedPosition);
  rotatedPosition.x += position.x;
  rotatedPosition.y += pos.y;

  vec4 positionView = view * model * vec4(rotatedPosition, 1.0);

  viewCoord = positionView.xyz;
  lightViewPosition = (view * vec4(lightPosition, 1.0)).xyz;

  gl_Position = projection * positionView;
}
