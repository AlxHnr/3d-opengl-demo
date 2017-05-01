import math, basic3d, opengl

type
  Matrix4* = array[4 * 4, GLfloat]

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

proc perspectiveMatrix*(fieldOfView, ratio, near, far: float): Matrix4 =
  let
    f = 1.0/tan(fieldOfView/2.0)
    nearMinusFar = near - far

  result[0] = f/ratio
  result[5] = f
  result[10] = (far + near)/nearMinusFar
  result[11] = (2 * far * near)/nearMinusFar
  result[14] = -1.0

proc lookAt*(camera, target: Point3d): Matrix4 =
  var cameraVector = camera - target
  cameraVector.normalize()

  var right = cross(YAXIS, cameraVector)
  right.normalize()

  var up = cross(cameraVector, right)
  up.normalize()

  let cameraInverted = vector3d(-camera.x, -camera.y, -camera.z)

  result[0] = right.x
  result[1] = up.x
  result[2] = cameraVector.x

  result[4] = right.y
  result[5] = up.y
  result[6] = cameraVector.y

  result[8] = right.z
  result[9] = up.z
  result[10] = cameraVector.z

  result[12] = dot(right, cameraInverted)
  result[13] = dot(up, cameraInverted)
  result[14] = dot(cameraVector, cameraInverted)

  result[15] = 1.0
