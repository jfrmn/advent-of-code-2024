package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:time"
import "core:slice"

when #config(small, false) {
	INPUT_FILENAME :: "input_small.txt"
	MAP_SIZE :: 10

} else {
	INPUT_FILENAME :: "input.txt"
	MAP_SIZE :: 50
}

// these values are used for part II
MAP_WIDTH :: MAP_SIZE * 2
MAP_HEIGHT :: MAP_SIZE

SIMULATION_SPEED :: #config(simulation_speed, 1000)


read_input :: proc() -> ([]u8, []u8) {
	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	result_map := make([]u8, MAP_SIZE * MAP_SIZE)
	result_movements := make([dynamic]u8)
	
	entire_file_as_file := transmute(string)entire_file

	ln := 0
	for line in strings.split_lines_iterator(&entire_file_as_file) {
		if ln < MAP_SIZE {
			copy_slice(result_map[MAP_SIZE * ln:], transmute([]u8)line)
		
		} else {
			append_elems(&result_movements, ..transmute([]u8)line)
		}
		
		ln += 1
	}

	return result_map, result_movements[:]
}

coords_to_index :: proc(pos: [2]int, w: int = MAP_SIZE) -> int {
	return pos.y * w + pos.x
}

move :: proc(m: ^[]u8, pos: [2]int, movement: u8) -> ([2]int, bool) {
	pos_i := coords_to_index(pos)
	source_field := m[pos_i]
	
	new_pos := pos
	if movement == '^' do new_pos.y -= 1
	else if movement == 'v' do new_pos.y += 1
	else if movement == '<' do new_pos.x -= 1
	else if movement == '>' do new_pos.x += 1
	else do fmt.panicf("invalid movement: %c", movement)

	// map is surrounded by walls so this should never happen
	if !(new_pos.x >= 0 && new_pos.x < MAP_SIZE && new_pos.y >= 0 && new_pos.y < MAP_SIZE) {
		assert(false)
	}

	new_pos_i := coords_to_index(new_pos)
	if m[new_pos_i] == '#' {
		return pos, false
	
	} else if m[new_pos_i] == 'O' {
		_, ok := move(m, new_pos, movement)
		if !ok do return pos, false

		m[new_pos_i] = source_field
		m[pos_i] = '.'
		return new_pos, true

	} else if m[new_pos_i] == '.' {
		m[new_pos_i] = source_field
		m[pos_i] = '.'
		return new_pos, true
	
	} else {
		fmt.panicf("invalid field: %c", m[new_pos_i])
	}
}

get_target_pos :: proc(source_pos: [2]int, movement: u8) -> [2]int {
	target_pos := source_pos
	if movement == '^' do target_pos.y -= 1
	else if movement == 'v' do target_pos.y += 1
	else if movement == '<' do target_pos.x -= 1
	else if movement == '>' do target_pos.x += 1
	else do fmt.panicf("invalid movement: %c", movement)

	// map is surrounded by walls so this should never happen
	if !(target_pos.x >= 0 && target_pos.x < MAP_WIDTH && target_pos.y >= 0 && target_pos.y < MAP_HEIGHT) {
		assert(false)
	}

	return target_pos
}

get_pos_other_box_half :: proc(box_frag: u8, source_pos: [2]int) -> [2]int {
	pos_other_half := source_pos
	if box_frag == '[' do pos_other_half.x += 1
	else do pos_other_half.x -= 1

	return pos_other_half
}

movement_is_possible :: proc(m: []u8, source_pos: [2]int, movement: u8) -> bool {

	target_pos := get_target_pos(source_pos, movement)

	target_pos_i := coords_to_index(target_pos, MAP_WIDTH)
	if m[target_pos_i] == '#' {
		return false
	
	} else if m[target_pos_i] == '[' || m[target_pos_i] == ']' {

		ok: bool
		if movement == '^' || movement == 'v' {
			pos_other_half := get_pos_other_box_half(m[target_pos_i], target_pos)
			movement_is_possible(m, pos_other_half, movement) or_return
		}
		
		movement_is_possible(m, target_pos, movement) or_return
		return true

	} else if m[target_pos_i] == '.' {
		return true
	
	} else {
		fmt.panicf("invalid field: %c", m[target_pos_i])
	}
}

move_2 :: proc(m: ^[]u8, source_pos: [2]int, movement: u8) -> [2]int {
	
	source_i := coords_to_index(source_pos, MAP_WIDTH)
	source_field := m[source_i]

	target_pos := get_target_pos(source_pos, movement)
	target_i := coords_to_index(target_pos, MAP_WIDTH)

	if m[target_i] == '[' || m[target_i] == ']'  {
		
		ok: bool
		if movement == '^' || movement == 'v' {
			pos_other_half := get_pos_other_box_half(m[target_i], target_pos)
			move_2(m, pos_other_half, movement)
		}
		
		move_2(m, target_pos, movement)
		m[target_i] = source_field
		m[source_i] = '.'
		return target_pos

	} else if m[target_i] == '.' {
		m[target_i] = source_field
		m[source_i] = '.'
		return target_pos
	
	} else {
		fmt.panicf("can't move to field: %d,%d (%c)", target_pos.x, target_pos.y, m[target_i])
	}
}

