import opengl, mathhelpers, onfailure

type
  ArrayBuffer* = distinct GLuint
  ElementBuffer* = distinct GLuint
  VertexArrayObject* = distinct GLuint

proc toGLenum(buffer: ArrayBuffer): GLenum = GL_ARRAY_BUFFER
proc toGLenum(buffer: ElementBuffer): GLenum = GL_ELEMENT_ARRAY_BUFFER

proc initBuffer(bufferType: GLenum,
                values: seq[GLfloat] | seq[GLuint]): GLuint =
  var values = values
  glGenBuffers(1, result.addr)
  onFailure glDeleteBuffers(1, result.addr):
    glBindBuffer(bufferType, result)
    glBufferData(bufferType,
                 values.len * values[0].sizeof,
                 values[0].addr, GL_STATIC_DRAW)
    glBindBuffer(bufferType, 0)

proc initArrayBuffer*(vertices: varargs[float]): ArrayBuffer =
  initBuffer(result.toGLenum, vertices.toGLfloatSeq).ArrayBuffer

proc initElementBuffer*(indicies: varargs[int]): ElementBuffer =
  initBuffer(result.toGLenum, indicies.toGLuintSeq).ElementBuffer

proc bindBuffer*(buffer: ArrayBuffer | ElementBuffer) =
  glBindBuffer(buffer.toGLenum, buffer.GLuint)

proc unbindBuffer*(buffer: ArrayBuffer | ElementBuffer) =
  glBindBuffer(buffer.toGLenum, 0)

proc destroy*(buffer: ArrayBuffer | ElementBuffer) =
  var buffer = buffer.GLuint
  glDeleteBuffers(1, buffer.addr)

proc initVertexArrayObject*(): VertexArrayObject =
  var vao: GLuint
  glGenVertexArrays(1, vao.addr)
  vao.VertexArrayObject

proc destroy*(vao: VertexArrayObject) =
  var vao = vao.GLuint
  glDeleteVertexArrays(1, vao.addr)

template use*(vao: VertexArrayObject, body: untyped) =
  var previousVao: GLint
  glGetIntegerv(GL_VERTEX_ARRAY_BINDING, previousVao.addr)

  glBindVertexArray(vao.GLuint)
  try:
    body
  finally:
    glBindVertexArray(previousVao.GLuint)
