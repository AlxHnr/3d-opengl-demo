import
  math, basic3d,
  sdl2, opengl,
  shader, uniform, globject, mathhelpers, camera, flatmesh

const
  windowW = 800
  windowH = 600

template sdlAssert(condition: bool) =
  if not condition:
    stderr.write("failed to initialize libSDL: " & $sdl2.getError() & "\n")
    return true

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

  let flatMesh = initFlatMesh(48)
  defer: flatMesh.destroy()

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
    lightShaderUniforms = lightShader.getUniformLocationMVP()
    lightSunColorLoc = lightShader.getUniformLocationVec3("lightColor")
    lightSunPositionLoc = lightShader.getUniformLocationVec3("lightPosition")

    flatMeshUniforms = flatMeshShader.getUniformLocationMVP()
    flatMeshSunColorLoc = flatMeshShader.getUniformLocationVec3("lightColor")
    flatMeshSunPositionLoc = flatMeshShader.getUniformLocationVec3("lightPosition")
    flatMeshTimeLoc = flatMeshShader.getUniformLocationFloat("time")

    simpleUniforms = simpleShader.getUniformLocationMVP()
    simpleColorLoc = simpleShader.getUniformLocationVec3("color")

    mandelUniforms = mandelShader.getUniformLocationMVP()

    sunColor = vector3d(1.0, 1.0, 1.0)
  var
    modelMatrix, sunMatrix: Matrix4
    projectionMatrix = perspectiveMatrix(PI/4, windowW/windowH, 1.0, 100.0)
    camera = initCamera(0.0, 0.0, -40.0)

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

    var
      sunPosition = vector3d(sin(secondsPassed) * 30, 10, cos(secondsPassed) * 30)
      lookAtMatrix = camera.getLookAtMatrix()

    # Render.
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    use lightShader:
      lightShaderUniforms.view.updateWith(lookAtMatrix)
      lightShaderUniforms.projection.updateWith(projectionMatrix)
      lightSunPositionLoc.updateWith(sunPosition)
      lightSunColorLoc.updateWith(sunColor)

      use cubeVao:
        for x in -5..4:
          for y in -5..4:
            for z in -5..4:
              modelMatrix.setTo(rotateMatrix &
                                move(x.float * 3, y.float * 3, z.float * 3))
              lightShaderUniforms.model.updateWith(modelMatrix)
              glDrawArrays(GL_TRIANGLES, 0, cubeData.len.GLsizei)

    let flatMeshOffset = -150.0
    use flatMeshShader:
      flatMeshUniforms.view.updateWith(lookAtMatrix)
      flatMeshUniforms.projection.updateWith(projectionMatrix)
      flatMeshSunPositionLoc.updateWith(sunPosition)
      flatMeshSunColorLoc.updateWith(sunColor)
      flatMeshTimeLoc.updateWith(secondsPassed)

      modelMatrix.setTo(scale(30.0) & move(flatMeshOffset, 0, 0))
      flatMeshUniforms.model.updateWith(modelMatrix)

      flatMesh.draw()

    use simpleShader:
      simpleUniforms.view.updateWith(lookAtMatrix)
      simpleUniforms.projection.updateWith(projectionMatrix)
      simpleColorLoc.updateWith(sunColor)

      use sunVao:
        sunMatrix.setTo(move(sunPosition))
        simpleUniforms.model.updateWith(sunMatrix)
        glDrawArrays(GL_TRIANGLES, 0, cubeData.len.GLsizei)

        sunPosition.x += flatMeshOffset
        sunMatrix.setTo(move(sunPosition))
        simpleUniforms.model.updateWith(sunMatrix)
        glDrawArrays(GL_TRIANGLES, 0, cubeData.len.GLsizei)

    use mandelShader:
      mandelUniforms.view.updateWith(lookAtMatrix)
      mandelUniforms.projection.updateWith(projectionMatrix)

      use planeVao:
        modelMatrix.setTo(scale(1000.0) & move(0.0, 0.0, -3000.0))
        mandelUniforms.model.updateWith(modelMatrix)
        glDrawArrays(GL_TRIANGLES, 0, planeData.len.GLsizei)

    glSwapWindow(window)

if main(): quit(1)
