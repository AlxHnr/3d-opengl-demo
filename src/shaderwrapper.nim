import os, times, shader, uniform, onfailure

type
  BasicLightShader = object
    vertexShader: VertexShader
    vertexShaderSourceTime: Time
    fragmentShader: FragmentShader
    fragmentShaderSourceTime: Time
    program: ShaderProgram
    model, view, projection: UniformLocationMat4
    lightPosition, lightColor: UniformLocationVec3
  MVPShaderWrapper = BasicLightShader
  LightShaderWrapper = BasicLightShader
  ShaderWrapper = BasicLightShader

proc tryUpdateUniforms(shader: var ShaderWrapper, program: ShaderProgram) =
  let
    modelUniform = program.getUniformLocationMat4("model")
    viewUniform = program.getUniformLocationMat4("view")
    projectionUniform = program.getUniformLocationMat4("projection")
    lightPositionUniform = program.getUniformLocationVec3("lightPosition")
    lightColorUniform = program.getUniformLocationVec3("lightColor")

  shader.model = modelUniform
  shader.view = viewUniform
  shader.projection = projectionUniform
  shader.lightPosition = lightPositionUniform
  shader.lightColor = lightColorUniform

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
        result.tryUpdateUniforms(result.program)

proc destroy*(shader: ShaderWrapper) =
  shader.vertexShader.destroy()
  shader.fragmentShader.destroy()
  shader.program.destroy()

template use*(shader: ShaderWrapper, body: untyped) =
  use shader.program:
    body

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
        shader.tryUpdateUniforms(newProgram)

      shader.program.destroy()
      shader.program = newProgram
      result = true
    except ShaderError:
      echo getCurrentExceptionMsg()

template tryReload*(shader: var ShaderWrapper, body: untyped) =
  if shader.tryReload():
    use shader:
      body

proc model*(w: MVPShaderWrapper): UniformLocationMat4 = w.model
proc view*(w: MVPShaderWrapper): UniformLocationMat4 = w.view
proc projection*(w: MVPShaderWrapper): UniformLocationMat4 = w.projection
proc lightPosition*(w: LightShaderWrapper): UniformLocationVec3 = w.lightPosition
proc lightColor*(w: LightShaderWrapper): UniformLocationVec3 = w.lightColor
