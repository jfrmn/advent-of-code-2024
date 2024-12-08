package main
import "core:os"
import "core:fmt"
import "core:strings"
import "core:time"
import "core:slice"
import "core:thread"
import "core:sync"

INPUT_FILENAME :: "input.txt"
MAP_WIDTH :: 130
MAP_HEIGHT :: 130

// INPUT_FILENAME :: "input_small.txt"
// MAP_WIDTH :: 10
// MAP_HEIGHT :: 10

Direction :: enum { North, East, South, West }

get_guard_caret :: proc(dir: Direction) -> u8 {
	switch dir {
		case .North: return '^'
		case .East:  return '>'
		case .South: return 'v'
		case .West:  return '<'
	}

	panic("unknown direction")
}

get_next_direction :: proc(dir: Direction) -> Direction {
	if  dir == Direction.West {
		return Direction.North
	} else {
		new_dir := int(dir) + 1
		return Direction(new_dir)
	}
}

get_field_coords_in_direction :: proc(x: int, y: int, dir: Direction) -> (int, int) {
	switch dir {
		case .North: return x,   y-1
		case .East:  return x+1, y
		case .South: return x,   y+1
		case .West:  return x-1, y
	}

	panic("unknown direction")
}

read_input :: proc() -> []u8 {
	handle, err := os.open(INPUT_FILENAME)
	if err != nil do fmt.panicf("failed to open file: %v", err)
	defer os.close(handle)

	m := make([]u8, MAP_WIDTH * MAP_HEIGHT)
	for i in 0..<MAP_HEIGHT {
		total_read, err := os.read(handle, m[i * MAP_WIDTH:(i+1) * MAP_WIDTH])
		if err != nil do fmt.panicf("failed to read data: %v", err)
		assert(total_read == MAP_WIDTH)

		// skip line break
		FILE_LOCALTION_CURRENT :: 1
		os.seek(handle, 2, FILE_LOCALTION_CURRENT)
	}

	return m
}

is_valid_coord :: proc(x: int, y: int) -> bool {
	return (x >= 0 && x < MAP_WIDTH) && (y >= 0 && y < MAP_HEIGHT)
}

get_field :: proc(m: []u8, x: int, y: int) -> u8 {
	if !is_valid_coord(x, y) do fmt.panicf("get_field invalid coords: %d,%d", x, y)
	return m[(y * MAP_HEIGHT) + x]
}

set_field :: proc(m: []u8, x: int, y: int, value: u8) {
	if !is_valid_coord(x, y) do fmt.panicf("set_field invalid coords: %d,%d", x, y)
	m[(y * MAP_HEIGHT) + x] = value
}

