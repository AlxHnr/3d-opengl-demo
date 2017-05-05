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

proc loadFlatMeshShader*(): BasicLightShader =
  result.vertexShader = loadVertexShader("shader/flatMesh.vert")
  result.vertexShaderSourceTime =
    result.vertexShader.filePath.getLastModificationTime()

  onFailure destroy result.vertexShader:
    result.fragmentShader = loadFragmentShader("shader/flatMesh.frag")
    result.fragmentShaderSourceTime =
      result.fragmentShader.filePath.getLastModificationTime()

    onFailure destroy result.fragmentShader:
      result.program =
        linkShaderProgram(result.vertexShader, result.fragmentShader)
      onFailure destroy result.program:
        result.model = result.program.getUniformLocationMat4("model")
        result.view = result.program.getUniformLocationMat4("view")
        result.projection =
          result.program.getUniformLocationMat4("projection")
        result.lightPosition =
          result.program.getUniformLocationVec3("lightPosition")
        result.lightColor =
          result.program.getUniformLocationVec3("lightColor")

proc destroy*(shader: ShaderWrapper) =
  shader.vertexShader.destroy()
  shader.fragmentShader.destroy()
  shader.program.destroy()

template use*(shader: ShaderWrapper, body: untyped) =
  use shader.program:
    body

proc checkAndReloadChanges*(shader: var ShaderWrapper): bool =
  let
    vertexSourceTime =
      shader.vertexShader.filePath.getLastModificationTime()
    fragmentSourceTime =
      shader.fragmentShader.filePath.getLastModificationTime()
    vertexHasChanged = shader.vertexShaderSourceTime < vertexSourceTime
    fragmentHasChanged = shader.fragmentShaderSourceTime < fragmentSourceTime

  if vertexHasChanged or fragmentHasChanged:
    try:
      if vertexHasChanged:
        shader.vertexShaderSourceTime = vertexSourceTime
        shader.vertexShader.recompile()
      if fragmentHasChanged:
        shader.fragmentShaderSourceTime = fragmentSourceTime
        shader.fragmentShader.recompile()

      let newProgram =
        linkShaderProgram(shader.vertexShader, shader.fragmentShader)
      shader.program.destroy()
      shader.program = newProgram
      result = true
    except ShaderError:
      echo getCurrentExceptionMsg()

template tryReload*(shader: var ShaderWrapper, body: untyped) =
  if shader.checkAndReloadChanges():
    use shader:
      body

proc model*(w: MVPShaderWrapper): UniformLocationMat4 = w.model
proc view*(w: MVPShaderWrapper): UniformLocationMat4 = w.view
proc projection*(w: MVPShaderWrapper): UniformLocationMat4 = w.projection
proc lightPosition*(w: LightShaderWrapper): UniformLocationVec3 = w.lightPosition
proc lightColor*(w: LightShaderWrapper): UniformLocationVec3 = w.lightColor
