import shaderutils, shaderprogramproc, onfailure
export destroy

proc initShader*(vertexSourcePaths: openArray[string],
                 fragmentSourcePaths: openArray[string],
                 onShaderReload: ShaderProgramProc = ignoreArgs):
                 ShaderProgram =
  let vertexShaderObject = initVertexShaderObject(vertexSourcePaths)
  defer: vertexShaderObject.destroy()

  let fragmentShaderObject = initfragmentShaderObject(fragmentSourcePaths)
  defer: fragmentShaderObject.destroy()

  result = linkShaderProgram(vertexShaderObject, fragmentShaderObject)
  onFailure destroy result:
    onShaderReload(result)
