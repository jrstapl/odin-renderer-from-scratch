package main

// Tutorial from https://marianpekar.com/
import rl "vendor:raylib"

ApplyTransformations :: proc(transformed: ^[]Vector3, original: []Vector3, mat: Matrix4x4) {
	for i in 0 ..< len(original) {
		transformed[i] = Mat4MulVec3(mat, original[i])
	}
}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Renderer")
	// mesh := MakeCube()
	mesh := LoadMeshFromObjFile("assets/monkey.obj")
	camera := MakeCamera({0, 0, -3}, {0, 0, -1})
	translation := Vector3{0, 0, 0}
	rotation := Vector3{0, 0, 0}
	scale: f32 = 1

	zBuffer := new(ZBuffer)

	renderMode: i8 = RENDER_MODES_COUNT - 1

	projectionMatrix := MakeProjectionMatrix(
		FOV,
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
		NEAR_PLANE,
		FAR_PLANE,
	)

	light := MakeLight({0, 1, 0}, 1)

	texture := LoadTextureFromFile("assets/uv_checker_512.png")


	for !rl.WindowShouldClose() {
		deltaTime := rl.GetFrameTime()
		HandleInputs(&translation, &rotation, &scale, &renderMode, RENDER_MODES_COUNT, deltaTime)

		translationMatrix := MakeTranslationMatrix(translation.x, translation.y, translation.z)
		rotationMatrix := MakeRotationMatrix(rotation.x, rotation.y, rotation.z)
		scaleMatrix := MakeScaleMatrix(scale, scale, scale)

		modelMatrix := Mat4Mul(translationMatrix, Mat4Mul(rotationMatrix, scaleMatrix))
		viewMatrix := MakeViewMatrix(camera.position, camera.target)
		viewMatrix = Mat4Mul(viewMatrix, modelMatrix)

		ApplyTransformations(&mesh.transformedVertices, mesh.vertices, viewMatrix)

		rl.BeginDrawing()

		ClearZBuffer(zBuffer)

		switch renderMode {
		case 0:
			DrawWireframe(
				mesh.transformedVertices,
				mesh.triangles,
				projectionMatrix,
				rl.GREEN,
				false,
			)
		case 1:
			DrawWireframe(
				mesh.transformedVertices,
				mesh.triangles,
				projectionMatrix,
				rl.GREEN,
				true,
			)
		case 2:
			DrawUnlit(
				mesh.transformedVertices,
				mesh.triangles,
				projectionMatrix,
				rl.WHITE,
				zBuffer,
			)
		case 3:
			DrawFlatShaded(
				mesh.transformedVertices,
				mesh.triangles,
				projectionMatrix,
				light,
				rl.WHITE,
				zBuffer,
			)
		case 4:
			DrawTexturedUnlit(
				mesh.transformedVertices,
				mesh.triangles,
				mesh.uvs,
				texture,
				zBuffer,
				projectionMatrix,
			)
		case 5:
			DrawTexturedFlatShaded(
				mesh.transformedVertices,
				mesh.triangles,
				mesh.uvs,
				light,
				texture,
				zBuffer,
				projectionMatrix,
			)
		}


		rl.EndDrawing()
		rl.ClearBackground(rl.BLACK)
	}

	rl.CloseWindow()
}

