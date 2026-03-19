package main

// Tutorial from https://marianpekar.com/
import rl "vendor:raylib"


main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Renderer")
	mesh := MakeCube()

	for !rl.WindowShouldClose() {
		for point in mesh.vertices {
			rl.DrawPoint3D(point, rl.Color{255, 255, 255, 1})
		}

		rl.EndDrawing()
	}

	rl.CloseWindow()
}

