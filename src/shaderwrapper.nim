import
  os, times, opengl,
  shaderutils, reloadableshader, uniform, onfailure

type
  UniformLocations* = object
    model, view, projection, normalMatrix: UniformLocationMat4
    lightPosition, lightColor, color: UniformLocationVec3
    bezierPoints: UniformLocationMat4
  UniformProc = proc(uniforms: UniformLocations)
  ShaderWrapper* = object
    reloadableShader: ReloadableShader
    uniforms: UniformLocations
    uniformProc: UniformProc

proc updateUniforms(shader: var ShaderWrapper) =
  let program = shader.reloadableShader.program
  shader.uniforms.model = program.getUniformLocationMat4("model")
  shader.uniforms.view = program.getUniformLocationMat4("view")
  shader.uniforms.projection = program.getUniformLocationMat4("projection")
  shader.uniforms.normalMatrix = program.getUniformLocationMat4("normalMatrix")
  shader.uniforms.lightPosition = program.getUniformLocationVec3("lightPosition")
  shader.uniforms.lightColor = program.getUniformLocationVec3("lightColor")
  shader.uniforms.color = program.getUniformLocationVec3("color")
  shader.uniforms.bezierPoints = program.getUniformLocationMat4("bezierPoints")

  var previousProgram: GLint
  glGetIntegerv(GL_CURRENT_PROGRAM, previousProgram.addr)
  defer: glUseProgram(previousProgram.GLuint)

  glUseProgram(program.GLuint)
  shader.uniformProc(shader.uniforms)

proc ignore(uniforms: UniformLocations) = discard uniforms
proc loadShaderWrapper*(vertex, fragment: openArray[string],
                        uniformProc: UniformProc = ignore):
                        ShaderWrapper =
  result.reloadableShader = initReloadableShader(vertex, fragment)
  result.uniformProc = uniformProc
  result.updateUniforms()

proc destroy*(shader: ShaderWrapper) =
  shader.reloadableShader.destroy()

proc tryReload*(shader: var ShaderWrapper): bool {.discardable.} =
  if shader.reloadableShader.tryReload():
    shader.updateUniforms()
    result = true

template declareShaderWrapperUniformLet*(shader: ShaderWrapper) =
  let `U` {.inject.} = shader.uniforms
template declareUseBodyWithShader*(shader: ShaderWrapper, body: typed) =
  use shader.reloadableShader: body

proc model*(u: UniformLocations): auto = u.model
proc view*(u: UniformLocations): auto = u.view
proc projection*(u: UniformLocations): auto = u.projection
proc normalMatrix*(u: UniformLocations): auto = u.normalMatrix
proc lightPosition*(u: UniformLocations): auto = u.lightPosition
proc lightColor*(u: UniformLocations): auto = u.lightColor
proc color*(u: UniformLocations): auto = u.color
proc bezierPoints*(u: UniformLocations): auto = u.bezierPoints
