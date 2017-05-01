import math, basic3d, sdl2, opengl, shader, globject, mathhelpers

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
  let vertices = initArrayBuffer(-1.0, -1.0,  1.0,
                                  1.0, -1.0,  1.0,
                                  1.0, -1.0, -1.0,
                                 -1.0, -1.0, -1.0,
                                 -1.0,  1.0,  1.0,
                                  1.0,  1.0,  1.0,
                                  1.0,  1.0, -1.0,
                                 -1.0,  1.0, -1.0)
  defer: vertices.destroy()

  let indicies = initElementBuffer(0, 1, 2,
                                   0, 2, 3,
                                   0, 1, 5,
                                   0, 4, 5,
                                   0, 3, 7,
                                   0, 4, 7,
                                   2, 1, 5,
                                   2, 6, 5,
                                   2, 3, 7,
                                   2, 6, 7,
                                   4, 5, 6,
                                   4, 7, 6)
  defer: indicies.destroy()

  let vao = initVertexArrayObject()
  defer: vao.destroy()

  withVertexArrayObject vao:
    vertices.bindBuffer()
    indicies.bindBuffer()
    glVertexAttribPointer(0, 3, cGL_Float, GL_FALSE, 3 * GLfloat.sizeof, nil)
    glEnableVertexAttribArray(0);

  # Setup shaders.
  let shaderProgram =
    loadShaderProgram("shader/simple.vert", "shader/simple.frag")
  defer: shaderProgram.destroy()

  # Setup transformation matrices.
  let
    modelLocation = shaderProgram.getUniformLocation("model")
    viewLocation = shaderProgram.getUniformLocation("view")
    projectionLocation = shaderProgram.getUniformLocation("projection")
  var
    modelMatrix, viewMatrix: Matrix4
    projectionMatrix = perspectiveMatrix(PI/4, windowW/windowH, 1.0, 100.0)
    camera = vector3d(0.0, 0.0, -40.0)
    cameraVector: Vector3d
    yaw = -PI/2
    pitch = 0.0

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
        yaw += event.motion.xrel.float/200.0
        pitch += event.motion.yrel.float/200.0
        if pitch < -PI/2.1: pitch = -PI/2.1
        elif pitch > PI/2.1: pitch = PI/2.1
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
      camera -= cameraVector
    elif keys[SDL_SCANCODE_S.uint8] == 1:
      camera += cameraVector
    if keys[SDL_SCANCODE_A.uint8] == 1:
      var right = cross(YAXIS, cameraVector)
      right.normalize()
      camera -= right
    elif keys[SDL_SCANCODE_D.uint8] == 1:
      var right = cross(YAXIS, cameraVector)
      right.normalize()
      camera += right

    # Update state.
    let rotateMatrix = rotate(sdl2.getTicks().float/1000.0, XAXIS)

    cameraVector.x = cos(yaw) * cos(pitch)
    cameraVector.y = sin(pitch)
    cameraVector.z = sin(yaw) * cos(pitch)
    cameraVector.normalize()
    viewMatrix = lookAt(camera, cameraVector)

    # Render.
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    withShaderProgram shaderProgram:
      glUniformMatrix4fv(viewLocation, 1, GL_FALSE, viewMatrix[0].addr)
      glUniformMatrix4fv(projectionLocation, 1, GL_FALSE, projectionMatrix[0].addr)
      withVertexArrayObject vao:
        for x in -5..4:
          for y in -5..4:
            for z in -5..4:
              modelMatrix.setTo(rotateMatrix &
                                move(x.float * 3, y.float * 3, z.float * 3))
              glUniformMatrix4fv(modelLocation, 1, GL_FALSE, modelMatrix[0].addr)
              glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, nil)

    glSwapWindow(window)

if main(): quit(1)
