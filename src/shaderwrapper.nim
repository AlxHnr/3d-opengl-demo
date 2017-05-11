import os, times, shaderutils, reloadableshader, uniform, onfailure

type
  UniformLocations = object
    model, view, projection: UniformLocationMat4
    lightPosition, lightColor: UniformLocationVec3
  BasicLightShader = object
    reloadableShader: ReloadableShader
    uniforms: UniformLocations
  ShaderWrapper* = BasicLightShader

proc resolveUniformLocations(program: ShaderProgram): UniformLocations =
  result.model = program.getUniformLocationMat4("model")
  result.view = program.getUniformLocationMat4("view")
  result.projection = program.getUniformLocationMat4("projection")
  result.lightPosition = program.getUniformLocationVec3("lightPosition")
  result.lightColor = program.getUniformLocationVec3("lightColor")

template buildCaptureUniformProc(onShaderReload: untyped,
                                 uniforms: untyped) =
  var uniforms: UniformLocations
  let onShaderReload =
    proc(program: ShaderProgram) =
      uniforms = program.resolveUniformLocations()

proc loadFlatMeshShader*(): BasicLightShader =
  buildCaptureUniformProc(onShaderReload, uniforms)
  result.reloadableShader =
    initReloadableShader(["shader/flatmesh.vert"],
                         ["shader/flatmesh.frag"],
                         onShaderReload)
  result.uniforms = uniforms

proc destroy*(shader: ShaderWrapper) =
  shader.reloadableShader.destroy()

proc tryReload*(shader: var ShaderWrapper): bool {.discardable.} =
  buildCaptureUniformProc(onShaderReload, uniforms)
  if shader.reloadableShader.tryReload(onShaderReload):
    shader.uniforms = uniforms
    result = true

template declareShaderWrapperUniformLet*(shader: ShaderWrapper) =
  let `U` {.inject.} = shader.uniforms
template declareUseBodyWithShader*(shader: ShaderWrapper, body: typed) =
  use shader.reloadableShader: body

proc model*(u: UniformLocations): auto = u.model
proc view*(u: UniformLocations): auto = u.view
proc projection*(u: UniformLocations): auto = u.projection
proc lightPosition*(u: UniformLocations): auto = u.lightPosition
proc lightColor*(u: UniformLocations): auto = u.lightColor
