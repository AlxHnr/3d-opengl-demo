import math, basic3d, mathhelpers, opengl

type
  Camera = object
    position, direction, right, up: Vector3d
    yaw, pitch: float

proc recomputeValues(camera: var Camera) =
  camera.direction.x = cos(camera.yaw) * cos(camera.pitch)
  camera.direction.y = sin(camera.pitch)
  camera.direction.z = sin(camera.yaw) * cos(camera.pitch)
  camera.direction.normalize()

  camera.right = cross(YAXIS, camera.direction)
  camera.right.normalize()
  camera.up = cross(camera.direction, camera.right)
  camera.up.normalize()

proc initCamera*(x, y, z: float): Camera =
  result.position = vector3d(x, y, z)
  result.yaw = -PI/2
  result.pitch = 0.0
  result.recomputeValues()

proc moveRight*(camera: var Camera, factor: float) =
  camera.position += camera.right * factor

proc moveUp*(camera: var Camera, factor: float) =
  camera.position += camera.up * factor

proc moveForward*(camera: var Camera, factor: float) =
  camera.position += camera.direction * factor

proc yawPitch*(camera: var Camera; yaw, pitch: float) =
  camera.yaw += yaw
  camera.pitch += pitch

  if camera.pitch < -PI/2.1:
    camera.pitch = -PI/2.1
  elif camera.pitch > PI/2.1:
    camera.pitch = PI/2.1

  camera.recomputeValues()

proc updateViewUniform*(camera: Camera, location: GLint) =
  let invertedPosition = -camera.position

  var matrix: Matrix4
  matrix[0] = camera.right.x
  matrix[1] = camera.up.x
  matrix[2] = camera.direction.x

  matrix[4] = camera.right.y
  matrix[5] = camera.up.y
  matrix[6] = camera.direction.y

  matrix[8] = camera.right.z
  matrix[9] = camera.up.z
  matrix[10] = camera.direction.z

  matrix[12] = dot(camera.right, invertedPosition)
  matrix[13] = dot(camera.up, invertedPosition)
  matrix[14] = dot(camera.direction, invertedPosition)
  matrix[15] = 1.0

  glUniformMatrix4fv(location, 1, GL_FALSE, matrix[0].addr)
