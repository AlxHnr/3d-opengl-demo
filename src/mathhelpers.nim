import math, basic3d, opengl

type
  Matrix4* = array[4 * 4, GLfloat]

proc toGLfloatSeq*(a: varargs[float]): seq[GLfloat] =
  result = newSeq[GLfloat](a.len)
  for i, v in a:
    result[i] = v

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

proc perspectiveMatrix*(angle, ratio, near, far: float): Matrix4 =
  let
    f = 1.0/tan(degToRad(angle)/2.0)
    nearMinusFar = near - far

  result[0] = f/ratio
  result[5] = f
  result[10] = (far + near)/nearMinusFar
  result[11] = (2 * far * near)/nearMinusFar
  result[14] = -1.0
