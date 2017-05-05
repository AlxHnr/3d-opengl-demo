import globject, onfailure, opengl

type
  FlatMesh = object
    vertexVbo: ArrayBuffer
    indexVbo: ElementBuffer
    vao: VertexArrayObject
    indexCount: int

proc initFlatMesh*(subdivisions: Positive): FlatMesh =
  let subdivisionsPrev = subdivisions - 1
  result.indexCount = subdivisionsPrev * subdivisionsPrev * 6

  var
    vertices = newSeq[float](subdivisions * subdivisions * 3)
    indices = newSeq[int](result.indexCount)

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
      indices[i + 1] = z * subdivisions + x + 1
      indices[i + 2] = (z + 1) * subdivisions + x + 1
      indices[i + 3] = z * subdivisions + x
      indices[i + 4] = (z + 1) * subdivisions + x
      indices[i + 5] = (z + 1) * subdivisions + x + 1

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

proc destroy*(mesh: FlatMesh) =
  mesh.vertexVbo.destroy()
  mesh.indexVbo.destroy()
  mesh.vao.destroy()

proc draw*(mesh: FlatMesh) =
  use mesh.vao:
    glDrawElements(GL_TRIANGLES,
                   mesh.indexCount.GLsizei,
                   GL_UNSIGNED_INT, nil)