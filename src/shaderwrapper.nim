import shader, uniform, onfailure

type
  BasicLightShader = object
    vertexShader: VertexShader
    fragmentShader: FragmentShader
    program: ShaderProgram
    model, view, projection: UniformLocationMat4
    lightPosition, lightColor: UniformLocationVec3
  MVPShaderWrapper = BasicLightShader
  LightShaderWrapper = BasicLightShader
  ShaderWrapper = BasicLightShader

proc loadFlatMeshShader*(): BasicLightShader =
  result.vertexShader = loadVertexShader("shader/flatMesh.vert")
  onFailure destroy result.vertexShader:
    result.fragmentShader = loadFragmentShader("shader/flatMesh.frag")
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

proc model*(w: MVPShaderWrapper): UniformLocationMat4 = w.model
proc view*(w: MVPShaderWrapper): UniformLocationMat4 = w.view
proc projection*(w: MVPShaderWrapper): UniformLocationMat4 = w.projection
proc lightPosition*(w: LightShaderWrapper): UniformLocationVec3 = w.lightPosition
proc lightColor*(w: LightShaderWrapper): UniformLocationVec3 = w.lightColor
