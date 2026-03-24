package main

import rl "vendor:raylib"

Model :: struct {
	mesh:        Mesh,
	texture:     Texture,
	color:       rl.Color,
	wireColor:   rl.Color,
	translation: Vector3,
	rotation:    Vector3,
	scale:       f32,
}

LoadModel :: proc(
	meshPath: string,
	texturePath: cstring,
	color: rl.Color = rl.WHITE,
	wireColor: rl.Color = rl.GREEN,
) -> Model {
	return Model {
		mesh = LoadMeshFromObjFile(meshPath),
		texture = LoadTextureFromFile(texturePath),
		color = color,
		wireColor = wireColor,
		translation = Vector3{0, 0, 0},
		rotation = Vector3{0, 0, 0},
		scale = 1.0,
	}
}

