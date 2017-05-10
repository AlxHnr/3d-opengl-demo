import os, sequtils, times, shaderutils, onfailure

type
  ShaderProgramProc = proc(program: ShaderProgram)
  SourcePathInfo = tuple
    path: string
    time: Time
  SourcePathInfoSeq = seq[SourcePathInfo]
  ReloadableShader* = object
    vertexShaderObject: VertexShaderObject
    vertexSourcePathInfos: SourcePathInfoSeq
    fragmentShaderObject: FragmentShaderObject
    fragmentSourcePathInfos: SourcePathInfoSeq
    program: ShaderProgram

proc ignoreArgs(program: ShaderProgram) {.procvar.} = discard program
proc init(infoSeq: var SourcePathInfoSeq, paths: openArray[string]) =
  infoSeq = newSeq[SourcePathInfo](paths.len)
  for i, path in paths:
    infoSeq[i].path = path
    infoSeq[i].time = path.getLastModificationTime()

proc initReloadableShader*(vertexSourcePaths: openArray[string],
                           fragmentSourcePaths: openArray[string],
                           onShaderReload: ShaderProgramProc = ignoreArgs):
                           ReloadableShader =
  result.vertexShaderObject = initVertexShaderObject(vertexSourcePaths)

  onFailure destroy result.vertexShaderObject:
    result.vertexSourcePathInfos.init(vertexSourcePaths)
    result.fragmentShaderObject =
      initFragmentShaderObject(fragmentSourcePaths)

    onFailure destroy result.fragmentShaderObject:
      result.fragmentSourcePathInfos.init(fragmentSourcePaths)
      result.program = linkShaderProgram(result.vertexShaderObject,
                                         result.fragmentShaderObject)

      onFailure destroy result.program:
        onShaderReload(result.program)

proc destroy*(shader: ReloadableShader) =
  shader.vertexShaderObject.destroy()
  shader.fragmentShaderObject.destroy()
  shader.program.destroy()

proc updateChangeTime(infoSeq: var SourcePathInfoSeq): bool =
  for i in 0..infoSeq.high:
    let time = infoSeq[i].path.getLastModificationTime()
    if time != infoSeq[i].time:
      infoSeq[i].time = time
      result = true

proc gatherSources(infoSeq: SourcePathInfoSeq): seq[string] =
  infoSeq.map do (info: SourcePathInfo) -> string: info.path

proc tryReload*(shader: var ReloadableShader,
                onShaderReload: ShaderProgramProc = ignoreArgs):
                bool {.discardable.} =
  let
    vertexHasChanged = shader.vertexSourcePathInfos.updateChangeTime()
    fragmentHasChanged = shader.fragmentSourcePathInfos.updateChangeTime()

  if vertexHasChanged or fragmentHasChanged:
    try:
      if vertexHasChanged:
        let vertexSources = shader.vertexSourcePathInfos.gatherSources()
        shader.vertexShaderObject.recompile(vertexSources)

      if fragmentHasChanged:
        let fragmentSources = shader.fragmentSourcePathInfos.gatherSources()
        shader.fragmentShaderObject.recompile(fragmentSources)

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
