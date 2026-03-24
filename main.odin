package main

// Tutorial from https://marianpekar.com/
import "core:log"
import rl "vendor:raylib"


ProjectionType :: enum {
	Perspective,
	Orthographic,
}


ApplyTransformations :: proc(model: ^Model, camera: Camera) {
	translationMatrix := MakeTranslationMatrix(
		model.translation.x,
		model.translation.y,
		model.translation.z,
	)
	rotationMatrix := MakeRotationMatrix(model.rotation.x, model.rotation.y, model.rotation.z)
	scaleMatrix := MakeScaleMatrix(model.scale, model.scale, model.scale)

	modelMatrix := Mat4Mul(translationMatrix, Mat4Mul(rotationMatrix, scaleMatrix))
	viewMatrix := MakeViewMatrix(camera.position, camera.target)
	viewMatrix = Mat4Mul(viewMatrix, modelMatrix)
	TransformVertices(&model.mesh.transformedVertices, model.mesh.vertices, viewMatrix)
	TransformVertices(&model.mesh.transformedNormals, model.mesh.normals, viewMatrix)
}

TransformVertices :: proc(transformed: ^[]Vector3, original: []Vector3, mat: Matrix4x4) {
	for i in 0 ..< len(original) {
		transformed[i] = Mat4MulVec3(mat, original[i])
	}
}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Renderer")
	// mesh := MakeCube()
	log.info("Loading models")
	cube := LoadModel("assets/cube.obj", "assets/box.png")
	monkey := LoadModel("assets/monkey.obj", "assets/uv_checker_512.png")

	cube.translation = {-1.25, 0.0, 0.5}
	monkey.translation = {1.5, 0, 0.5}
	monkey.rotation = {180, 0, 0}
	monkey.wireColor = rl.RED

	models := []Model{cube, monkey}

	selectedModelIdx := 0
	modelCount := len(models)
	selectedModel := &models[selectedModelIdx]

	log.info("Making Camera")
	camera := MakeCamera({0, 0, -3}, {0, 0, -1})

	zBuffer := new(ZBuffer)

	renderMode: i8 = RENDER_MODES_COUNT - 1

	projectionMatrix: Matrix4x4
	projectionType: ProjectionType = .Perspective

	log.info("Making View Matrixes")

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

	log.info("Making Lights")

	red_light := MakeLight({-4, 0, -3}, {1, 1, 0}, {1, 0, 0, 1})
	green_light := MakeLight({4, 0, -3}, {-1, -1, 0}, {0, 1, 0, 1})
	lights := []Light{red_light, green_light}
	ambient := Vector3{0.2, 0.2, 0.2}
	ambient2 := Vector3{0.1, 0.1, 0.2}


	log.info("Generating Images")
	renderImage := rl.GenImageColor(SCREEN_WIDTH, SCREEN_HEIGHT, rl.LIGHTGRAY)
	renderTexture := rl.LoadTextureFromImage(renderImage)

	log.info("Model transforms")
	for &model in models {
		ApplyTransformations(&model, camera)
	}
	log.info("Main loop entry")


	for !rl.WindowShouldClose() {
		deltaTime := rl.GetFrameTime()
		selectedModel := &models[selectedModelIdx]
		HandleInputs(
			selectedModel,
			&selectedModelIdx,
			modelCount,
			&renderMode,
			RENDER_MODES_COUNT,
			&projectionType,
			deltaTime,
		)
		ApplyTransformations(selectedModel, camera)

		switch projectionType {
		case .Perspective:
			projectionMatrix = perspectiveMatrix
		case .Orthographic:
			projectionMatrix = orthographicMatrix
		}


		rl.BeginDrawing()

		ClearZBuffer(zBuffer)

		for &model in models {

			switch renderMode {
			case 0:
				DrawWireframe(
					model.mesh.transformedVertices,
					model.mesh.triangles,
					projectionMatrix,
					projectionType,
					model.wireColor,
					false,
					&renderImage,
				)
			case 1:
				DrawWireframe(
					model.mesh.transformedVertices,
					model.mesh.triangles,
					projectionMatrix,
					projectionType,
					model.wireColor,
					true,
					&renderImage,
				)
			case 2:
				DrawUnlit(
					model.mesh.transformedVertices,
					model.mesh.triangles,
					projectionMatrix,
					projectionType,
					model.color,
					zBuffer,
					&renderImage,
				)
			case 3:
				DrawFlatShaded(
					model.mesh.transformedVertices,
					model.mesh.triangles,
					projectionMatrix,
					projectionType,
					lights,
					model.color,
					zBuffer,
					&renderImage,
					ambient,
				)
			case 4:
				DrawTexturedUnlit(
					model.mesh.transformedVertices,
					model.mesh.triangles,
					model.mesh.uvs,
					model.texture,
					zBuffer,
					projectionMatrix,
					projectionType,
					&renderImage,
				)
			case 5:
				DrawTexturedFlatShaded(
					model.mesh.transformedVertices,
					model.mesh.triangles,
					model.mesh.uvs,
					lights,
					model.texture,
					zBuffer,
					projectionMatrix,
					projectionType,
					&renderImage,
					ambient,
				)
			case 6:
				DrawPhongShaded(
					model.mesh.transformedVertices,
					model.mesh.triangles,
					model.mesh.transformedNormals,
					lights,
					model.color,
					zBuffer,
					projectionMatrix,
					projectionType,
					&renderImage,
					ambient2,
				)
			case 7:
				DrawTexturedPhongShaded(
					model.mesh.transformedVertices,
					model.mesh.triangles,
					model.mesh.uvs,
					model.mesh.transformedNormals,
					lights,
					model.texture,
					zBuffer,
					projectionMatrix,
					projectionType,
					&renderImage,
					ambient2,
				)
			}
		}


		rl.UpdateTexture(renderTexture, renderImage.data)
		rl.DrawTexture(renderTexture, 0, 0, rl.WHITE)
		rl.DrawFPS(10, 10)
		rl.EndDrawing()
		rl.ImageClearBackground(&renderImage, rl.BLACK)
	}

	rl.CloseWindow()
}

