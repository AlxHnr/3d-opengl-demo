import math, basic3d, opengl

type Matrix4* = array[4 * 4, GLfloat]

proc toGLfloatSeq*(a: varargs[float]): seq[GLfloat] =
  result = newSeq[GLfloat](a.len)
  for i, v in a:
    result[i] = v.GLfloat

proc toGLuintSeq*(a: varargs[int]): seq[GLuint] =
  result = newSeq[GLuint](a.len)
  for i, v in a:
    result[i] = v.GLuint

proc setTo*(buffer: var Matrix4, matrix: Matrix3d) =
  buffer[0] = matrix.ax
  buffer[1] = matrix.ay
  buffer[2] = matrix.az
  buffer[3] = matrix.aw

  buffer[4] = matrix.bx
  buffer[5] = matrix.by
  buffer[6] = matrix.bz
  buffer[7] = matrix.bw

  buffer[8] = matrix.cx
  buffer[9] = matrix.cy
  buffer[10] = matrix.cz
  buffer[11] = matrix.cw

  buffer[12] = matrix.tx
  buffer[13] = matrix.ty
  buffer[14] = matrix.tz
  buffer[15] = matrix.tw

proc clearScaleRotation*(matrix: Matrix3d): Matrix3d =
  result = matrix

  result.ax = 1.0
  result.ay = 0.0
  result.az = 0.0

  result.bx = 0.0
  result.by = 1.0
  result.bz = 0.0

  result.cx = 0.0
  result.cy = 0.0
  result.cz = 1.0

proc perspectiveMatrix*(fieldOfView, ratio, near, far: float): Matrix3d =
  let
    f = 1.0/tan(fieldOfView/2.0)
    nearMinusFar = near - far

  result.ax = f/ratio
  result.by = f
  result.cz = (far + near)/nearMinusFar
  result.cw = (2 * far * near)/nearMinusFar
  result.tz = -1.0
