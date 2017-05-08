import basic3d, strutils, opengl, mathhelpers, onfailure

type
  VertexShaderObject* = object
    id: GLuint
    filePath: string
  FragmentShaderObject* = object
    id: GLuint
    filePath: string
  ShaderObject* = VertexShaderObject | FragmentShaderObject
  ShaderProgram* = distinct GLuint
  ShaderError* = object of Exception

proc typeName(shader: VertexShaderObject): string = "vertex"
proc typeName(shader: FragmentShaderObject): string = "fragment"

proc recompile*(shader: ShaderObject, preincludes: varargs[string]) =
  var sources = @preincludes
  sources.add(readFile(shader.filePath))

  let stringArray = allocCStringArray(sources)
  defer: deallocCStringArray(stringArray)

  glShaderSource(shader.id, sources.len.GLsizei, stringArray, nil)
  glCompileShader(shader.id)

  var shaderiv: GLint
  glGetShaderiv(shader.id, GL_COMPILE_STATUS, shaderiv.addr)
  if shaderiv != GL_TRUE.GLint:
    glGetShaderiv(shader.id, GL_INFO_LOG_LENGTH, shaderiv.addr)
    var shaderInfo = cast[ptr GLchar](alloc(shaderiv))
    defer: dealloc(shaderInfo)

    glGetShaderInfoLog(shader.id, shaderiv.GLsizei, nil, shaderInfo)

    let msg = shader.typeName & " shader: \"" &
              shader.filePath & "\": " & $shaderInfo
    raise newException(ShaderError, msg)

proc initShader(shader: var ShaderObject,
                filePath: string,
                shaderType: GLenum) =
  if not filePath.endsWith("." & shader.typeName[0..3]):
    let msg = shader.typeName & " shader: \"" & filePath & "\""
    raise newException(ShaderError, "wrong file extension for a " & msg)

  shader.filePath = filePath
  shader.id = glCreateShader(shaderType)
  onFailure glDeleteShader(shader.id):
    shader.recompile()

proc loadVertexShaderObject*(filePath: string): VertexShaderObject =
  initShader(result, filePath, GL_VERTEX_SHADER)

proc loadFragmentShaderObject*(filePath: string): FragmentShaderObject =
  initShader(result, filePath, GL_FRAGMENT_SHADER)

proc destroy*(shader: ShaderObject) =
  glDeleteShader(shader.id)

proc filePath*(shader: ShaderObject): string =
  shader.filePath

proc linkShaderProgram*(vertexShaderObject: VertexShaderObject,
                        fragmentShaderObject: FragmentShaderObject):
                        ShaderProgram =
  let program = glCreateProgram()
  result = program.ShaderProgram

  onFailure glDeleteProgram(program):
    glAttachShader(program, vertexShaderObject.id)
    glAttachShader(program, fragmentShaderObject.id)
    glLinkProgram(program)
    glDetachShader(program, vertexShaderObject.id)
    glDetachShader(program, fragmentShaderObject.id)

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
