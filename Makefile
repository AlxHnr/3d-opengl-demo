PROGRAM = build/program

all: $(PROGRAM)
$(PROGRAM): src/*
	nim compile --nimcache:build --out:$@ src/main.nim

.PHONY: run test clean
run test: $(PROGRAM)
	./$<

clean:
	rm -rf build/
