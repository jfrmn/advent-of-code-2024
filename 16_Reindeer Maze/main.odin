package main

import "core:fmt"
import "core:os"
import "core:strings"

when #config(small, false) {
	INPUT_FILENAME :: "input_small.txt"
	MAP_SIZE :: 17

} else {
	INPUT_FILENAME :: "input.txt"
	MAP_SIZE :: 141
}

read_input :: proc() -> []u8 {
	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	result := make([]u8, MAP_SIZE * MAP_SIZE)
	
	entire_file_as_file := transmute(string)entire_file
	ln := 0
	for line in strings.split_lines_iterator(&entire_file_as_file) {
		copy_slice(result[MAP_SIZE * ln:], transmute([]u8)line)
		ln += 1
	}
	assert(ln == MAP_SIZE)

	return result[:]
}

PENALTY_ROTATION :: 1000
PENALTY_MOVE :: 1

Direction :: enum {
	North,
	East,
	South,
	West,
	MAX_DIRECTION
}

DIRECTION_CHANGES: [4][2]int : {{0, -1}, {1, 0}, {0, 1}, {-1, 0}}

Action :: union {
	[2]int,
	Direction
}

test_path :: proc(m: []u8, pos: [2]int, curr_dir: Direction) -> (int, [dynamic]Action, bool) {

	fmt.assertf(
		pos.x >= 0 && pos.x < MAP_SIZE && pos.y >= 0 && pos.y < MAP_SIZE,
		"pos out of bounds: %d, %d", pos.x, pos.y)

	field_value := m[pos.y * MAP_SIZE + pos.x]
	if field_value == '#' {
		return 0, [dynamic]Action{}, false
	
	} else if field_value == 'E' {
		return 0, make([dynamic]Action), true
	
	} else {
		assert(field_value == '.' || field_value == 'S')
	}

	min_score := -1
	best_path : [dynamic]Action = nil
	found_path := false

	for dirchg, di in DIRECTION_CHANGES {
		
		target_pos := [2]int{pos.x + dirchg.x, pos.y + dirchg.y}
		dir := Direction(di)

		score, path, ok := test_path(m, target_pos, dir)
		if ok {
			found_path = true

			append(&path, target_pos)
			score += PENALTY_MOVE

			if curr_dir != dir {
				append(&path, dir)
				score += PENALTY_ROTATION
			}

			if  min_score > score || min_score == -1 {
				min_score = score
				delete(best_path)
				best_path = path
			}
		}
	}
		
	return min_score, best_path, found_path
}

main :: proc() {
	input := read_input()

	i_start_pos := strings.index(transmute(string)input, "S")
	
	start_pos := [2]int{i_start_pos % MAP_SIZE, i_start_pos / MAP_SIZE}
	score, path, ok := test_path(input, start_pos, Direction.East)
	fmt.printfln("Score: %d", score)
}