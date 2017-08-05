import math, basic3d

type
  SplineValues = tuple[a, b, c, d: float]
  SplineHelperValues = tuple[b, d, h, alpha, c, ll, mu, z: float]
  Spline = object
    x_values: seq[float]
    values: seq[SplineValues]

proc newSpline*(points: openArray[Vector3d]): Spline =
  assert(points.len > 2)

  result.x_values = newSeq[float](points.len)
  result.values = newSeq[SplineValues](points.len - 1)

  var helpers = newSeq[SplineHelperValues](points.len)

  for i, point in points:
    result.x_values[i] = point.x
    result.values[i].a = point.y

  # Compute clamped cubic spline.
  for i in 0..<points.len - 2:
    helpers[i].h = result.x_values[i + 1] - result.x_values[i]

  for i in 1..<points.len - 2:
    helpers[i].alpha =
      3.0/helpers[i].h * (result.values[i + 1].a - result.values[i].a) -
      3.0/helpers[i - 1].h * (result.values[i].a - result.values[i - 1].a)

  helpers[0].ll  = 1
  helpers[0].mu = 0
  helpers[0].z  = 0

  for i in 1..<points.len - 2:
    helpers[i].ll =
      2.0 * (result.x_values[i + 1] - result.x_values[i - 1]) -
      helpers[i - 1].h * helpers[i - 1].mu
    helpers[i].mu = helpers[i].h/helpers[i].ll
    helpers[i].z =
      (helpers[i].alpha - helpers[i - 1].h * helpers[i - 1].z)/helpers[i].ll

  helpers[points.len - 2].ll = 1
  helpers[points.len - 2].c  = 0
  helpers[points.len - 2].z  = 0

  for i in points.len - 3 .. 0:
    helpers[i].c = helpers[i].z - helpers[i].mu * helpers[i + 1].c
    helpers[i].b =
      (result.values[i + 1].a - result.values[i].a)/helpers[i].h -
      helpers[i].h * (helpers[i + 1].c + 2 * helpers[i].c)/3
    helpers[i].d = (helpers[i + 1].c - helpers[i].c)/(3 * helpers[i].h)

  for i in 0..<points.len - 2:
    result.values[i].b = helpers[i].b
    result.values[i].c = helpers[i].c
    result.values[i].d = helpers[i].d
