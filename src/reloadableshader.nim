import os, times, shader, onfailure

type
  OnShaderReloadProc = proc(program: ShaderProgram)
  ReloadableShader* = object
    vertexShader: VertexShader
    vertexShaderSourceTime: Time
    fragmentShader: FragmentShader
    fragmentShaderSourceTime: Time
    program: ShaderProgram

proc initReloadableShader*(vertexSourcePath, fragmentSourcePath: string,
                           onShaderReload: OnShaderReloadProc):
                           ReloadableShader =
  result.vertexShader = loadVertexShader(vertexSourcePath)

  onFailure destroy result.vertexShader:
    result.vertexShaderSourceTime =
      result.vertexShader.filePath.getLastModificationTime()
    result.fragmentShader = loadFragmentShader(fragmentSourcePath)

    onFailure destroy result.fragmentShader:
      result.fragmentShaderSourceTime =
        result.fragmentShader.filePath.getLastModificationTime()
      result.program =
        linkShaderProgram(result.vertexShader, result.fragmentShader)

      onFailure destroy result.program:
        onShaderReload(result.program)

proc destroy*(shader: ReloadableShader) =
  shader.vertexShader.destroy()
  shader.fragmentShader.destroy()
  shader.program.destroy()

proc tryReload*(shader: var ReloadableShader,
                onShaderReload: OnShaderReloadProc):
                bool {.discardable.} =
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
        onShaderReload(newProgram)

      shader.program.destroy()
      shader.program = newProgram
      result = true
    except ShaderError:
      echo getCurrentExceptionMsg()

template declareUseBodyWithShader*(shader: ReloadableShader, body: typed) =
  use shader.program: body
