package main

import "core:log"
import "core:os"
import "core:strconv"
import "core:strings"

Triangle :: [9]int


Mesh :: struct {
	transformedVertices: []Vector3,
	transformedNormals:  []Vector3,
	vertices:            []Vector3,
	normals:             []Vector3,
	uvs:                 []Vector2,
	triangles:           []Triangle,
}

// there's lots of magic numbers here, but
// the cube is simple enough for it to be
// explanatory, 8 points make up
// 				6 faces which each have 1 normal and
// 				  2 triangle per face for
// 				12 triangles total
MakeCube :: proc() -> Mesh {
	vertices := make([]Vector3, 8)
	vertices[0] = Vector3{-1, -1, -1}
	vertices[1] = Vector3{-1, 1, -1}
	vertices[2] = Vector3{1, 1, -1}
	vertices[3] = Vector3{1, -1, -1}
	vertices[4] = Vector3{1, 1, 1}
	vertices[5] = Vector3{1, -1, 1}
	vertices[6] = Vector3{-1, 1, 1}
	vertices[7] = Vector3{-1, -1, 1}

	normals := make([]Vector3, 6)
	normals[0] = {0, 0, -1}
	normals[1] = {1, 0, 0}
	normals[2] = {0, 0, 1}
	normals[3] = {-1, 0, 0}
	normals[4] = {0, 1, 0}
	normals[5] = {0, -1, 0}

	uvs := make([]Vector2, 4)
	uvs[0] = Vector2{1, 1}
	uvs[1] = Vector2{1, 0}
	uvs[2] = Vector2{0, 0}
	uvs[3] = Vector2{0, 1}

	triangles := make([]Triangle, 12)
	// Front                vert.    uvs      normal
	triangles[0] = Triangle{0, 1, 2, 0, 1, 2, 0, 0, 0}
	triangles[1] = Triangle{0, 2, 3, 0, 2, 3, 0, 0, 0}
	// Right
	triangles[2] = Triangle{3, 2, 4, 0, 1, 2, 1, 1, 1}
	triangles[3] = Triangle{3, 4, 5, 0, 2, 3, 1, 1, 1}
	// Back
	triangles[4] = Triangle{5, 4, 6, 0, 1, 2, 2, 2, 2}
	triangles[5] = Triangle{5, 6, 7, 0, 2, 3, 2, 2, 2}
	// Left
	triangles[6] = Triangle{7, 6, 1, 0, 1, 2, 3, 3, 3}
	triangles[7] = Triangle{7, 1, 0, 0, 2, 3, 3, 3, 3}
	// Top
	triangles[8] = Triangle{1, 6, 4, 0, 1, 2, 4, 4, 4}
	triangles[9] = Triangle{1, 4, 2, 0, 2, 3, 4, 4, 4}
	// Bottom
	triangles[10] = Triangle{5, 7, 0, 0, 1, 2, 5, 5, 5}
	triangles[11] = Triangle{5, 0, 3, 0, 2, 3, 5, 5, 5}


	return Mesh {
		transformedVertices = make([]Vector3, 8),
		transformedNormals = make([]Vector3, 6),
		vertices = vertices,
		normals = normals,
		triangles = triangles,
		uvs = uvs,
	}
}

ParseCoord :: proc(split: []string, idx: i32) -> f32 {
	coord, ok := strconv.parse_f32(split[idx])
	if !ok {
		log.panic("Failed to parse coordinate")
	}

	return coord
}
ParseIndices :: proc(split: []string, idx: u8) -> (int, int, int) {
	indices := strings.split(split[idx], "/")

	v, okv := strconv.parse_int(indices[0])
	if !okv {
		log.panic("Failed to parse index of a vertex")
	}

	vt, okvt := strconv.parse_int(indices[1])
	if !okvt {
		log.panic("Failed to parse index of a UV")
	}

	vn, okvn := strconv.parse_int(indices[2])
	if !okvn {
		log.panic("Failed to parse index of a normal")
	}


	return v - 1, vt - 1, vn - 1


}

LoadMeshFromObjFile :: proc(filepath: string) -> Mesh {
	data, ok := os.read_entire_file(filepath, context.allocator)

	if ok != nil {
		log.panic("Failed to read file %v", filepath)
	}

	defer delete(data)

	vertices: [dynamic]Vector3
	normals: [dynamic]Vector3
	triangles: [dynamic]Triangle
	uvs: [dynamic]Vector2

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		if len(line) <= 0 {
			continue
		}
		if line[0] == '#' {
			continue
		}

		split := strings.split(line, " ")

		switch split[0] {
		case "v":
			x := ParseCoord(split, 1)
			y := ParseCoord(split, 2)
			z := ParseCoord(split, 3)
			append(&vertices, Vector3{x, y, z})
		case "vn":
			nx := ParseCoord(split, 1)
			ny := ParseCoord(split, 2)
			nz := ParseCoord(split, 3)
			append(&normals, Vector3{nx, ny, nz})
		case "vt":
			u := ParseCoord(split, 1)
			v := ParseCoord(split, 2)
			append(&uvs, Vector2{u, v})
		case "f":
			// f v1/vt1/vn1 v2/vt2/vn2 v3/vt3/vn3
			v1, vt1, vn1 := ParseIndices(split, 1)
			v2, vt2, vn2 := ParseIndices(split, 2)
			v3, vt3, vn3 := ParseIndices(split, 3)
			append(&triangles, Triangle{v1, v2, v3, vt1, vt2, vt3, vn1, vn2, vn3})
		}

	}


	return Mesh {
		transformedVertices = make([]Vector3, len(vertices)),
		transformedNormals = make([]Vector3, len(normals)),
		vertices = vertices[:],
		normals = normals[:],
		triangles = triangles[:],
		uvs = uvs[:],
	}
}

