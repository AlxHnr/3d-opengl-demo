import
  math, basic3d,
  sdl2, opengl,
  globject, mathhelpers, camera, primitivegenerator,
  shader, shaderwrapper, uniform, use

type MouseMode = enum mmNone, mmCamera, mmDrag

const
  windowW = 1024
  windowH = 768

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

  # Setup vaos.
  let flatMesh = initFlatMesh(96)
  defer: flatMesh.destroy()

  let sun = initCircle(18)
  defer: sun.destroy()
  var sunPosition = vector3d(1.0, 11.0, 1.0)

  # Setup transformation matrices.
  var
    projectionMatrix = perspectiveMatrix(PI/4, windowW/windowH, 1.0, 100.0)
    camera = initCamera(0.0, 10.0, -30.0)

  # Setup shaders.
  var flatMeshShader = loadFlatMeshShader()
  defer: flatMeshShader.destroy()
  use flatMeshShader:
    U.projection.updateWith(projectionMatrix)
    U.lightColor.updateWith(vector3d(1.0, 1.0, 1.0))

  let sunShader =
    initShader(["shader/lightsource.vert"], ["shader/lightsource.frag"])
  defer: sunShader.destroy()
  let sunShaderProjection = sunShader.getUniformLocationMat4("projection")
  let sunShaderModelView = sunShader.getUniformLocationMat4("modelView")
  use sunShader:
    sunShaderProjection.updateWith(projectionMatrix)

  # Main loop.
  var
    running = true
    wireframe = false
    mouseMode = mmNone
    shaderReloadCounter = 0
    event = sdl2.defaultEvent
  let keys = sdl2.getKeyboardState()

  while running:
    # Handle events.
    while pollEvent(event):
      if event.kind == QuitEvent:
        running = false
      elif event.kind == MouseButtonDown:
        case event.button.button:
          of sdl2.BUTTON_RIGHT:
            mouseMode = mmCamera
          of sdl2.BUTTON_LEFT:
            mouseMode = mmDrag
          else: discard
      elif event.kind == MouseButtonUp and
           (event.button.button == sdl2.BUTTON_LEFT or
            event.button.button == sdl2.BUTTON_RIGHT):
        mouseMode = mmNone
      elif event.kind == MouseMotion:
        case mouseMode:
          of mmCamera:
            camera.yawPitch(event.motion.xrel.float/200.0,
                            event.motion.yrel.float/200.0)
          of mmDrag:
            sunPosition -= camera.up * event.motion.yrel.float/30.0
            sunPosition += camera.right * event.motion.xrel.float/30.0
          of mmNone: discard
      elif event.kind == KeyDown:
        case event.key.keysym.sym:
          of K_ESCAPE:
            running = false
          of K_g:
            if wireframe:
              glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
            else:
              glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
            wireframe = not wireframe
          else: discard

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
    if keys[SDL_SCANCODE_E.uint8] == 1:
      camera.moveUp(-movementSpeed)
    elif keys[SDL_SCANCODE_Q.uint8] == 1:
      camera.moveUp(movementSpeed)

    # Update state.
    let
      secondsPassed = sdl2.getTicks().float/1000.0
      lookAtMatrix = camera.getLookAtMatrix()

    # Reload shaders.
    if shaderReloadCounter == 40:
      shaderReloadCounter = 0
      flatMeshShader.afterReload:
        U.projection.updateWith(projectionMatrix)
        U.lightColor.updateWith(vector3d(1.0, 1.0, 1.0))
    else:
      shaderReloadCounter += 1

    # Render.
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    use flatMeshShader:
      U.view.updateWith(lookAtMatrix)
      U.model.updateWith(scale(50.0))
      U.lightPosition.updateWith(sunPosition)
      flatMesh.draw()

    use sunShader:
      let sunMatrix = clearScaleRotation(sunPosition.move & lookAtMatrix)
      sunShaderModelView.updateWith(sunMatrix)
      sun.draw()

    glSwapWindow(window)

if main(): quit(1)
