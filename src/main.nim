import
  algorithm, math, basic3d,
  sdl2, opengl,
  globject, mathhelpers, camera, primitivegenerator,
  shader, shaderwrapper, uniform, use, spline

type MouseMode = enum
  mmNone, mmCamera, mmDragSun, mmDragBezier, mmDragSpline

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

proc toPoint3d(v: Vector3d): Point3d = point3d(v.x, v.y, v.z)
proc toVector3d(p: Point3d): Vector3d = vector3d(p.x, p.y, p.z)

proc invertVec3dArray(points: array[4, Vector3d], inverseMatrix: Matrix3d):
                      array[4, Point3d] =
  [
    points[0].toPoint3d & inverseMatrix,
    points[1].toPoint3d & inverseMatrix,
    points[2].toPoint3d & inverseMatrix,
    points[3].toPoint3d & inverseMatrix,
  ]

proc invertControlPoints(points: array[4, Vector3d],
                         inverseMatrix: Matrix3d): Matrix3d =
  let inverted = points.invertVec3dArray(inverseMatrix)
  matrix3d(
    inverted[0].x, inverted[0].y, 0.0, 0.0,
    inverted[1].x, inverted[1].y, 0.0, 0.0,
    inverted[2].x, inverted[2].y, 0.0, 0.0,
    inverted[3].x, inverted[3].y, 0.0, 0.0)

