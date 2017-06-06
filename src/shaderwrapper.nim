import os, times, shaderutils, reloadableshader, uniform, onfailure

type
  UniformLocations = object
    model, view, projection, normalMatrix: UniformLocationMat4
    lightPosition, lightColor: UniformLocationVec3
  BasicLightShader* = object
    reloadableShader: ReloadableShader
    uniforms: UniformLocations

proc destroy*(shader: BasicLightShader) =
  shader.reloadableShader.destroy()

proc updateUniforms(shader: var BasicLightShader) =
  let program = shader.reloadableShader.program
  shader.uniforms.model = program.getUniformLocationMat4("model")
  shader.uniforms.view = program.getUniformLocationMat4("view")
  shader.uniforms.projection = program.getUniformLocationMat4("projection")
  shader.uniforms.normalMatrix = program.getUniformLocationMat4("normalMatrix")
  shader.uniforms.lightPosition = program.getUniformLocationVec3("lightPosition")
  shader.uniforms.lightColor = program.getUniformLocationVec3("lightColor")

proc loadBasicLightShader(vertex, fragment: openArray[string]):
                          BasicLightShader =
  result.reloadableShader = initReloadableShader(vertex, fragment)
  result.updateUniforms()

proc loadFlatMeshShader*(): BasicLightShader =
  loadBasicLightShader(["shader/height.vert",
                        "shader/flatmesh.vert"],
                       ["shader/height.vert",
                        "shader/flatmesh.frag"])

proc loadCurveShader*(): BasicLightShader =
  loadBasicLightShader(["shader/curve.vert"], ["shader/curve.frag"])

proc tryReload*(shader: var BasicLightShader): bool {.discardable.} =
  if shader.reloadableShader.tryReload():
    shader.updateUniforms()
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
