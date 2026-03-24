package main

// Tutorial from https://marianpekar.com/
import rl "vendor:raylib"


ProjectionType :: enum {
	Perspective,
	Orthographic,
}


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

	projectionMatrix: Matrix4x4
	projectionType: ProjectionType = .Perspective

	perspectiveMatrix := MakePerspectiveMatrix(
		FOV,
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
		NEAR_PLANE,
		FAR_PLANE,
	)
	orthographicMatrix := MakeOrthographicMatrix(
		SCREEN_WIDTH,
		SCREEN_HEIGHT,
		NEAR_PLANE,
		FAR_PLANE,
	)

	light := MakeLight(camera.position, {0, 1, 0}, 1)

	renderImage := rl.GenImageColor(SCREEN_WIDTH, SCREEN_HEIGHT, rl.LIGHTGRAY)
	renderTexture := rl.LoadTextureFromImage(renderImage)
	texture := LoadTextureFromFile("assets/uv_checker_512.png")


	for !rl.WindowShouldClose() {
		deltaTime := rl.GetFrameTime()
		HandleInputs(
			&translation,
			&rotation,
			&scale,
			&renderMode,
			RENDER_MODES_COUNT,
			&projectionType,
			deltaTime,
		)

		switch projectionType {
		case .Perspective:
			projectionMatrix = perspectiveMatrix
		case .Orthographic:
			projectionMatrix = orthographicMatrix
		}

		translationMatrix := MakeTranslationMatrix(translation.x, translation.y, translation.z)
		rotationMatrix := MakeRotationMatrix(rotation.x, rotation.y, rotation.z)
		scaleMatrix := MakeScaleMatrix(scale, scale, scale)

		modelMatrix := Mat4Mul(translationMatrix, Mat4Mul(rotationMatrix, scaleMatrix))
		viewMatrix := MakeViewMatrix(camera.position, camera.target)
		viewMatrix = Mat4Mul(viewMatrix, modelMatrix)

		ApplyTransformations(&mesh.transformedVertices, mesh.vertices, viewMatrix)
		ApplyTransformations(&mesh.transformedNormals, mesh.vertices, viewMatrix)

		rl.BeginDrawing()

		ClearZBuffer(zBuffer)

		switch renderMode {
		case 0:
			DrawWireframe(
				mesh.transformedVertices,
				mesh.triangles,
				projectionMatrix,
				projectionType,
				rl.GREEN,
				false,
				&renderImage,
			)
		case 1:
			DrawWireframe(
				mesh.transformedVertices,
				mesh.triangles,
				projectionMatrix,
				projectionType,
				rl.GREEN,
				true,
				&renderImage,
			)
		case 2:
			DrawUnlit(
				mesh.transformedVertices,
				mesh.triangles,
				projectionMatrix,
				projectionType,
				rl.WHITE,
				zBuffer,
				&renderImage,
			)
		case 3:
			DrawFlatShaded(
				mesh.transformedVertices,
				mesh.triangles,
				projectionMatrix,
				projectionType,
				light,
				rl.WHITE,
				zBuffer,
				&renderImage,
			)
		case 4:
			DrawTexturedUnlit(
				mesh.transformedVertices,
				mesh.triangles,
				mesh.uvs,
				texture,
				zBuffer,
				projectionMatrix,
				projectionType,
				&renderImage,
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
				projectionType,
				&renderImage,
			)
		case 6:
			DrawPhongShaded(
				mesh.transformedVertices,
				mesh.triangles,
				mesh.transformedNormals,
				light,
				rl.WHITE,
				zBuffer,
				projectionMatrix,
				projectionType,
				&renderImage,
			)
		case 7:
			DrawTexturedPhongShaded(
				mesh.transformedVertices,
				mesh.triangles,
				mesh.uvs,
				mesh.transformedNormals,
				light,
				texture,
				zBuffer,
				projectionMatrix,
				projectionType,
				&renderImage,
			)
		}


		rl.UpdateTexture(renderTexture, renderImage.data)
		rl.DrawTexture(renderTexture, 0, 0, rl.WHITE)
		rl.DrawFPS(10, 10)
		rl.EndDrawing()
		rl.ImageClearBackground(&renderImage, rl.BLACK)
	}

	rl.CloseWindow()
}

