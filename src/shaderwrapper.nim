import os, times, shaderutils, reloadableshader, uniform, onfailure

type
  UniformLocations = object
    model, view, projection, normalMatrix: UniformLocationMat4
    lightPosition, lightColor: UniformLocationVec3
  BasicLightShader* = object
    reloadableShader: ReloadableShader
    uniforms: UniformLocations

proc resolveUniformLocations(program: ShaderProgram): UniformLocations =
  result.model = program.getUniformLocationMat4("model")
  result.view = program.getUniformLocationMat4("view")
  result.projection = program.getUniformLocationMat4("projection")
  result.normalMatrix = program.getUniformLocationMat4("normalMatrix")
  result.lightPosition = program.getUniformLocationVec3("lightPosition")
  result.lightColor = program.getUniformLocationVec3("lightColor")

template buildCaptureUniformProc(onShaderReload: untyped,
                                 uniforms: untyped) =
  var uniforms: UniformLocations
  let onShaderReload =
    proc(program: ShaderProgram) =
      uniforms = program.resolveUniformLocations()

proc loadBasicLightShader(vertex, fragment: openArray[string]):
                          BasicLightShader =
  buildCaptureUniformProc(onShaderReload, uniforms)
  result.reloadableShader =
    initReloadableShader(vertex, fragment, onShaderReload)
  result.uniforms = uniforms

proc loadFlatMeshShader*(): BasicLightShader =
  loadBasicLightShader(["shader/height.vert",
                        "shader/flatmesh.vert"],
                       ["shader/height.vert",
                        "shader/flatmesh.frag"])

proc loadCurveShader*(): BasicLightShader =
  loadBasicLightShader(["shader/curve.vert"], ["shader/curve.frag"])

proc destroy*(shader: BasicLightShader) =
  shader.reloadableShader.destroy()

proc tryReload*(shader: var BasicLightShader): bool {.discardable.} =
  buildCaptureUniformProc(onShaderReload, uniforms)
  if shader.reloadableShader.tryReload(onShaderReload):
    shader.uniforms = uniforms
    result = true

template declareShaderWrapperUniformLet*(shader: BasicLightShader) =
  let `U` {.inject.} = shader.uniforms
template declareUseBodyWithShader*(shader: BasicLightShader, body: typed) =
  use shader.reloadableShader: body

proc model*(u: UniformLocations): auto = u.model
proc view*(u: UniformLocations): auto = u.view
proc projection*(u: UniformLocations): auto = u.projection
proc normalMatrix*(u: UniformLocations): auto = u.normalMatrix
proc lightPosition*(u: UniformLocations): auto = u.lightPosition
proc lightColor*(u: UniformLocations): auto = u.lightColor