proc controlPointsToSpline(points: array[4, Vector3d],
                           inverseMatrix: Matrix3d): Spline =
  var inverted = points.invertVec3dArray(inverseMatrix)
  inverted.sort do(a: Point3d, b: Point3d) -> int:
    if a.x < b.x: -1
    elif a.x > b.x: 1
    else: 0
  newSpline([
      vector3d(inverted[0].x, inverted[0].y, 0.0),
      vector3d(inverted[1].x, inverted[1].y, 0.0),
      vector3d(inverted[2].x, inverted[2].y, 0.0),
      vector3d(inverted[3].x, inverted[3].y, 0.0)
    ])

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
  let flatMesh = initFlatMesh(128)
  defer: flatMesh.destroy()

  let cylinderMesh = initCylinder(100, 0.02)
  defer: cylinderMesh.destroy()

  let circle = initCircle(18)
  defer: circle.destroy()
  var sunPosition = vector3d(0.0, 90.0, -90.0)

  # Setup transformation matrices.
  var
    projectionMatrix = perspectiveMatrix(PI/4, windowW/windowH, 1.0, 100.0)
    inverseProjectionMatrix = projectionMatrix.inverse
    camera = initCamera(0.0, 40.0, -30.0)

  # Setup shaders.
  let
    flatMeshModelMatrix = scale(500.0)
    flatMeshShaderUpdate = proc(U: UniformLocations) =
      U.model.updateWith(flatMeshModelMatrix)
      U.projection.updateWith(projectionMatrix)
      U.lightColor.updateWith(vector3d(1.0, 1.0, 1.0))
      U.color.updateWith(vector3d(0.51, 0.7, 0.27))

  var flatMeshShader =
    loadShaderWrapper(["shader/flatmesh.vert"],
                      ["shader/reflective.frag"],
                      flatMeshShaderUpdate)
  defer: flatMeshShader.destroy()

  let sunShader = initShader(["shader/lightsource.vert"],
                             ["shader/lightsource.frag"])

  defer: sunShader.destroy()
  let sunShaderProjection = sunShader.getUniformLocationMat4("projection")
  let sunShaderModelView = sunShader.getUniformLocationMat4("modelView")
  let sunShaderColor = sunShader.getUniformLocationVec3("color")
  var sunColor = vector3d(1.0, 1.0, 1.0)
  use sunShader:
    sunShaderProjection.updateWith(projectionMatrix)

  let
    x3ModelMatrix = scale(50.0) & move(180.0, 65.0, 0.0)
    bezierModelMatrix = scale(50.0) & move(-180.0, 65.0, 0.0)
    inverseBezierModelMatrix = bezierModelMatrix.inverse
    splineModelMatrix = scale(50.0) & move(0.0, 65.0, 0.0)
    inverseSplineModelMatrix = splineModelMatrix.inverse
    curveShaderUpdate = proc(U: UniformLocations) =
      U.projection.updateWith(projectionMatrix)
      U.lightColor.updateWith(sunColor)

  var curveShader = loadShaderWrapper(["shader/curve.vert"],
                                      ["shader/reflective.frag"],
                                      curveShaderUpdate)
  defer: curveShader.destroy()
  use curveShader:
    U.model.updateWith(x3ModelMatrix)
    U.color.updateWith(vector3d(0.8, 1/3, 1/3))

  var bezierShader = loadShaderWrapper(["shader/bezier.vert"],
                                       ["shader/reflective.frag"],
                                       curveShaderUpdate)
  defer: bezierShader.destroy()
  use bezierShader:
    U.model.updateWith(bezierModelMatrix)
    U.color.updateWith(vector3d(1/3, 1/3, 0.8))

  var controllPointColor = vector3d(225.0, 65.0, 105.0)/255
  var bezierPoints =
    [
      (point3d(-1.0, -1.0, 0.0) & bezierModelMatrix).toVector3d,
      (point3d(-1.0,  1.0, 0.0) & bezierModelMatrix).toVector3d,
      (point3d( 1.0,  1.0, 0.0) & bezierModelMatrix).toVector3d,
      (point3d( 1.0, -1.0, 0.0) & bezierModelMatrix).toVector3d,
    ]

  var splineShader = loadShaderWrapper(["shader/spline.vert"],
                                       ["shader/reflective.frag"],
                                       curveShaderUpdate)
  defer: splineShader.destroy()
  use splineShader:
    U.model.updateWith(splineModelMatrix)
    U.color.updateWith(vector3d(218, 165, 32)/255.0)

  var splinePoints =
    [
      (point3d(-1.0, -1.0, 0.0) & splineModelMatrix).toVector3d,
      (point3d(-0.5,  0.5, 0.0) & splineModelMatrix).toVector3d,
      (point3d( 0.2, -0.5, 0.0) & splineModelMatrix).toVector3d,
      (point3d( 1.0,  1.0, 0.0) & splineModelMatrix).toVector3d,
    ]
  var dummySpline =
    splinePoints.controlPointsToSpline(inverseSplineModelMatrix)

  var draggedSphereIndex = 0

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
              mouseMode = mmDragSun
            else:
              for i, point in bezierPoints:
                if collidesWithRay(camera.position, ray, point):
                  draggedSphereIndex = i
                  mouseMode = mmDragBezier
                  break
              for i, point in splinePoints:
                if collidesWithRay(camera.position, ray, point):
                  draggedSphereIndex = i
                  mouseMode = mmDragSpline
                  break
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
          of mmDragSun:
            sunPosition.moveToMousePos(camera, event.motion.x, event.motion.y,
                                       inverseProjectionMatrix,
                                       camera.getLookAtMatrix().inverse)
          of mmDragBezier:
            bezierPoints[draggedSphereIndex]
            .moveToMousePos(camera, event.motion.x, event.motion.y,
                            inverseProjectionMatrix,
                            camera.getLookAtMatrix().inverse)
            bezierPoints[draggedSphereIndex].z = 0.0
          of mmDragSpline:
            splinePoints[draggedSphereIndex]
            .moveToMousePos(camera, event.motion.x, event.motion.y,
                            inverseProjectionMatrix,
                            camera.getLookAtMatrix().inverse)
            splinePoints[draggedSphereIndex].z = 0.0
            dummySpline =
              splinePoints.controlPointsToSpline(inverseSplineModelMatrix)
          of mmNone: discard
      elif event.kind == KeyDown:
        case event.key.keysym.sym:
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
      x3NormalMatrix =
        (lookAtMatrix & x3ModelMatrix).inverse.transpose
      bezierNormalMatrix =
        (lookAtMatrix & bezierModelMatrix).inverse.transpose
      splineNormalMatrix =
        (lookAtMatrix & splineModelMatrix).inverse.transpose

    # Reload shaders.
    if shaderReloadCounter == 40:
      shaderReloadCounter = 0
      flatMeshShader.tryReload()
      bezierShader.tryReload()
      splineShader.tryReload()
      curveShader.tryReload()
    else:
      shaderReloadCounter += 1

    # Render.
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    use flatMeshShader:
      U.view.updateWith(lookAtMatrix)
      U.lightPosition.updateWith(sunPosition)
      U.normalMatrix.updateWith(flatMeshNormalMatrix)
      flatMesh.draw()

    use curveShader:
      U.view.updateWith(lookAtMatrix)
      U.lightPosition.updateWith(sunPosition)
      U.normalMatrix.updateWith(x3NormalMatrix)
      cylinderMesh.draw()

    use bezierShader:
      U.view.updateWith(lookAtMatrix)
      U.lightPosition.updateWith(sunPosition)
      U.normalMatrix.updateWith(bezierNormalMatrix)
      U.bezierPoints.updateWith(
        bezierPoints.invertControlPoints(inverseBezierModelMatrix))
      cylinderMesh.draw()

    use splineShader:
      U.view.updateWith(lookAtMatrix)
      U.lightPosition.updateWith(sunPosition)
      U.normalMatrix.updateWith(splineNormalMatrix)
      U.updateSplineLocations(dummySpline)
      cylinderMesh.draw()

    glDisable(GL_DEPTH_TEST)
    use sunShader:
      let sunMatrix = clearScaleRotation(sunPosition.move & lookAtMatrix)
      sunShaderModelView.updateWith(sunMatrix)
      sunShaderColor.updateWith(sunColor)
      circle.draw()

      sunShaderColor.updateWith(controllPointColor)
      for point in splinePoints:
        let pointMatrix = clearScaleRotation(point.move & lookAtMatrix)
        sunShaderModelView.updateWith(pointMatrix)
        circle.draw()
      for point in bezierPoints:
        let pointMatrix = clearScaleRotation(point.move & lookAtMatrix)
        sunShaderModelView.updateWith(pointMatrix)
        circle.draw()
    glEnable(GL_DEPTH_TEST)

    glSwapWindow(window)

if main(): quit(1)
