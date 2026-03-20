package main

ZBuffer :: [SCREEN_WIDTH * SCREEN_HEIGHT]f32

ClearZBuffer :: proc(buf: ^ZBuffer) {
	for &px in buf {
		px = 999_999
	}
}

