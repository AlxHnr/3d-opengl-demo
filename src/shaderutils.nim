import basic3d, strutils, opengl, mathhelpers, onfailure

type
  VertexShaderObject* = distinct GLuint
  FragmentShaderObject* = distinct GLuint
  ShaderObject* = VertexShaderObject | FragmentShaderObject
  ShaderProgram* = distinct GLuint
  ShaderError* = object of Exception

proc typeName(shader: VertexShaderObject): string = "vertex"
proc typeName(shader: FragmentShaderObject): string = "fragment"

proc loadSources(paths: openArray[string], typeName: string):
                 TaintedString =
  if paths.len == 0:
    let msg = "no " & typeName & " shader source files specified"
    raise newException(ShaderError, msg)

  try:
    result = "#version 330 core\n"
    for path in paths: result.add(path.readFile)
  except IOError:
    let msg = typeName & " shader: " & getCurrentExceptionMsg()
    raise newException(ShaderError, msg)

proc recompile*(shader: ShaderObject, paths: openArray[string]) =
  let
    source = paths.loadSources(shader.typeName)
    shaderID = shader.GLuint

  let stringArray = allocCStringArray([source])
  defer: deallocCStringArray(stringArray)

  glShaderSource(shaderID, 1, stringArray, nil)
  glCompileShader(shaderID)

  var shaderiv: GLint
  glGetShaderiv(shaderID, GL_COMPILE_STATUS, shaderiv.addr)
  if shaderiv != GL_TRUE.GLint:
    glGetShaderiv(shaderID, GL_INFO_LOG_LENGTH, shaderiv.addr)
    var shaderInfo = cast[ptr GLchar](alloc(shaderiv))
    defer: dealloc(shaderInfo)

    glGetShaderInfoLog(shaderID, shaderiv.GLsizei, nil, shaderInfo)

    let msg = shader.typeName & " shader: \"" &
              paths[paths.high] & "\": " & $shaderInfo
    raise newException(ShaderError, msg)

proc initShader(shader: var ShaderObject,
                paths: openArray[string],
                shaderType: GLenum) =
  shader = glCreateShader(shaderType).ShaderObject
  onFailure glDeleteShader(shader.GLuint):
    shader.recompile(paths)

proc initVertexShaderObject*(paths: openArray[string]):
                             VertexShaderObject =
  initShader(result, paths, GL_VERTEX_SHADER)

proc initFragmentShaderObject*(paths: openArray[string]):
                               FragmentShaderObject =
  initShader(result, paths, GL_FRAGMENT_SHADER)

proc destroy*(shader: VertexShaderObject) =
  glDeleteShader(shader.GLuint)
proc destroy*(shader: FragmentShaderObject) =
  glDeleteShader(shader.GLuint)

proc linkShaderProgram*(vertexShaderObject: VertexShaderObject,
                        fragmentShaderObject: FragmentShaderObject):
                        ShaderProgram =
  let program = glCreateProgram()
  result = program.ShaderProgram

  onFailure glDeleteProgram(program):
    glAttachShader(program, vertexShaderObject.GLuint)
    glAttachShader(program, fragmentShaderObject.GLuint)
    glLinkProgram(program)
    glDetachShader(program, vertexShaderObject.GLuint)
    glDetachShader(program, fragmentShaderObject.GLuint)

    var programiv: GLint
    glGetProgramiv(program, GL_LINK_STATUS, programiv.addr)
    if programiv != GL_TRUE.GLint:
      glGetProgramiv(program, GL_INFO_LOG_LENGTH, programiv.addr)
      var programInfo = cast[ptr GLchar](alloc(programiv))
      defer: dealloc(programInfo)

      glGetProgramInfoLog(program, programiv.GLsizei, nil, programInfo)

      let msg = "failed to link shader: " & $programInfo
      raise newException(ShaderError, msg)

proc destroy*(program: ShaderProgram) =
  glDeleteProgram(program.GLuint)
