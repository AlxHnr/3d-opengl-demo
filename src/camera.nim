import math, basic3d

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

proc position*(c: Camera): auto = c.position
proc direction*(c: Camera): auto = c.direction
proc right*(c: Camera): auto = c.right
proc up*(c: Camera): auto = c.up

proc getLookAtMatrix*(camera: Camera): Matrix3d =
  let invertedPosition = -camera.position

  matrix3d(
    camera.right.x,
    camera.up.x,
    camera.direction.x,
    0.0,

    camera.right.y,
    camera.up.y,
    camera.direction.y,
    0.0,

    camera.right.z,
    camera.up.z,
    camera.direction.z,
    0.0,

    dot(camera.right, invertedPosition),
    dot(camera.up, invertedPosition),
    dot(camera.direction, invertedPosition),
    1.0
  )
