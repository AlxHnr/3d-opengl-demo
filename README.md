![screenshot](https://user-images.githubusercontent.com/8235638/99920644-20aa3e80-2d25-11eb-8d76-6e4a5db908a3.png)

Basic 3D OpenGL demo with a first-person camera. Shaders are (re)loaded at runtime to allow live
editing.

# Building and running the demo

Requires Nim (0.17.0 or higher), SDL2 (with development files) and its Nim bindings:

```sh
nimble install basic3d sdl2 opengl
```

Build and run the demo:

```sh
make run
```

## Controls

* **W** - Move forward
* **A** - Move left
* **S** - Move back
* **D** - Move right
* **Q** - Move up
* **E** - Move down
* **G** - Toggle wireframe
* **hold space** - Fast movement
* **hold shift** - Slow movement
* **drag left mouse button** - Move sun or spline points
* **drag right mouse button** - Rotate camera

# Screenshots

![screenshot](https://user-images.githubusercontent.com/8235638/99920641-1e47e480-2d25-11eb-840b-cdbb745e1a48.gif)
![screenshot](https://user-images.githubusercontent.com/8235638/99920646-2142d500-2d25-11eb-966e-7eba73887e1e.png)
![screenshot](https://user-images.githubusercontent.com/8235638/99920647-21db6b80-2d25-11eb-94da-29b75a695795.png)

## git checkout c46d988

![screenshot](https://user-images.githubusercontent.com/8235638/99920648-230c9880-2d25-11eb-9532-9d8a642dbc93.png)

## git checkout be9d0c0

![screenshot](https://user-images.githubusercontent.com/8235638/99920649-230c9880-2d25-11eb-92f9-b48e3c3bdb01.png)
