import opengl, globject, shaderutils, reloadableshader, shaderwrapper

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

template use*(shader: ReloadableShader, body: untyped) =
  block: declareUseBodyWithShader(shader, body)

template use*(shader: BasicLightShader, body: untyped) =
  block:
    declareShaderWrapperUniformLet(shader)
    declareUseBodyWithShader(shader, body)

template afterReload*(shader: var BasicLightShader, body: untyped) =
  if shader.tryReload():
    use shader:
      body
