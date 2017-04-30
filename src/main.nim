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

  modelMatrix.setTo(IDMATRIX)
  viewMatrix.setTo(move(0.0, 0.0, -5.0))

  # Main loop.
  var
    running = true
    wireframe = false
    event = sdl2.defaultEvent

  while running:
    # Handle events.
    while pollEvent(event):
      if event.kind == QuitEvent:
        running = false
      elif event.kind == KeyDown:
        case event.key.keysym.sym:
          of K_q, K_ESCAPE:
            running = false
          of K_w:
            if wireframe:
              glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
            else:
              glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
            wireframe = not wireframe
          else:
            # Ignore most keys.
            discard nil

    # Update state.
    modelMatrix.setTo(rotate(sdl2.getTicks().float/1000.0,
                             vector3d(0.5, 1.0, -1.0)) &
                      move(0, 0, sin(sdl2.getTicks().float/1000.0) * 5 - 3))

    # Render.
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

    withShaderProgram shaderProgram:
      glUniformMatrix4fv(modelLocation, 1, GL_FALSE, modelMatrix[0].addr)
      glUniformMatrix4fv(viewLocation, 1, GL_FALSE, viewMatrix[0].addr)
      glUniformMatrix4fv(projectionLocation, 1, GL_FALSE, projectionMatrix[0].addr)
      withVertexArrayObject vao:
        glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, nil)

    glSwapWindow(window)

if main(): quit(1)
