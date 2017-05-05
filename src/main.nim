import
  math, basic3d,
  sdl2, opengl,
  globject, mathhelpers, camera, flatmesh, shaderwrapper, uniform

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

  let flatMesh = initFlatMesh(48)
  defer: flatMesh.destroy()

  # Setup transformation matrices.
  var
    projectionMatrix = perspectiveMatrix(PI/4, windowW/windowH, 1.0, 100.0)
    camera = initCamera(0.0, 300.0, -40.0)

  # Setup shaders.
  var flatMeshShader = loadFlatMeshShader()
  defer: flatMeshShader.destroy()
  use flatMeshShader:
    flatMeshShader.projection.updateWith(projectionMatrix)
    flatMeshShader.lightColor.updateWith(vector3d(1.0, 1.0, 1.0))
    flatMeshShader.lightPosition.updateWith(vector3d(0.0, 10.0, 0.0))

  # Main loop.
  var
    running = true
    wireframe = false
    cameraMode = false
    shaderReloadCounter = 0
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
    let secondsPassed = sdl2.getTicks().float/1000.0
    var lookAtMatrix = camera.getLookAtMatrix()

    # Reload shaders.
    if shaderReloadCounter == 40:
      shaderReloadCounter = 0
      flatMeshShader.tryReload:
        flatMeshShader.projection.updateWith(projectionMatrix)
        flatMeshShader.lightColor.updateWith(vector3d(1.0, 1.0, 1.0))
        flatMeshShader.lightPosition.updateWith(vector3d(0.0, 10.0, 0.0))
    else:
      shaderReloadCounter += 1

    # Render.
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    use flatMeshShader:
      flatMeshShader.view.updateWith(lookAtMatrix)
      flatMeshShader.model.updateWith(scale(1000.0))
      flatMesh.draw()

    glSwapWindow(window)

if main(): quit(1)
