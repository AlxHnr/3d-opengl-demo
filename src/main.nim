import math, basic3d, sdl2, opengl, shader, globject, mathhelpers

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
                            800, 600, SDL_WINDOW_OPENGL)
  sdlAssert(window != nil)
  defer: window.destroy()

  let glcontext = glCreateContext(window)
  sdlAssert(glcontext != nil)
  defer: glDeleteContext(glcontext)
  loadExtensions()

  block:
    var w, h: cint
    window.getSize(w, h)
    glViewport(0, 0, w, h)
    glClearColor(0, 0, 0, 0)

  # Setup triangle.
  let vertices = initArrayBuffer(0.0,  1.0,  0.0,
                                -1.0, -1.0,  0.0,
                                 1.0, -1.0,  0.0)
  defer: vertices.destroy()

  let vao = initVertexArrayObject()
  defer: vao.destroy()

  withVertexArrayObject vao:
    vertices.bindBuffer()
    glVertexAttribPointer(0, 3, cGL_Float, GL_FALSE, 3 * GLfloat.sizeof, nil)
    glEnableVertexAttribArray(0);

  # Setup shaders.
  let shaderProgram =
    loadShaderProgram("shader/simple.vert", "shader/simple.frag")
  defer: shaderProgram.destroy()

  # Setup transformation matrices.
  let transformLocation = shaderProgram.getUniformLocation("transform")
  var transformBuffer: mat4Buffer

  # Main loop.
  var
    running = true
    event = sdl2.defaultEvent

  while running:
    # Handle events.
    while pollEvent(event):
      if event.kind == QuitEvent:
        running = false
      elif event.kind == KeyDown and
          (event.key.keysym.sym == K_q or
           event.key.keysym.sym == K_ESCAPE):
        running = false

    # Update state.
    let zoomFactor = sin(sdl2.getTicks().float/200.0)/20.0 + 0.5;
    transformBuffer.setTo(scale(zoomFactor) & rotateZ(sdl2.getTicks().float/1000.0))

    # Render.
    glClear(GL_COLOR_BUFFER_BIT)

    withShaderProgram shaderProgram:
      glUniformMatrix4fv(transformLocation, 1, GL_FALSE, transformBuffer[0].addr)
      withVertexArrayObject vao:
        glDrawArrays(GL_TRIANGLES, 0, 3)

    glSwapWindow(window)

if main(): quit(1)