main :: proc() {
	
	when #config (show, true) do fmt.print("\e[2J\e[1;1H")

	input := read_input()
	defer delete(input)

	distinct_locations: [dynamic][2]int
	defer delete(distinct_locations)

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART ONE
	{	
		m: = slice.clone(input)
		defer delete(m)

		start := strings.index(string(m), "^")

		guard_x := start % MAP_HEIGHT
		guard_y := int(start / MAP_HEIGHT)
		guard_caret : u8 = '^'
		assert(is_valid_coord(guard_x, guard_y))

		direction := Direction.North
		
		// add startpostion
		append(&distinct_locations, [2]int{guard_x, guard_y})

		for {
			next_x, next_y := get_field_coords_in_direction(guard_x, guard_y, direction)
			if is_valid_coord(next_x, next_y) {

				field := get_field(m, next_x, next_y)
				if field == '.' || field == 'X' {
						set_field(m, guard_x, guard_y, 'X')
						set_field(m, next_x, next_y, guard_caret)
						if field == '.' do append(&distinct_locations, [2]int{next_x, next_y})
						
						guard_x, guard_y = next_x, next_y
				
				} else if field == '#' {
					direction = get_next_direction(direction)
					guard_caret = get_guard_caret(direction)
					set_field(m, guard_x, guard_y, guard_caret)
				
				} else {
					fmt.panicf("unknown fieled value: %s", field)
				}

			} else {
				set_field(m, guard_x, guard_y, 'X')
				break;
			}

			when #config (show, true) {
				fmt.print("\e[1;1H")
				for l in 0..<MAP_WIDTH {
					line := string(m[l * MAP_WIDTH:(l+1) * MAP_WIDTH])
					fmt.println(line)
				}
				
				when #config (show_timeout, 0) > 0 do time.sleep(#config (show_timeout, 0) * time.Millisecond)
			}
		}
		
		fmt.printfln("total distinct fields visited: %d", len(distinct_locations))
	}

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART TWO
	{
		m: = slice.clone(input)
		defer delete(m)

		start := strings.index(string(m), "^")
		m[start] = '.'

		start_x := start % MAP_HEIGHT
		start_y := int(start / MAP_HEIGHT)
		assert(is_valid_coord(start_x, start_y))

		direction := Direction.North

		Thread_Data :: struct {
			m: []u8,
			start_x: int,
			start_y: int,

			mtx: ^sync.Mutex,
			locations: ^[dynamic][2]int,
			locations_checked: int,

			mtx_result: ^sync.Mutex,
			result: ^[dynamic][2]int
		}

		thread_data: Thread_Data
		thread_data.m = m
		thread_data.start_x = start_x
		thread_data.start_y = start_y
		thread_data.mtx = new(sync.Mutex)
		thread_data.locations = &distinct_locations
		thread_data.locations_checked = 0
		thread_data.mtx_result = new(sync.Mutex)
		thread_data.result = new([dynamic][2]int)
		defer {
			free(thread_data.mtx)
			free(thread_data.mtx_result)
			free(thread_data.result)
		}

		NUM_THREADS :: #config (num_threads, 8)
		threads: [NUM_THREADS]^thread.Thread

		thread_proc :: proc(raw_data: rawptr) {
			
			data := cast(^Thread_Data)raw_data

			main_loop: for {
				sync.mutex_lock(data.mtx)
				if data.locations_checked == len(data.locations) {
					sync.mutex_unlock(data.mtx)
					return
				}
				
				loc_to_check_x := data.locations[data.locations_checked][0]
				loc_to_check_y := data.locations[data.locations_checked][1]
				data.locations_checked += 1
				//fmt.printfln("checking location %d,%d (%d / %d)", loc_to_check_x, loc_to_check_y, data.locations_checked, len(data.locations))
				
				sync.mutex_unlock(data.mtx)
				
				direction := Direction.North
				turns := make(map[[3]int]byte)
				defer delete(turns)

				x, y := data.start_x, data.start_y
				for {
					next_x, next_y := get_field_coords_in_direction(x, y, direction)
					if is_valid_coord(next_x, next_y) {
		
						field := get_field(data.m, next_x, next_y)
						if (next_x == loc_to_check_x && next_y == loc_to_check_y) || (field == '#') {
							
							//fmt.printfln("turns: %v", turns)
							
							key := [3]int{x, y, int(direction)}
							if key in turns {
								
								sync.mutex_lock(data.mtx_result)
								defer sync.mutex_unlock(data.mtx_result)
								
								append_elem(data.result, [2]int{loc_to_check_x, loc_to_check_y})
								fmt.println("--> is loop")

								continue main_loop
							}

							map_insert(&turns, key, 0)
							direction = get_next_direction(direction)
					
						} else if field == '.' {
							x, y = next_x, next_y
						} else {
							fmt.panicf("unknown fieled value: %s", field)
						}
					} else {
						break;
					}
				}
			}
		}

		for i in 0..<NUM_THREADS do threads[i] = thread.create_and_start_with_data(&thread_data, thread_proc, context)
		defer for t in threads do thread.destroy(t)

		thread.join_multiple(..threads[:])

		fmt.printfln("Locations with loop (%d)", len(thread_data.result))
		//fmt.printfln("Locations; %v", thread_data.result)
	}
}