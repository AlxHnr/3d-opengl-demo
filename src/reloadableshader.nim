import os, times, shaderutils, onfailure

type
  ShaderProgramProc = proc(program: ShaderProgram)
  ReloadableShader* = object
    vertexShaderObject: VertexShaderObject
    vertexShaderSourceTime: Time
    fragmentShaderObject: FragmentShaderObject
    fragmentShaderSourceTime: Time
    program: ShaderProgram

proc ignoreArgs(program: ShaderProgram) {.procvar.} = discard program

proc initReloadableShader*(vertexSourcePath, fragmentSourcePath: string,
                           onShaderReload: ShaderProgramProc = ignoreArgs):
                           ReloadableShader =
  result.vertexShaderObject = loadVertexShaderObject(vertexSourcePath)

  onFailure destroy result.vertexShaderObject:
    result.vertexShaderSourceTime =
      result.vertexShaderObject.filePath.getLastModificationTime()
    result.fragmentShaderObject =
      loadFragmentShaderObject(fragmentSourcePath)

    onFailure destroy result.fragmentShaderObject:
      result.fragmentShaderSourceTime =
        result.fragmentShaderObject.filePath.getLastModificationTime()
      result.program =
        linkShaderProgram(result.vertexShaderObject,
                          result.fragmentShaderObject)

      onFailure destroy result.program:
        onShaderReload(result.program)

proc destroy*(shader: ReloadableShader) =
  shader.vertexShaderObject.destroy()
  shader.fragmentShaderObject.destroy()
  shader.program.destroy()

proc tryReload*(shader: var ReloadableShader,
                onShaderReload: ShaderProgramProc = ignoreArgs):
                bool {.discardable.} =
  let
    vertexSourceTime =
      shader.vertexShaderObject.filePath.getLastModificationTime()
    fragmentSourceTime =
      shader.fragmentShaderObject.filePath.getLastModificationTime()
    vertexHasChanged = shader.vertexShaderSourceTime < vertexSourceTime
    fragmentHasChanged = shader.fragmentShaderSourceTime < fragmentSourceTime

  if vertexHasChanged or fragmentHasChanged:
    shader.vertexShaderSourceTime = vertexSourceTime
    shader.fragmentShaderSourceTime = fragmentSourceTime

    try:
      if vertexHasChanged: shader.vertexShaderObject.recompile()
      if fragmentHasChanged: shader.fragmentShaderObject.recompile()

      let newProgram = linkShaderProgram(shader.vertexShaderObject,
                                         shader.fragmentShaderObject)

      onFailure destroy newProgram:
        onShaderReload(newProgram)

      shader.program.destroy()
      shader.program = newProgram
      result = true
    except ShaderError:
      echo getCurrentExceptionMsg()

template declareUseBodyWithShader*(shader: ReloadableShader, body: typed) =
  use shader.program: body
