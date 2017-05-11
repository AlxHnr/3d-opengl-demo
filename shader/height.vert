vec3 getHeightVec(float x, float z)
{
  return vec3(x, sin(x * 5) * cos(z * 5)/5.0, z);
}
