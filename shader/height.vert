vec3 getHeightVec(float x, float z)
{
  return vec3(x, sin(x * 15) * cos(z * 15)/15.0, z);
}
