import math, basic3d, sdl2, opengl, shader, globject, mathhelpers, camera

const
  windowW = 800
  windowH = 600

template sdlAssert(condition: bool) =
  if not condition:
    stderr.write("failed to initialize libSDL: " & $sdl2.getError() & "\n")
    return true

proc initFlatMesh(subdivisions: Positive):
     tuple[vertices: seq[float], indicies: seq[int]]  =
  let subdivisionsPrev = subdivisions - 1
  newSeq[float](result.vertices, subdivisions * subdivisions * 3)
  newSeq[int](result.indicies, subdivisionsPrev * subdivisionsPrev * 6)

  let
    subdivisionHalf = subdivisions/2
    edgeLength = 2.0/subdivisions.float

  for z in 0..<subdivisions.int:
    let z3Sub = z * 3 * subdivisions
    for x in 0..<subdivisions.int:
      let x3 = x * 3
      result.vertices[z3Sub + x3] =
        (x.float - subdivisionHalf) * edgeLength
      result.vertices[z3Sub + x3 + 1] = 0.0
      result.vertices[z3Sub + x3 + 2] =
        (z.float - subdivisionHalf) * edgeLength

  for z in 0..<subdivisionsPrev:
    let z6Sub = z * 6 * subdivisionsPrev
    for x in 0..<subdivisionsPrev:
      let i = z6Sub + x * 6
      result.indicies[i]     = z * subdivisions + x
      result.indicies[i + 1] = z * subdivisions + x + 1
      result.indicies[i + 2] = (z + 1) * subdivisions + x + 1
      result.indicies[i + 3] = z * subdivisions + x
      result.indicies[i + 4] = (z + 1) * subdivisions + x
      result.indicies[i + 5] = (z + 1) * subdivisions + x + 1

proc loadShaderPair(name: string): auto =
  loadShaderProgram("shader/" & name & ".vert",
                    "shader/" & name & ".frag")

