import
  math, basic3d,
  sdl2, opengl,
  globject, mathhelpers, camera, primitivegenerator,
  shader, shaderwrapper, uniform, use

type MouseMode = enum mmNone, mmCamera, mmDrag

const
  windowW = 1024
  windowH = 768

proc castRay(mouseX, mouseY: int;
             inverseProjectionMatrix: Matrix3d,
             inverseViewMatrix: Matrix3d): Vector3d =
  let
    clipRay = vector3d(mouseX/windowW * 4.0 - 2.0,
                       2.0 - mouseY/windowH * 4.0, -1.0)
    viewRay = clipRay & inverseProjectionMatrix
  result = vector3d(viewRay.x, viewRay.y, -1.0) & inverseViewMatrix
  result.normalize()

proc collidesWithRay(origin, direction, sphere: Vector3d): bool =
  let
    distance = sphere - origin
    tca = dot(distance, direction)
    d2 = dot(distance, distance) - tca * tca

  if d2 < 1.0:
    let thc = sqrt(1 - d2)
    var
      t0 = tca - thc
      t1 = tca + thc

    if(t0 > t1):  swap(t0, t1)
    if(t0 < 0.0): t0 = t1

    result = t0 > 0

proc moveToMousePos(obj: var Vector3d;
                    camera: Camera; mouseX, mouseY: int,
                    inverseProjectionMatrix: Matrix3d,
                    inverseViewMatrix: Matrix3d) =
  let
    ray = castRay(mouseX, mouseY, inverseProjectionMatrix, inverseViewMatrix)
    distance = obj - camera.position
    projection = dot(ray, distance)/dot(ray, ray) * ray
  obj = camera.position + projection

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
  sdlAssert(glSetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 1) == 0)
  sdlAssert(glSetAttribute(SDL_GL_MULTISAMPLESAMPLES, 4) == 0)

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
  glClearColor(0.6, 0.65, 0.7, 0)
  glEnable(GL_DEPTH_TEST)
  glEnable(GL_MULTISAMPLE)

  # Setup vaos.
  let flatMesh = initFlatMesh(96)
  defer: flatMesh.destroy()

  let cylinderMesh = initCylinder(100, 0.01)
  defer: cylinderMesh.destroy()

  let sun = initCircle(18)
  defer: sun.destroy()
  var sunPosition = vector3d(1.0, 11.0, 1.0)

  # Setup transformation matrices.
  var
    projectionMatrix = perspectiveMatrix(PI/4, windowW/windowH, 1.0, 100.0)
    inverseProjectionMatrix = projectionMatrix.inverse
    camera = initCamera(0.0, 10.0, -30.0)

  # Setup shaders.
  var flatMeshShader = loadFlatMeshShader()
  defer: flatMeshShader.destroy()

  let flatMeshModelMatrix = scale(50.0)
  use flatMeshShader:
    U.model.updateWith(flatMeshModelMatrix)
    U.projection.updateWith(projectionMatrix)
    U.lightColor.updateWith(vector3d(1.0, 1.0, 1.0))

  let sunShader =
    initShader(["shader/lightsource.vert"], ["shader/lightsource.frag"])
  defer: sunShader.destroy()
  let sunShaderProjection = sunShader.getUniformLocationMat4("projection")
  let sunShaderModelView = sunShader.getUniformLocationMat4("modelView")
  let sunShaderColor = sunShader.getUniformLocationVec3("color")
  var sunColor = vector3d(1.0, 1.0, 1.0)
  use sunShader:
    sunShaderProjection.updateWith(projectionMatrix)

  let cylinderShader =
    initShader(["shader/mandelbrot.vert"], ["shader/lightsource.frag"])
  defer: cylinderShader.destroy()
  let
    cylinderModel = cylinderShader.getUniformLocationMat4("model")
    cylinderView = cylinderShader.getUniformLocationMat4("view")
    cylinderProjection = cylinderShader.getUniformLocationMat4("projection")
    cylinderColor = cylinderShader.getUniformLocationVec3("color")

  use cylinderShader:
    cylinderModel.updateWith(scale(50.0) & move(20.0, 25.0, 0.0))
    cylinderProjection.updateWith(projectionMatrix)
    cylinderColor.updateWith(sunColor)

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
            let ray =
              castRay(event.button.x, event.button.y,
                      inverseProjectionMatrix,
                      camera.getLookAtMatrix().inverse)
            if collidesWithRay(camera.position, ray, sunPosition):
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
            sunPosition.moveToMousePos(camera, event.motion.x, event.motion.y,
                                       inverseProjectionMatrix,
                                       camera.getLookAtMatrix().inverse)
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
      lookAtMatrix = camera.getLookAtMatrix()
      flatMeshNormalMatrix =
        (lookAtMatrix & flatMeshModelMatrix).inverse.transpose

    # Reload shaders.
    if shaderReloadCounter == 40:
      shaderReloadCounter = 0
      flatMeshShader.afterReload:
        U.model.updateWith(flatMeshModelMatrix)
        U.projection.updateWith(projectionMatrix)
        U.lightColor.updateWith(vector3d(1.0, 1.0, 1.0))
    else:
      shaderReloadCounter += 1

    # Render.
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    use flatMeshShader:
      U.view.updateWith(lookAtMatrix)
      U.lightPosition.updateWith(sunPosition)
      U.normalMatrix.updateWith(flatMeshNormalMatrix)
      flatMesh.draw()

    use sunShader:
      let sunMatrix = clearScaleRotation(sunPosition.move & lookAtMatrix)
      sunShaderModelView.updateWith(sunMatrix)
      sunShaderColor.updateWith(sunColor)
      sun.draw()

    use cylinderShader:
      cylinderView.updateWith(lookAtMatrix)
      cylinderMesh.draw()

    glSwapWindow(window)

if main(): quit(1)
