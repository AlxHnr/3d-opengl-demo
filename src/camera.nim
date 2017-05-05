import math, basic3d, mathhelpers

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

proc getLookAtMatrix*(camera: Camera): Matrix4 =
  let invertedPosition = -camera.position

  result[0] = camera.right.x
  result[1] = camera.up.x
  result[2] = camera.direction.x

  result[4] = camera.right.y
  result[5] = camera.up.y
  result[6] = camera.direction.y

  result[8] = camera.right.z
  result[9] = camera.up.z
  result[10] = camera.direction.z

  result[12] = dot(camera.right, invertedPosition)
  result[13] = dot(camera.up, invertedPosition)
  result[14] = dot(camera.direction, invertedPosition)
  result[15] = 1.0
