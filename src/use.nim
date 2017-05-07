import opengl, globject, shader, shaderwrapper

template use*(vao: VertexArrayObject, body: untyped) =
  var previousVao: GLint
  glGetIntegerv(GL_VERTEX_ARRAY_BINDING, previousVao.addr)

  glBindVertexArray(vao.GLuint)
  try:
    body
  finally:
    glBindVertexArray(previousVao.GLuint)

template use*(program: ShaderProgram, body: untyped) =
  var previousProgram: GLint
  glGetIntegerv(GL_CURRENT_PROGRAM, previousProgram.addr)

  glUseProgram(program.GLuint)
  try:
    body
  finally:
    glUseProgram(previousProgram.GLuint)

template use*(shader: ShaderWrapper, body: untyped) =
  block:
    declareShaderWrapperUniformLet(shader)
    declareUseBodyWithShader(shader, body)

template afterReload*(shader: var ShaderWrapper, body: untyped) =
  if shader.tryReload():
    use shader:
      body
