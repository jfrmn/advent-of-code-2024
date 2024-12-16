package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:math"
import "core:os"
import "core:slice"

when #config(small, false) {
	INPUT_FILENAME :: "input_small.txt"	
	MAP_WIDTH :: 11
	MAP_HEIGHT :: 7
} else {
	INPUT_FILENAME :: "input.txt"
	MAP_WIDTH :: 101
	MAP_HEIGHT :: 103
}

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

		remaining_line = strings.trim_prefix(remaining_line, " v=")
		// fmt.printfln("remaining_line: %s", remaining_line)
		
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

simulate :: proc(robot: ^Robot) {
	robot.position.x += robot.velocity.x
	robot.position.y += robot.velocity.y

		if robot.position.x < 0 do robot.position.x += MAP_WIDTH
	else if robot.position.x >= MAP_WIDTH do robot.position.x -= MAP_WIDTH
		if robot.position.y < 0 do robot.position.y += MAP_HEIGHT
	else if robot.position.y >= MAP_HEIGHT do robot.position.y -= MAP_HEIGHT
}

print_map :: proc(robots: []Robot) {

	buffer: [MAP_HEIGHT][MAP_WIDTH]byte
	for y in 0..<MAP_HEIGHT do slice.fill(buffer[y][:], 0)

	for &robot in robots do buffer[robot.position.y][robot.position.x] += 1
	
	for y in 0..<MAP_HEIGHT {
		for x in 0..<MAP_WIDTH {
			if buffer[y][x] > 0 do fmt.print(buffer[y][x])
			else do fmt.print(".")
		}
		fmt.print("\n")
	}
	fmt.println()
}

main :: proc() {
	input := read_input()
	defer delete(input)
	
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART I
	{
		robots := slice.clone(input)
		defer delete(robots)

		NUM_TICKS_TO_SIMULATE :: 100
		for i in 0..<NUM_TICKS_TO_SIMULATE {
			for &robot in robots do simulate(&robot)
		}

		num_robots_in_top_left_quadrant := 0
		num_robots_in_top_right_quadrant := 0
		num_robots_in_lower_left_quadrant := 0
		num_robots_in_lower_right_quadrant := 0
		num_robots_in_middle := 0

		for &robot in robots {
			
			if robot.position.x < math.floor_div(MAP_WIDTH, 2) {

				if robot.position.y < math.floor_div(MAP_HEIGHT, 2) do num_robots_in_top_left_quadrant += 1
				else if robot.position.y >= MAP_HEIGHT - math.floor_div(MAP_HEIGHT, 2) do num_robots_in_lower_left_quadrant += 1
				else do num_robots_in_middle += 1
			
			} else if robot.position.x >= MAP_WIDTH - math.floor_div(MAP_WIDTH, 2) {

				if robot.position.y < math.floor_div(MAP_HEIGHT, 2) do num_robots_in_top_right_quadrant += 1
				else if robot.position.y >= MAP_HEIGHT- math.floor_div(MAP_HEIGHT, 2) do num_robots_in_lower_right_quadrant += 1
				else do num_robots_in_middle += 1
			
			} else {
				num_robots_in_middle += 1
			}
		}

		assert(len(robots) == num_robots_in_top_left_quadrant \
			+ num_robots_in_top_right_quadrant \
			+ num_robots_in_lower_left_quadrant \
			+ num_robots_in_lower_right_quadrant \
			+ num_robots_in_middle)

		fmt.printf("Top left quadrant: %d robots\n", num_robots_in_top_left_quadrant)
		fmt.printf("Top right quadrant: %d robots\n", num_robots_in_top_right_quadrant)
		fmt.printf("Lower left quadrant: %d robots\n", num_robots_in_lower_left_quadrant)
		fmt.printf("Lower right quadrant: %d robots\n", num_robots_in_lower_right_quadrant)
		fmt.printf("Not counted: %d robots\n", num_robots_in_middle)
		fmt.printfln("Num robors total: %d", len(robots))

		safety_factor := num_robots_in_top_left_quadrant \
		* num_robots_in_top_right_quadrant \
		* num_robots_in_lower_left_quadrant \
		* num_robots_in_lower_right_quadrant

		fmt.printfln("Safety factor: %d\n", safety_factor)
	}

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART II
	{
		robots := slice.clone(input)
		defer delete(robots)

		NUM_TICKS_TO_SIMULATE :: 10000

		fmt.println()

		tick := 0
		max_straigt_line_length := 0
		robots_snapshot: []Robot

		// we search for the tick that has the longest straigt line (horizontally) of robots
		
		for i in 0..<NUM_TICKS_TO_SIMULATE {
			fmt.printf("\e[2MSimulating Tick %d/%d", i, NUM_TICKS_TO_SIMULATE)
			
			for &robot in robots do simulate(&robot)

			for y in 0..<MAP_HEIGHT {

				straigt_line_length := 0
				
				width_loop: for x in 0..<MAP_WIDTH {
					for &robot in robots {
						if robot.position.x == x && robot.position.y == y {
							straigt_line_length += 1
							continue width_loop
						}
					}
					
					if max_straigt_line_length < straigt_line_length {
						max_straigt_line_length = straigt_line_length
						tick = i
						straigt_line_length = 0
						delete(robots_snapshot)
						robots_snapshot = slice.clone(robots)
					}
				}

			}			
		}

		fmt.printf("\nStraigt line length %d\n", max_straigt_line_length)
		fmt.printf("Tick: %d\n", tick)

		print_map(robots_snapshot)
	}
}