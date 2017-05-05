import basic3d, strutils, opengl, mathhelpers, onfailure

type
  VertexShader = distinct GLuint
  FragmentShader = distinct GLuint
  ShaderProgram = distinct GLuint
  UniformLocationFloat = distinct GLuint
  UniformLocationVec3 = distinct GLuint
  UniformLocationMat4 = distinct GLuint
  ShaderError* = object of Exception

proc loadShader(path: string,
                shaderType: GLenum,
                shaderName: string): GLuint =
  if not path.endsWith("." & shaderName[0..3]):
    let msg = shaderName & " shader: \"" & path & "\""
    raise newException(ShaderError, "wrong file extension for a " & msg)

  let shader = glCreateShader(shaderType)
  result = shader

  onFailure glDeleteShader(shader):
    let stringArray = allocCStringArray([readFile(path)])
    defer: deallocCStringArray(stringArray)

    glShaderSource(shader, 1, stringArray, nil)
    glCompileShader(shader)

    var shaderiv: GLint
    glGetShaderiv(shader, GL_COMPILE_STATUS, shaderiv.addr)
    if shaderiv != GL_TRUE.GLint:
      glGetShaderiv(shader, GL_INFO_LOG_LENGTH, shaderiv.addr)
      var shaderInfo = cast[ptr GLchar](alloc(shaderiv))
      defer: dealloc(shaderInfo)

      glGetShaderInfoLog(shader, shaderiv.GLsizei, nil, shaderInfo)

      let msg = shaderName & " shader: \"" & path & "\": " & $shaderInfo
      raise newException(ShaderError, msg)

proc loadVertexShader*(path: string): VertexShader =
  loadShader(path, GL_VERTEX_SHADER, "vertex").VertexShader

proc loadFragmentShader*(path: string): FragmentShader =
  loadShader(path, GL_FRAGMENT_SHADER, "fragment").FragmentShader

proc destroy*(shader: VertexShader|FragmentShader) =
  glDeleteShader(shader.GLuint)

proc linkShaderProgram*(vertexShader: VertexShader,
                        fragmentShader: FragmentShader): ShaderProgram =
  let program = glCreateProgram()
  result = program.ShaderProgram

  onFailure glDeleteProgram(program):
    glAttachShader(program, vertexShader.GLuint)
    glAttachShader(program, fragmentShader.GLuint)
    glLinkProgram(program)
    glDetachShader(program, vertexShader.GLuint)
    glDetachShader(program, fragmentShader.GLuint)

    var programiv: GLint
    glGetProgramiv(program, GL_LINK_STATUS, programiv.addr)
    if programiv != GL_TRUE.GLint:
      glGetProgramiv(program, GL_INFO_LOG_LENGTH, programiv.addr)
      var programInfo = cast[ptr GLchar](alloc(programiv))
      defer: dealloc(programInfo)

      glGetProgramInfoLog(program, programiv.GLsizei, nil, programInfo)

      let msg = "failed to link shader: " & $programInfo
      raise newException(ShaderError, msg)

proc loadShaderProgram*(vertexPath: string,
                        fragmentPath: string): ShaderProgram =
  let vertexShader = loadVertexShader(vertexPath)
  defer: vertexShader.destroy()

  let fragmentShader = loadFragmentShader(fragmentPath)
  defer: fragmentShader.destroy()

  linkShaderProgram(vertexShader, fragmentShader)

proc destroy*(program: ShaderProgram) =
  glDeleteProgram(program.GLuint)

template use*(program: ShaderProgram, body: untyped) =
  var previousProgram: GLint
  glGetIntegerv(GL_CURRENT_PROGRAM, previousProgram.addr)

  glUseProgram(program.GLuint)
  try:
    body
  finally:
    glUseProgram(previousProgram.GLuint)

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
