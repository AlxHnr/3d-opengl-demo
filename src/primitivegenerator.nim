import math, opengl, globject, use, onfailure

type
  Mesh = object
    vertexVbo: ArrayBuffer
    indexVbo: ElementBuffer
    vao: VertexArrayObject
    indexCount: int
  Circle = object
    vbo: ArrayBuffer
    vao: VertexArrayObject
    vertexCount: int

proc initFlatMeshVao(vertices: openArray[float],
                     indices: openArray[int]): Mesh =
  result.indexCount = indices.len

  result.vertexVbo = initArrayBuffer(vertices)
  onFailure destroy result.vertexVbo:
    result.indexVbo = initElementBuffer(indices)
    onFailure destroy result.indexVbo:
      result.vao = initVertexArrayObject()

      use result.vao:
        result.vertexVbo.bindBuffer()
        result.indexVbo.bindBuffer()
        glVertexAttribPointer(0, 3, cGL_Float, GL_FALSE,
                              3 * GLfloat.sizeof, nil)
        glEnableVertexAttribArray(0)

proc initFlatMesh*(subdivisions: range[2..int.high]): Mesh =
  let
    subdivisions = subdivisions.int
    subdivisionsPrev = subdivisions - 1

  var
    vertices = newSeq[float](subdivisions * subdivisions * 3)
    indices = newSeq[int](subdivisionsPrev * subdivisionsPrev * 6)

  let
    subdivisionHalf = subdivisions/2
    edgeLength = 2.0/subdivisions.float

  # Generate vertices.
  for z in 0..<subdivisions.int:
    let z3Sub = z * 3 * subdivisions
    for x in 0..<subdivisions.int:
      let x3 = x * 3
      vertices[z3Sub + x3] =
        (x.float - subdivisionHalf) * edgeLength
      vertices[z3Sub + x3 + 1] = 0.0
      vertices[z3Sub + x3 + 2] =
        (z.float - subdivisionHalf) * edgeLength

  # Generate indices.
  for z in 0..<subdivisionsPrev:
    let z6Sub = z * 6 * subdivisionsPrev
    for x in 0..<subdivisionsPrev:
      let i = z6Sub + x * 6
      indices[i]     = z * subdivisions + x
      indices[i + 4] = (z + 1) * subdivisions + x
      indices[i + 1] = indices[i + 4] + 1
      indices[i + 2] = indices[i] + 1
      indices[i + 3] = indices[i]
      indices[i + 5] = indices[i + 1]

  initFlatMeshVao(vertices, indices)

proc initCylinder*(subdivisions: range[2..int.high],
                   radius: float): Mesh =
  let
    subdivisionsLength = subdivisions.int
    subdivisionsLengthPrev = subdivisionsLength - 1

    subdivisionsCircle = (subdivisions.float/15.0).int + 3
    subdivisionsCirclePrev = subdivisionsCircle - 1

    xStep = 2.0/subdivisionsLength.float
    circleStep = 2.0 * PI/subdivisionsCircle.float

  var
    vertices = newSeq[float](subdivisionsLength * subdivisionsCircle * 3)
    indices = newSeq[int](subdivisionsLengthPrev * subdivisionsCircle * 6)

  # Generate vertices.
  for xIndex in 0..<subdivisionsLength:
    let x = -1.0 + xIndex.float * xStep
    for circleIndex in 0..<subdivisionsCircle:
      let
        index = xIndex * subdivisionsCircle * 3 + circleIndex * 3
        angle = circleIndex.float * circleStep
      vertices[index] = x
      vertices[index + 1] = sin(angle) * radius
      vertices[index + 2] = cos(angle) * radius

  # Generate indices.
  for xIndex in 0..<subdivisionsLengthPrev:
    for circleIndex in 0..<subdivisionsCirclePrev:
      let index = xIndex * subdivisionsCircle * 6 + circleIndex * 6
      indices[index]     = xIndex * subdivisionsCircle + circleIndex
      indices[index + 1] = (xIndex + 1) * subdivisionsCircle + circleIndex
      indices[index + 2] = indices[index] + 1
      indices[index + 3] = indices[index + 2]
      indices[index + 4] = indices[index + 1]
      indices[index + 5] = indices[index + 1] + 1

    let index = xIndex * subdivisionsCircle * 6 + subdivisionsCirclePrev * 6
    indices[index + 2] = xIndex * subdivisionsCircle
    indices[index]     = indices[index + 2] + subdivisionsCirclePrev
    indices[index + 5] = (xIndex + 1) * subdivisionsCircle
    indices[index + 1] = indices[index + 5] + subdivisionsCirclePrev
    indices[index + 3] = indices[index + 2]
    indices[index + 4] = indices[index + 1]

  initFlatMeshVao(vertices, indices)

proc destroy*(mesh: Mesh) =
  mesh.vertexVbo.destroy()
  mesh.indexVbo.destroy()
  mesh.vao.destroy()

proc draw*(mesh: Mesh) =
  use mesh.vao:
    glDrawElements(GL_TRIANGLES,
                   mesh.indexCount.GLsizei,
                   GL_UNSIGNED_INT, nil)

proc initCircle*(subdivisions: range[3..int.high]): Circle =
  result.vertexCount = subdivisions.int + 2
  var vertices = newSeq[float](result.vertexCount * 2)
  vertices[0] = 0.0
  vertices[1] = 0.0

  vertices[2] = 1.0
  vertices[3] = 0.0

  vertices[vertices.high - 1] = 1.0
  vertices[vertices.high] = 0.0

  let step = 2.0 * PI/subdivisions.float
  for i in 1..<subdivisions.int:
    let angle = i.float * step
    vertices[(i * 2) + 2] = cos(angle)
    vertices[(i * 2) + 3] = sin(angle)

  result.vbo = initArrayBuffer(vertices)
  onFailure destroy result.vbo:
    result.vao = initVertexArrayObject()

    use result.vao:
      result.vbo.bindBuffer()
      glVertexAttribPointer(0, 2, cGL_Float, GL_FALSE,
                            2 * GLfloat.sizeof, nil)
      glEnableVertexAttribArray(0)

proc destroy*(circle: Circle) =
  circle.vbo.destroy()
  circle.vao.destroy()

proc draw*(circle: Circle) =
  use circle.vao:
    glDrawArrays(GL_TRIANGLE_FAN, 0, circle.vertexCount.GLsizei)
