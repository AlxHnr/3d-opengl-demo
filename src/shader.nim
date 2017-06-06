import shaderutils, onfailure
export destroy

proc initShader*(vertexSourcePaths: openArray[string],
                 fragmentSourcePaths: openArray[string]):
                 ShaderProgram =
  let vertexShaderObject = initVertexShaderObject(vertexSourcePaths)
  defer: vertexShaderObject.destroy()

  let fragmentShaderObject = initfragmentShaderObject(fragmentSourcePaths)
  defer: fragmentShaderObject.destroy()

  linkShaderProgram(vertexShaderObject, fragmentShaderObject)
