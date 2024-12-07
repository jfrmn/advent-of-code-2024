package main
import "core:os"
import "core:fmt"
import "core:strings"
import "core:time"

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
	
	when #config (simulate, true) do fmt.print("\e[2J\e[1;1H")

	m := read_input()
	defer delete(m)

	// find start pos
	start := strings.index(string(m), "^")

	guard_x := start % MAP_HEIGHT
	guard_y := int(start / MAP_HEIGHT)
	guard_caret : u8 = '^'
	assert(is_valid_coord(guard_x, guard_y))

	direction := Direction.North

	total_distinct_fields_visited := 0
	for {
		next_x, next_y := get_field_coords_in_direction(guard_x, guard_y, direction)
		if is_valid_coord(next_x, next_y) {

			field := get_field(m, next_x, next_y)
			if field == '.' || field == 'X' {
					set_field(m, guard_x, guard_y, 'X')
					set_field(m, next_x, next_y, guard_caret)
					guard_x, guard_y = next_x, next_y

					if field == '.' do total_distinct_fields_visited += 1
			
			} else if field == '#' {
				if  direction == Direction.West {
					direction = Direction.North
				} else {
					new_dir := int(direction) + 1
					direction = Direction(new_dir)
				}

				guard_caret = get_guard_caret(direction)
				set_field(m, guard_x, guard_y, guard_caret)
			
			} else {
				fmt.panicf("unknown fieled value: %s", field)
			}

		} else {
			set_field(m, guard_x, guard_y, 'X')
			total_distinct_fields_visited += 1
			break;
		}

		when #config (simulate, true) {
			fmt.print("\e[1;1H")
			for l in 0..<MAP_WIDTH {
				line := string(m[l * MAP_WIDTH:(l+1) * MAP_WIDTH])
				fmt.println(line)
			}
			//time.sleep(200 * time.Millisecond)
		}
	}

	fmt.printfln("total distinct fields visited: %d", total_distinct_fields_visited)
}