proc main(): bool =
  sdlAssert(sdl2.init(INIT_VIDEO) == SdlSuccess)
  defer: sdl2.quit()

  sdlAssert(glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3) == 0)
  sdlAssert(glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3) == 0)
  sdlAssert(glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK,
                           SDL_GL_CONTEXT_PROFILE_CORE) == 0)

  let window = createWindow("OpenGL Demo",
                            SDL_WINDOWPOS_UNDEFINED,
                            SDL_WINDOWPOS_UNDEFINED,
                            windowW, windowH,
                            SDL_WINDOW_OPENGL)
  sdlAssert(window != nil)
  defer: window.destroy()

  let glcontext = glCreateContext(window)
  sdlAssert(glcontext != nil)
  defer: glDeleteContext(glcontext)
  loadExtensions()

  glViewport(0, 0, windowW, windowH)
  glClearColor(0, 0, 0, 0)
  glEnable(GL_DEPTH_TEST)

  # Setup vertices.
  let cubeData =
    [
      -1.0, -1.0, -1.0,  0.0,  0.0, -1.0,
       1.0, -1.0, -1.0,  0.0,  0.0, -1.0,
       1.0,  1.0, -1.0,  0.0,  0.0, -1.0,
       1.0,  1.0, -1.0,  0.0,  0.0, -1.0,
      -1.0,  1.0, -1.0,  0.0,  0.0, -1.0,
      -1.0, -1.0, -1.0,  0.0,  0.0, -1.0,

      -1.0, -1.0,  1.0,  0.0,  0.0,  1.0,
       1.0, -1.0,  1.0,  0.0,  0.0,  1.0,
       1.0,  1.0,  1.0,  0.0,  0.0,  1.0,
       1.0,  1.0,  1.0,  0.0,  0.0,  1.0,
      -1.0,  1.0,  1.0,  0.0,  0.0,  1.0,
      -1.0, -1.0,  1.0,  0.0,  0.0,  1.0,

      -1.0,  1.0,  1.0, -1.0,  0.0,  0.0,
      -1.0,  1.0, -1.0, -1.0,  0.0,  0.0,
      -1.0, -1.0, -1.0, -1.0,  0.0,  0.0,
      -1.0, -1.0, -1.0, -1.0,  0.0,  0.0,
      -1.0, -1.0,  1.0, -1.0,  0.0,  0.0,
      -1.0,  1.0,  1.0, -1.0,  0.0,  0.0,

       1.0,  1.0,  1.0,  1.0,  0.0,  0.0,
       1.0,  1.0, -1.0,  1.0,  0.0,  0.0,
       1.0, -1.0, -1.0,  1.0,  0.0,  0.0,
       1.0, -1.0, -1.0,  1.0,  0.0,  0.0,
       1.0, -1.0,  1.0,  1.0,  0.0,  0.0,
       1.0,  1.0,  1.0,  1.0,  0.0,  0.0,

      -1.0, -1.0, -1.0,  0.0, -1.0,  0.0,
       1.0, -1.0, -1.0,  0.0, -1.0,  0.0,
       1.0, -1.0,  1.0,  0.0, -1.0,  0.0,
       1.0, -1.0,  1.0,  0.0, -1.0,  0.0,
      -1.0, -1.0,  1.0,  0.0, -1.0,  0.0,
      -1.0, -1.0, -1.0,  0.0, -1.0,  0.0,

      -1.0,  1.0, -1.0,  0.0,  1.0,  0.0,
       1.0,  1.0, -1.0,  0.0,  1.0,  0.0,
       1.0,  1.0,  1.0,  0.0,  1.0,  0.0,
       1.0,  1.0,  1.0,  0.0,  1.0,  0.0,
      -1.0,  1.0,  1.0,  0.0,  1.0,  0.0,
      -1.0,  1.0, -1.0,  0.0,  1.0,  0.0,
    ]
  let cubeBuffer = initArrayBuffer(cubeData)
  defer: cubeBuffer.destroy()

  let flatMeshData = initFlatMesh(48)

  let flatMeshVertexBuffer = initArrayBuffer(flatMeshData.vertices)
  defer: flatMeshVertexBuffer.destroy()
  let flatMeshIndexBuffer = initElementBuffer(flatMeshData.indicies)
  defer: flatMeshIndexBuffer.destroy()

  let flatMeshVao = initVertexArrayObject()
  defer: flatMeshVao.destroy()
  use flatMeshVao:
    flatMeshVertexBuffer.bindBuffer()
    flatMeshIndexBuffer.bindBuffer()
    glVertexAttribPointer(0, 3, cGL_Float, GL_FALSE, 3 * GLfloat.sizeof, nil)
    glEnableVertexAttribArray(0)

  let planeData =
    [
      -2.0, -1.0, 0.0,
       1.0, -1.0, 0.0,
      -2.0,  1.0, 0.0,
       1.0, -1.0, 0.0,
       1.0,  1.0, 0.0,
      -2.0,  1.0, 0.0,
    ]
  let planeBuffer = initArrayBuffer(planeData)
  defer: planeBuffer.destroy()

  let planeVao = initVertexArrayObject()
  use planeVao:
    planeBuffer.bindBuffer()
    glVertexAttribPointer(0, 3, cGL_Float, GL_FALSE, 3 * GLfloat.sizeof, nil)
    glEnableVertexAttribArray(0)

  # Setup vaos.
  let cubeVao = initVertexArrayObject()
  defer: cubeVao.destroy()
  use cubeVao:
    cubeBuffer.bindBuffer()

    glVertexAttribPointer(0, 3, cGL_Float, GL_FALSE, 6 * GLfloat.sizeof, nil)
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(1, 3, cGL_Float, GL_FALSE, 6 * GLfloat.sizeof,
                          cast[pointer](3 * GLfloat.sizeof))
    glEnableVertexAttribArray(1)

  let sunVao = initVertexArrayObject()
  defer: sunVao.destroy()
  use sunVao:
    cubeBuffer.bindBuffer()
    glVertexAttribPointer(0, 3, cGL_Float, GL_FALSE, 6 * GLfloat.sizeof, nil)
    glEnableVertexAttribArray(0)

  # Setup shaders.
  let simpleShader = loadShaderPair("simple")
  defer: simpleShader.destroy()

  let lightShader = loadShaderPair("light")
  defer: lightShader.destroy()

  let flatMeshShader = loadShaderPair("flatMesh")
  defer: flatMeshShader.destroy()

  let mandelShader = loadShaderPair("mandelbrot")
  defer: mandelShader.destroy()

  # Setup transformation matrices.
  let
    lightModelLoc = lightShader.getUniformLocation("model")
    lightViewLoc = lightShader.getUniformLocation("view")
    lightProjectionLoc = lightShader.getUniformLocation("projection")
    lightSunColorLoc = lightShader.getUniformLocation("sunColor")
    lightSunPositionLoc = lightShader.getUniformLocation("sunPosition")

    flatMeshModelLoc = flatMeshShader.getUniformLocation("model")
    flatMeshViewLoc = flatMeshShader.getUniformLocation("view")
    flatMeshProjectionLoc = flatMeshShader.getUniformLocation("projection")
    flatMeshSunColorLoc = flatMeshShader.getUniformLocation("sunColor")
    flatMeshSunPositionLoc = flatMeshShader.getUniformLocation("sunPosition")
    flatMeshTimeLoc = flatMeshShader.getUniformLocation("time")

    simpleModelLoc = simpleShader.getUniformLocation("model")
    simpleViewLoc = simpleShader.getUniformLocation("view")
    simpleProjectionLoc = simpleShader.getUniformLocation("projection")
    simpleColorLoc = simpleShader.getUniformLocation("color")

    mandelModelLoc = mandelShader.getUniformLocation("model")
    mandelViewLoc = mandelShader.getUniformLocation("view")
    mandelProjectionLoc = mandelShader.getUniformLocation("projection")
  var
    modelMatrix, sunMatrix: Matrix4
    projectionMatrix = perspectiveMatrix(PI/4, windowW/windowH, 1.0, 100.0)
    camera = initCamera(0.0, 0.0, -40.0)
    sunColor = [1.0.GLfloat, 1.0.GLfloat, 1.0.GLfloat]

  # Main loop.
  var
    running = true
    wireframe = false
    cameraMode = false
    event = sdl2.defaultEvent
  let keys = sdl2.getKeyboardState()

  while running:
    # Handle events.
    while pollEvent(event):
      if event.kind == QuitEvent:
        running = false
      elif event.kind == MouseButtonDown and
           event.button.button == sdl2.BUTTON_RIGHT:
        cameraMode = true
      elif event.kind == MouseButtonUp and
           event.button.button == sdl2.BUTTON_RIGHT:
        cameraMode = false
      elif event.kind == MouseMotion and cameraMode:
        camera.yawPitch(event.motion.xrel.float/200.0,
                        event.motion.yrel.float/200.0)
      elif event.kind == KeyDown:
        case event.key.keysym.sym:
          of K_q, K_ESCAPE:
            running = false
          of K_g:
            if wireframe:
              glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
            else:
              glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
            wireframe = not wireframe
          else:
            # Ignore most keys.
            discard nil

    let movementSpeed =
      if keys[SDL_SCANCODE_SPACE.uint8] == 1:
        10.0
      elif keys[SDL_SCANCODE_LSHIFT.uint8] == 1:
        0.1
      else:
        1.0

    if keys[SDL_SCANCODE_W.uint8] == 1:
      camera.moveForward(-movementSpeed)
    elif keys[SDL_SCANCODE_S.uint8] == 1:
      camera.moveForward(movementSpeed)
    if keys[SDL_SCANCODE_A.uint8] == 1:
      camera.moveRight(-movementSpeed)
    elif keys[SDL_SCANCODE_D.uint8] == 1:
      camera.moveRight(movementSpeed)

    # Update state.
    let
      secondsPassed = sdl2.getTicks().float/1000.0
      rotateMatrix = rotate(secondsPassed, XAXIS)

    var sunPosition = vector3d(sin(secondsPassed) * 30, 10, cos(secondsPassed) * 30)

    # Render.
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    use lightShader:
      camera.updateViewUniform(lightViewLoc)
      glUniformMatrix4fv(lightProjectionLoc, 1, GL_FALSE, projectionMatrix[0].addr)
      glUniform3f(lightSunPositionLoc, sunPosition.x, sunPosition.y, sunPosition.z)
      glUniform3fv(lightSunColorLoc, 1, sunColor[0].addr)

      use cubeVao:
        for x in -5..4:
          for y in -5..4:
            for z in -5..4:
              modelMatrix.setTo(rotateMatrix &
                                move(x.float * 3, y.float * 3, z.float * 3))
              glUniformMatrix4fv(lightModelLoc, 1, GL_FALSE, modelMatrix[0].addr)
              glDrawArrays(GL_TRIANGLES, 0, cubeData.len.GLsizei)

    let flatMeshOffset = -150.0
    use flatMeshShader:
      camera.updateViewUniform(flatMeshViewLoc)
      glUniformMatrix4fv(flatMeshProjectionLoc, 1, GL_FALSE, projectionMatrix[0].addr)
      glUniform3f(flatMeshSunPositionLoc, sunPosition.x + flatMeshOffset,
                  sunPosition.y, sunPosition.z)
      glUniform3fv(flatMeshSunColorLoc, 1, sunColor[0].addr)
      glUniform1f(flatMeshTimeLoc, secondsPassed)

      modelMatrix.setTo(scale(30.0) & move(flatMeshOffset, 0, 0))
      glUniformMatrix4fv(flatMeshModelLoc, 1, GL_FALSE, modelMatrix[0].addr)

      use flatMeshVao:
        glDrawElements(GL_TRIANGLES, flatMeshData.indicies.len.GLsizei,
                       GL_UNSIGNED_INT, nil)

    use simpleShader:
      camera.updateViewUniform(simpleViewLoc)
      glUniformMatrix4fv(simpleProjectionLoc, 1, GL_FALSE, projectionMatrix[0].addr)
      glUniform3fv(simpleColorLoc, 1, sunColor[0].addr)

      use sunVao:
        sunMatrix.setTo(move(sunPosition))
        glUniformMatrix4fv(simpleModelLoc, 1, GL_FALSE, sunMatrix[0].addr)
        glDrawArrays(GL_TRIANGLES, 0, cubeData.len.GLsizei)

        sunPosition.x += flatMeshOffset
        sunMatrix.setTo(move(sunPosition))
        glUniformMatrix4fv(simpleModelLoc, 1, GL_FALSE, sunMatrix[0].addr)
        glDrawArrays(GL_TRIANGLES, 0, cubeData.len.GLsizei)

    use mandelShader:
      camera.updateViewUniform(mandelViewLoc)
      glUniformMatrix4fv(mandelProjectionLoc, 1, GL_FALSE, projectionMatrix[0].addr)

      use planeVao:
        modelMatrix.setTo(scale(1000.0) & move(0.0, 0.0, -3000.0))
        glUniformMatrix4fv(mandelModelLoc, 1, GL_FALSE, modelMatrix[0].addr)
        glDrawArrays(GL_TRIANGLES, 0, planeData.len.GLsizei)

    glSwapWindow(window)

if main(): quit(1)
