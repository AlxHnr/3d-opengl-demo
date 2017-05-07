import os, times, shader, uniform, onfailure

type
  UniformLocations = object
    model, view, projection: UniformLocationMat4
    lightPosition, lightColor: UniformLocationVec3
  BasicLightShader = object
    vertexShader: VertexShader
    vertexShaderSourceTime: Time
    fragmentShader: FragmentShader
    fragmentShaderSourceTime: Time
    program: ShaderProgram
    uniforms: UniformLocations
  ShaderWrapper* = BasicLightShader

proc resolveUniformLocations(program: ShaderProgram): UniformLocations =
  result.model = program.getUniformLocationMat4("model")
  result.view = program.getUniformLocationMat4("view")
  result.projection = program.getUniformLocationMat4("projection")
  result.lightPosition = program.getUniformLocationVec3("lightPosition")
  result.lightColor = program.getUniformLocationVec3("lightColor")

proc loadFlatMeshShader*(): BasicLightShader =
  result.vertexShader = loadVertexShader("shader/flatMesh.vert")

  onFailure destroy result.vertexShader:
    result.vertexShaderSourceTime =
      result.vertexShader.filePath.getLastModificationTime()
    result.fragmentShader = loadFragmentShader("shader/flatMesh.frag")

    onFailure destroy result.fragmentShader:
      result.fragmentShaderSourceTime =
        result.fragmentShader.filePath.getLastModificationTime()
      result.program =
        linkShaderProgram(result.vertexShader, result.fragmentShader)

      onFailure destroy result.program:
        result.uniforms = result.program.resolveUniformLocations()

proc destroy*(shader: ShaderWrapper) =
  shader.vertexShader.destroy()
  shader.fragmentShader.destroy()
  shader.program.destroy()

proc tryReload*(shader: var ShaderWrapper): bool {.discardable.} =
  let
    vertexSourceTime =
      shader.vertexShader.filePath.getLastModificationTime()
    fragmentSourceTime =
      shader.fragmentShader.filePath.getLastModificationTime()
    vertexHasChanged = shader.vertexShaderSourceTime < vertexSourceTime
    fragmentHasChanged = shader.fragmentShaderSourceTime < fragmentSourceTime

  if vertexHasChanged or fragmentHasChanged:
    shader.vertexShaderSourceTime = vertexSourceTime
    shader.fragmentShaderSourceTime = fragmentSourceTime

    try:
      if vertexHasChanged: shader.vertexShader.recompile()
      if fragmentHasChanged: shader.fragmentShader.recompile()

      let newProgram =
        linkShaderProgram(shader.vertexShader, shader.fragmentShader)

      onFailure destroy newProgram:
        shader.uniforms = newProgram.resolveUniformLocations()

      shader.program.destroy()
      shader.program = newProgram
      result = true
    except ShaderError:
      echo getCurrentExceptionMsg()

template declareShaderWrapperUniformLet*(shader: ShaderWrapper) =
  let `U` {.inject.} = shader.uniforms
template declareUseBodyWithShader*(shader: ShaderWrapper, body: typed) =
  use shader.program: body

proc model*(u: UniformLocations): auto = u.model
proc view*(u: UniformLocations): auto = u.view
proc projection*(u: UniformLocations): auto = u.projection
proc lightPosition*(u: UniformLocations): auto = u.lightPosition
proc lightColor*(u: UniformLocations): auto = u.lightColor
