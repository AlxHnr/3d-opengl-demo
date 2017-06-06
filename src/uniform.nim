import options, basic3d, opengl, shaderutils, mathhelpers

type
  UniformLocationFloat* = object
    location: Option[GLint]
  UniformLocationVec3* = object
    location: Option[GLint]
  UniformLocationMat4* = object
    location: Option[GLint]

proc getUniformLocation(program: ShaderProgram, name: string):
                        Option[GLint] =
  let location = glGetUniformLocation(program.GLuint, name)
  if location == -1:
    stderr.write("uniform location doesn't exist: \"" & name & "\"\n")
  else:
    result = some(location)

proc getUniformLocationFloat*(program: ShaderProgram, name: string):
                              UniformLocationFloat =
  result.location = program.getUniformLocation(name)

proc updateWith*(uniform: UniformLocationFloat, value: float) =
  if uniform.location.isSome:
    glUniform1f(uniform.location.get, value)

proc getUniformLocationVec3*(program: ShaderProgram, name: string):
                             UniformLocationVec3 =
  result.location = program.getUniformLocation(name)

proc updateWith*(uniform: UniformLocationVec3; vector: Vector3d) =
  if uniform.location.isSome:
    glUniform3f(uniform.location.get, vector.x, vector.y, vector.z)

proc getUniformLocationMat4*(program: ShaderProgram, name: string):
                             UniformLocationMat4 =
  result.location = program.getUniformLocation(name)

proc updateWith*(uniform: UniformLocationMat4, matrix: var Matrix4) =
  if uniform.location.isSome:
    glUniformMatrix4fv(uniform.location.get, 1, GL_FALSE, matrix[0].addr)

proc updateWith*(uniform: UniformLocationMat4, matrix3d: Matrix3d) =
  var matrix: Matrix4
  matrix.setTo(matrix3d)
  uniform.updateWith(matrix)
