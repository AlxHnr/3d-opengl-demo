import opengl

type
  ArrayBuffer = distinct GLuint
  VertexArrayObject = distinct GLuint

proc toFloat32Seq(a: varargs[float]): seq[float32] =
  var a32 = newSeq[float32](a.len)
  for i, v in a:
    a32[i] = v
  a32

proc initArrayBuffer*(vertices: varargs[float]): ArrayBuffer =
  var arrayBuffer: GLuint
  glGenBuffers(1, arrayBuffer.addr)
  result = arrayBuffer.ArrayBuffer

  try:
    var vertices32 = vertices.toFloat32Seq()
    glBindBuffer(GL_ARRAY_BUFFER, arrayBuffer)
    glBufferData(GL_ARRAY_BUFFER,
                 vertices32.len * float32.sizeof,
                 vertices32[0].addr, GL_STATIC_DRAW)
    glBindBuffer(GL_ARRAY_BUFFER, 0)
  except:
    glDeleteBuffers(1, arrayBuffer.addr)
    raise

proc destroy*(buffer: ArrayBuffer) =
  var bufferVar = buffer.GLuint
  glDeleteBuffers(1, bufferVar.addr)

proc bindBuffer*(buffer: ArrayBuffer) =
  glBindBuffer(GL_ARRAY_BUFFER, buffer.GLuint)

proc unbindBuffer*(buffer: ArrayBuffer) =
  glBindBuffer(GL_ARRAY_BUFFER, 0)

proc initVertexArrayObject*(): VertexArrayObject =
  var vao: GLuint
  glGenVertexArrays(1, vao.addr)
  vao.VertexArrayObject

proc destroy*(vao: VertexArrayObject) =
  var vaoVar = vao.GLuint
  glDeleteVertexArrays(1, vaoVar.addr)

template withVertexArrayObject*(vao: VertexArrayObject,
                                body: untyped): typed =
  glBindVertexArray(vao.GLuint)
  try:
    body
  finally:
    glBindVertexArray(0)
