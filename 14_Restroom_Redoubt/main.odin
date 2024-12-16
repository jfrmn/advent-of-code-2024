package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"
import "core:os"

when #config(small, false) {
	INPUT_FILENAME :: "input_small.txt"	
	MAP_WIDTH :: 11
	MAP_HEIGHT :: 7
} else {
	INPUT_FILENAME :: "input.txt"
	MAP_WIDTH :: 101
	MAP_HEIGHT :: 103
}

NUM_TICKS_TO_SIMULATE :: 100

Robot :: struct {
	position: [2]int,
	velocity: [2]int
}

read_input :: proc() -> []Robot {
	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	result := make([dynamic]Robot)

	current_robot: Robot;
	entire_file_as_file := transmute(string)entire_file
	for line in strings.split_lines_iterator(&entire_file_as_file) {
		remaining_line := strings.trim_prefix(line, "p=")

		parsed_len := 0
		current_robot.position.x, _ = strconv.parse_int(remaining_line, 10, &parsed_len)
		if parsed_len == 0 do panic("failed to parse position.x")
		remaining_line = remaining_line[parsed_len:]

		remaining_line = strings.trim_prefix(remaining_line, ",")
		
		current_robot.position.y, _ = strconv.parse_int(remaining_line, 10, &parsed_len)
		if parsed_len == 0 do panic("failed to parse position.y")
		remaining_line = remaining_line[parsed_len:]

		remaining_line = strings.trim_prefix(line, " v=")
		
		current_robot.velocity.x, _ = strconv.parse_int(remaining_line, 10, &parsed_len)
		if parsed_len == 0 do panic("failed to parse velocity.x")
		remaining_line = remaining_line[parsed_len:]

		remaining_line = strings.trim_prefix(remaining_line, ",")

		current_robot.velocity.y, _ = strconv.parse_int(remaining_line, 10, &parsed_len)
		if parsed_len == 0 do panic("failed to parse velocity.y")

		append(&result, current_robot)
	}

	return result[:]
}

main :: proc() {
	robots := read_input()

	// for i in 0..<NUM_TICKS_TO_SIMULATE {

		for &robot in robots {
			robot.position.x += robot.velocity.x * NUM_TICKS_TO_SIMULATE
			robot.position.y += robot.velocity.y * NUM_TICKS_TO_SIMULATE

			if robot.position.x < 0 do robot.position.x += MAP_WIDTH
			if robot.position.y < 0 do robot.position.y += MAP_HEIGHT
			if robot.position.x >= MAP_WIDTH do robot.position.x -= MAP_WIDTH
			if robot.position.y >= MAP_WIDTH do robot.position.y -= MAP_WIDTH
		}
	// }

	// find number of robots in each quadrant
	top_left_quad := [2]int {
		math.floor_div(MAP_WIDTH, 2),
		math.floor_div(MAP_HEIGHT, 2) }

	top_right_quad := [2]int {
		MAP_WIDTH - math.floor_div(MAP_WIDTH, 2),
		math.floor_div(MAP_HEIGHT, 2) }

	lower_left_quad := [2]int {
		math.floor_div(MAP_WIDTH, 2),
		MAP_HEIGHT - math.floor_div(MAP_HEIGHT, 2) }

	lower_right_quad := [2]int {
		MAP_WIDTH - math.floor_div(MAP_WIDTH, 2),
		MAP_HEIGHT - math.floor_div(MAP_HEIGHT, 2) }

	num_robots_in_top_left_quadrant := 0
	num_robots_in_top_right_quadrant := 0
	num_robots_in_lower_left_quadrant := 0
	num_robots_in_lower_right_quadrant := 0
	num_robots_in_middle := 0

	for &robot in robots {
		
		if robot.position.x < math.floor_div(MAP_WIDTH, 2) {

			if robot.position.x < math.floor_div(MAP_HEIGHT, 2) do num_robots_in_top_left_quadrant += 1
			else if robot.position.x < MAP_HEIGHT- math.floor_div(MAP_HEIGHT, 2) do num_robots_in_lower_left_quadrant += 1
			else do num_robots_in_middle += 1
		
		} else if robot.position.x < MAP_WIDTH - math.floor_div(MAP_WIDTH, 2) {

			if robot.position.x < math.floor_div(MAP_HEIGHT, 2) do num_robots_in_top_right_quadrant += 1
			else if robot.position.x < MAP_HEIGHT- math.floor_div(MAP_HEIGHT, 2) do num_robots_in_lower_right_quadrant += 1
			else do num_robots_in_middle += 1
		
		} else {
			num_robots_in_middle += 1
		}
	}

	fmt.printf("Top left quadrant: %d robots\n", num_robots_in_top_left_quadrant)
	fmt.printf("Top right quadrant: %d robots\n", num_robots_in_top_right_quadrant)
	fmt.printf("Lower left quadrant: %d robots\n", num_robots_in_lower_left_quadrant)
	fmt.printf("Lower right quadrant: %d robots\n", num_robots_in_lower_right_quadrant)
	fmt.printfln("Not counted: %d robots", num_robots_in_middle)
}