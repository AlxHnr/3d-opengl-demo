import shaderutils

type ShaderProgramProc* = proc(program: ShaderProgram)
proc ignoreArgs*(program: ShaderProgram) {.procvar.} = discard program
