package main

// Tutorial from https://marianpekar.com/
import rl "vendor:raylib"


main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Renderer")

	for !rl.WindowShouldClose() {
		rl.EndDrawing()
	}

	rl.CloseWindow()
}

