vec3 getHeightVec(float x, float z)
{
  return vec3(x, sin(x * 15) * sin(z * 15)/30.0, z);
}