move_if_possible :: proc(m: ^[]u8, pos: [2]int, movement: u8) -> ([2]int, bool) {
	
	if !movement_is_possible(m^, pos, movement) {
		return pos, false
	} else {
		return move_2(m, pos, movement), true
	}
	
}

print_map :: proc(m: []u8, w: int, h: int) {
	for y in 0..<h {
		for x in 0..<w {
			field := m[coords_to_index({x, y}, w)]
			if field == '@' do fmt.print("\e[31m@")
			else if field == '#' do fmt.print("\e[34m#")
			else if field == 'O' do fmt.print("\e[32mO")
			else if field == '[' do fmt.print("\e[32m[")
			else if field == ']' do fmt.print("\e[32m]")
			else if field == '.' do fmt.print("\e[0m.")
			else do fmt.printf("\e[91m%c", field)
		}
		fmt.println("\e[0m")
	}
}

main :: proc() {
	input_map, movements := read_input()
	defer {
		delete(input_map)
		delete(movements)
	}
	
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART I
	{
		m := slice.clone(input_map)
		defer delete(m)

		// find inital robot position
		robot_pos := [2]int{0, 0}
		for field, i in m {
			if field == '@' {
				robot_pos.x = i % MAP_SIZE
				robot_pos.y = i / MAP_SIZE
				break
			}
		}

		fmt.println("Inital state:")
		print_map(m, MAP_SIZE, MAP_SIZE)

		for movement, im in movements {

			new_pos, _ := move(&m, robot_pos, movement)
			robot_pos = new_pos

			when #config(simulate_part_1, false) {
				fmt.print("\e[2J\e[1;1H")
				fmt.printfln("movement: %c (%d / %d)", movement, im + 1, len(movements))
				print_map(m)
				time.sleep(SIMULATION_SPEED * time.Millisecond)
			}
		}

		fmt.println("final state:")
		print_map(m, MAP_SIZE, MAP_SIZE)

		gps_score := 0
		for i in 0..<len(m) {
			if m[i] == 'O' {
				x := i % MAP_SIZE
				y := i / MAP_SIZE
				gps_score += x + (y * 100)			
			}
		}

		fmt.printfln("gps score: %d", gps_score)
	}

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART II
	{
		// change map accoring to rules
		m := make([]u8, MAP_WIDTH * MAP_HEIGHT)
		defer delete(m)

		i_input, i_m := 0, 0
		for y in 0..<MAP_SIZE {
			for x in 0..<MAP_SIZE {
				f := input_map[i_input]
				if f == '@' {
					m[i_m] = '@'
					m[i_m+1] = '.'

				} else if f == 'O' {
					m[i_m] = '['
					m[i_m+1] = ']'
				
				} else {
					m[i_m] = f
					m[i_m+1] = f
				}

				i_input += 1
				i_m += 2
			}
		}

		robot_pos := [2]int{0, 0}
		for field, i in m {
			if field == '@' {
				robot_pos.x = i % MAP_WIDTH
				robot_pos.y = i / MAP_WIDTH
				break
			}
		}

		fmt.println("Inital state:")
		print_map(m, MAP_WIDTH, MAP_HEIGHT)

		for movement, im in movements {

			new_pos, _ := move_if_possible(&m, robot_pos, movement)
			robot_pos = new_pos

			when #config(simulate_part_2, false) {
				fmt.print("\e[2J\e[1;1H")
				fmt.printfln("movement: %c (%d / %d)", movement, im + 1, len(movements))
				print_map(m, MAP_WIDTH, MAP_HEIGHT)
				time.sleep(SIMULATION_SPEED * time.Millisecond)
			}

			j := 0
			for y in 0..<MAP_HEIGHT {
				for x in 0..<MAP_WIDTH-1 {
					if m[j] == '[' {
						if (m[j+1] != ']') {
							fmt.printfln("Invalid map after move movement %d ('%c'):", im, movement)
							print_map(m, MAP_WIDTH, MAP_HEIGHT)
							panic("invalid map")							
						}
					}

					j += 1
				}
			}
		}

		fmt.println("final state:")
		print_map(m, MAP_WIDTH, MAP_HEIGHT)

		gps_score := 0
		for i in 0..<len(m) {
			if m[i] == '[' {
				x := i % MAP_WIDTH
				y := i / MAP_WIDTH
				gps_score += x + (y * 100)			
			}
		}

		fmt.printfln("gps score: %d", gps_score)
	}
}