import math, basic3d, sdl2, opengl, shader, globject, mathhelpers, camera

const
  windowW = 800
  windowH = 600

template sdlAssert(condition: bool) =
  if not condition:
    stderr.write("failed to initialize libSDL: " & $sdl2.getError() & "\n")
    return true

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
  glEnable(GL_DEPTH_TEST);

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

  let cubeVao = initVertexArrayObject()
  defer: cubeVao.destroy()
  withVertexArrayObject cubeVao:
    cubeBuffer.bindBuffer()

    glVertexAttribPointer(0, 3, cGL_Float, GL_FALSE, 6 * GLfloat.sizeof, nil)
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 3, cGL_Float, GL_FALSE, 6 * GLfloat.sizeof,
                          cast[pointer](3 * GLfloat.sizeof))
    glEnableVertexAttribArray(1);

  let sunVao = initVertexArrayObject()
  defer: sunVao.destroy()
  withVertexArrayObject sunVao:
    cubeBuffer.bindBuffer()
    glVertexAttribPointer(0, 3, cGL_Float, GL_FALSE, 6 * GLfloat.sizeof, nil)
    glEnableVertexAttribArray(0);

  # Setup shaders.
  let simpleShader = loadShaderProgram("shader/simple.vert", "shader/simple.frag")
  defer: simpleShader.destroy()

  let lightShader = loadShaderProgram("shader/light.vert", "shader/light.frag")
  defer: lightShader.destroy()

  # Setup transformation matrices.
  let
    lightModelLoc = lightShader.getUniformLocation("model")
    lightViewLoc = lightShader.getUniformLocation("view")
    lightProjectionLoc = lightShader.getUniformLocation("projection")
    lightSunColorLoc = lightShader.getUniformLocation("sunColor")
    lightSunPositionLoc = lightShader.getUniformLocation("sunPosition")

    simpleModelLoc = simpleShader.getUniformLocation("model")
    simpleViewLoc = simpleShader.getUniformLocation("view")
    simpleProjectionLoc = simpleShader.getUniformLocation("projection")
    simpleColorLoc = simpleShader.getUniformLocation("color")
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
              glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            else:
              glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
            wireframe = not wireframe
          else:
            # Ignore most keys.
            discard nil

    if keys[SDL_SCANCODE_W.uint8] == 1:
      camera.moveForward(-1.0)
    elif keys[SDL_SCANCODE_S.uint8] == 1:
      camera.moveForward(1.0)
    if keys[SDL_SCANCODE_A.uint8] == 1:
      camera.moveRight(-1.0)
    elif keys[SDL_SCANCODE_D.uint8] == 1:
      camera.moveRight(1.0)

    # Update state.
    let
      secondsPassed = sdl2.getTicks().float/1000.0
      rotateMatrix = rotate(secondsPassed, XAXIS)
      sunPosition = vector3d(sin(secondsPassed) * 30, 10, cos(secondsPassed) * 30)
    sunMatrix.setTo(move(sunPosition))

    # Render.
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    withShaderProgram lightShader:
      camera.updateViewUniform(lightViewLoc)
      glUniformMatrix4fv(lightProjectionLoc, 1, GL_FALSE, projectionMatrix[0].addr)
      glUniform3fv(lightSunColorLoc, 1, sunColor[0].addr)
      glUniform3f(lightSunPositionLoc, sunPosition.x, sunPosition.y, sunPosition.z)

      withVertexArrayObject cubeVao:
        for x in -5..4:
          for y in -5..4:
            for z in -5..4:
              modelMatrix.setTo(rotateMatrix &
                                move(x.float * 3, y.float * 3, z.float * 3))
              glUniformMatrix4fv(lightModelLoc, 1, GL_FALSE, modelMatrix[0].addr)
              glDrawArrays(GL_TRIANGLES, 0, cubeData.len.GLsizei)

    withShaderProgram simpleShader:
      glUniformMatrix4fv(simpleModelLoc, 1, GL_FALSE, sunMatrix[0].addr)
      camera.updateViewUniform(simpleViewLoc)
      glUniformMatrix4fv(simpleProjectionLoc, 1, GL_FALSE, projectionMatrix[0].addr)
      glUniform3fv(simpleColorLoc, 1, sunColor[0].addr)

      withVertexArrayObject sunVao:
        glDrawArrays(GL_TRIANGLES, 0, cubeData.len.GLsizei)

    glSwapWindow(window)

if main(): quit(1)
