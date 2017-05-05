import basic3d, opengl, shader, mathhelpers

type
  UniformLocationFloat = distinct GLuint
  UniformLocationVec3 = distinct GLuint
  UniformLocationMat4 = distinct GLuint

proc getUniformLocation(program: ShaderProgram, name: string): GLint =
  result = glGetUniformLocation(program.GLuint, name)
  if result == -1:
    let msg = "uniform location doesn't exist: \"" & name & "\""
    raise newException(ShaderError, msg)

proc getUniformLocationFloat*(program: ShaderProgram, name: string):
                              UniformLocationFloat =
  program.getUniformLocation(name).UniformLocationFloat

proc updateWith*(location: UniformLocationFloat, value: float) =
  glUniform1f(location.GLint, value)

proc getUniformLocationVec3*(program: ShaderProgram, name: string):
                             UniformLocationVec3 =
  program.getUniformLocation(name).UniformLocationVec3

proc updateWith*(location: UniformLocationVec3; vector: Vector3d) =
  glUniform3f(location.GLint, vector.x, vector.y, vector.z)

proc getUniformLocationMat4*(program: ShaderProgram, name: string):
                             UniformLocationMat4 =
  program.getUniformLocation(name).UniformLocationMat4

proc updateWith*(location: UniformLocationMat4, matrix: var Matrix4) =
  glUniformMatrix4fv(location.GLint, 1, GL_FALSE, matrix[0].addr)
