import math, basic3d, uniform, shaderwrapper

type
  SplineValues = tuple[a, b, c, d: float]
  SplineHelperValues = tuple[a, b, c, d, h, alpha, ll, mu, z: float]
  Spline* = object
    x_values: seq[float]
    values: seq[SplineValues]

proc newSpline*(points: openArray[Vector3d]): Spline =
  assert(points.len > 2)

  result.x_values = newSeq[float](points.len)
  result.values = newSeq[SplineValues](points.len)
  var helpers = newSeq[SplineHelperValues](points.len)

  for i, point in points:
    result.x_values[i] = point.x
    helpers[i].a = point.y

  # Compute clamped cubic spline.
  for i in 0..<points.len - 1:
    helpers[i].h = result.x_values[i + 1] - result.x_values[i]

  for i in 1..<points.len - 1:
    helpers[i].alpha =
      3.0/helpers[i].h * (helpers[i + 1].a - helpers[i].a) -
      3.0/helpers[i - 1].h * (helpers[i].a - helpers[i - 1].a)

  helpers[0].ll = 1
  helpers[0].mu = 0
  helpers[0].z  = 0

  for i in 1..<points.len - 1:
    helpers[i].ll =
      2.0 * (result.x_values[i + 1] - result.x_values[i - 1]) -
      helpers[i - 1].h * helpers[i - 1].mu
    helpers[i].mu = helpers[i].h/helpers[i].ll
    helpers[i].z =
      (helpers[i].alpha - helpers[i - 1].h * helpers[i - 1].z)/helpers[i].ll

  helpers[points.len - 1].ll = 1
  helpers[points.len - 1].z  = 0
  helpers[points.len - 1].c  = 0

  for i in countdown(points.len - 2, 0):
    helpers[i].c = helpers[i].z - helpers[i].mu * helpers[i + 1].c
    helpers[i].b =
      (helpers[i + 1].a - helpers[i].a)/helpers[i].h -
      helpers[i].h * (helpers[i + 1].c + 2.0 * helpers[i].c)/3.0
    helpers[i].d = (helpers[i + 1].c - helpers[i].c)/(3.0 * helpers[i].h)

  for i in 0..<points.len - 1:
    result.values[i].a = helpers[i].a
    result.values[i].b = helpers[i].b
    result.values[i].c = helpers[i].c
    result.values[i].d = helpers[i].d

proc updateSplineLocations*(U: UniformLocations, spline: Spline) =
  assert(spline.values.len == 4)
  assert(spline.x_values.len == 4)

  U.splineData.updateWith(matrix3d(
    spline.values[0].a, spline.values[0].b, spline.values[0].c, spline.values[0].d,
    spline.values[1].a, spline.values[1].b, spline.values[1].c, spline.values[1].d,
    spline.x_values[0], spline.x_values[1], spline.x_values[2], spline.x_values[3],
    0.0,                0.0,                0.0,                0.0))
