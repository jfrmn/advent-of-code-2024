package main

import "core:os"
import "core:fmt"

MAX_HEIGHT :: 9

when #config(small, false) {
	// INPUT_FILENAME :: "input_small_2.txt"
	// MAP_SIZE :: 7
	INPUT_FILENAME :: "input_small.txt"
	MAP_SIZE :: 8
} else {
	INPUT_FILENAME :: "input.txt"
	MAP_SIZE :: 55
}

read_input :: proc() -> []u8 {
	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	result := make([dynamic]u8)
	for c in entire_file {
		if c == '\n' || c == '\r' do continue
		
		// for testing...
		if c == '.' {
			append(&result, u8(255))
			continue
		}

		assert(c >= '0' && c <= '9')
		append(&result, (c - '0'))
	}

	assert(len(result) == MAP_SIZE*MAP_SIZE)
	return result[:]
}

can_tranvel_to :: proc(m: []u8, x: int, y: int, h: u8) -> bool {
	if x < 0 || x >= MAP_SIZE || y < 0 || y >= MAP_SIZE do return false
	
	height := m[(y * MAP_SIZE) + x]
	if height != (h + 1) do return false
	
	return true
}

check_path :: proc(m: []u8, p: ^map[[2]int]byte, x: int, y: int, h: u8) -> int {

	if h == MAX_HEIGHT {

		if p != nil {
			key := [2]int{x, y}
			if key in p {
				return 0
			} else {
				map_insert(p, key, 0);
				return 1
			}

		} else {
			return 1
		}
	}

	score := 0

	// check north
	if can_tranvel_to(m, x, y - 1, h) {
		score += check_path(m, p, x, y - 1, h + 1)
	}
	
	// check east
	if can_tranvel_to(m, x + 1, y, h) {
		score += check_path(m, p, x + 1, y, h + 1)
	}
	
	// check south
	if can_tranvel_to(m, x, y + 1, h) {
		score += check_path(m, p, x, y + 1, h + 1)
	}
	
	// check west
	if can_tranvel_to(m, x - 1, y, h) {
		score += check_path(m, p, x - 1, y, h + 1)
	}
	
	return score
}

main :: proc() {

	m := read_input()
	defer delete(m)
	
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART ONE
	{
		sum := 0
		for i in 0..<len(m) {
			if m[i] != 0 do continue

			y := int(i / MAP_SIZE)
			x := i % MAP_SIZE
			reached_peaks := make(map[[2]int]byte)
			defer delete(reached_peaks)

			score := check_path(m, &reached_peaks, x, y, 0)
			sum += score

			// fmt.printfln("xy: %d,%d - score: %d - peaks: %v", x, y, score, reached_peaks)

			// sanity check
			for k, _ in reached_peaks {
				idx := (k[1] * MAP_SIZE) + k[0]
				if m[idx] != MAX_HEIGHT {
					fmt.panicf("(%d) %d,%d != 9", idx, k[0], k[1])
				}
			}
		}

		fmt.printfln("sum: %d", sum)
	}

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART TWO
	{
		// same as part one but we don't check which peaks we have already reached...

		sum := 0
		for i in 0..<len(m) {
			if m[i] != 0 do continue

			y := int(i / MAP_SIZE)
			x := i % MAP_SIZE
			score := check_path(m, nil, x, y, 0)
			sum += score
		}

		fmt.printfln("sum: %d", sum)
	}

}