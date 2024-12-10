package main

import "core:os"
import "core:strings"
import "core:fmt"

when #config(small, false) {
    INPUT_FILENAME :: "input_small.txt"
    MAP_SIZE :: 12 // both width and height
} else {
    INPUT_FILENAME :: "input.txt"
    MAP_SIZE :: 50
}

Field :: struct {
    frequency: u8,
    has_antinode: bool
}

// is_valid_coord :: proc(x, y: int) -> bool {
// 	return x >= 0 && x < MAP_SIZE && y >= 0 && y < MAP_SIZE
// }

// at :: proc(m: []Field, x: int, y: int) -> ^Field {
// 	if !is_valid_coord(x, y) do fmt.panicf("invalid coords: %d,%d", x, y)
// 	return &m[(y * MAP_SIZE) + x]
// }

// read_input :: proc() -> []Field {
// 	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
// 	if !ok do panic("failed to read input")
// 	defer delete(entire_file)

// 	result := make([]Field, MAP_SIZE * MAP_SIZE)
    
// 	y := 0
// 	entire_file_as_str := transmute(string)entire_file
// 	for line in strings.split_lines_iterator(&entire_file_as_str) {
// 		for x in 0..<len(line) {
// 			field := at(result, x, y)
// 			field.frequency = line[x] == '.' ? 0 : line[x]
// 			field.has_antinode = false
// 		}
// 		y += 1
// 	}

// 	return result
// }

Location :: struct #raw_union {
    using xy: struct {
        x: int,
        y: int
    },
    coords: [2]int
}

Antenna :: struct {
    location: Location,
    frequency: u8
}

read_input :: proc() -> []Antenna {
    entire_file, ok := os.read_entire_file(INPUT_FILENAME)
    if !ok do panic("failed to read input")
    defer delete(entire_file)

    result := make([dynamic]Antenna)
    
    y := 0
    entire_file_as_str := transmute(string)entire_file
    for line in strings.split_lines_iterator(&entire_file_as_str) {
        for x in 0..<len(line) {
            ant := Antenna{location = {xy = {x, y}}, frequency = line[x]}
            if line[x] != '.' do append(&result, ant)
        }
        y += 1
    }

    return result[:]
}

main :: proc() {

    antennas := read_input()
    defer delete(antennas)

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // PART TWO
    {
        antinodes := make(map[[2]int]byte)
        defer delete(antinodes)

        for i := 0; i < len(antennas); i += 1 {
            antenna := &antennas[i]

            // we need to compare in 'both directions' so don't do j := i
            for j := 0; j < len(antennas); j += 1 {
                if i == j do continue

                other_antenna := &antennas[j]
                if antenna.frequency == other_antenna.frequency {
                    delta_x := other_antenna.location.x - antenna.location.x
                    delta_y := other_antenna.location.y - antenna.location.y

                    target_loc := Location{xy = {other_antenna.location.x + delta_x, other_antenna.location.y + delta_y}}
                    
                    is_valid_coord := target_loc.x >= 0 && target_loc.x < MAP_SIZE \
                                && target_loc.y >= 0 && target_loc.y < MAP_SIZE
                    if !is_valid_coord do continue

                    if target_loc.coords not_in antinodes do map_insert(&antinodes, target_loc.coords, 0)
                }
            }
        }

        print_map(antinodes, antennas)
        fmt.printfln("Antinodes: %d", len(antinodes))
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // PART TWO
    {
        antinodes := make(map[[2]int]byte)
        defer delete(antinodes)

        for i := 0; i < len(antennas); i += 1 {
            antenna := &antennas[i]

            // we need to compare in 'both directions' so don't do j := i
            for j := 0; j < len(antennas); j += 1 {
                if i == j do continue

                other_antenna := &antennas[j]
                if antenna.frequency == other_antenna.frequency {
                    delta_x := other_antenna.location.x - antenna.location.x
                    delta_y := other_antenna.location.y - antenna.location.y
                    
                    if other_antenna.location.coords not_in antinodes do map_insert(&antinodes, other_antenna.location.coords, 0)
                    if       antenna.location.coords not_in antinodes do map_insert(&antinodes, antenna.location.coords, 0)

                    prev_loc := other_antenna.location
                    for {
                        target_loc := Location{xy = {prev_loc.x + delta_x, prev_loc.y + delta_y}}

                        is_valid_coord := target_loc.x >= 0 && target_loc.x < MAP_SIZE \
                                       && target_loc.y >= 0 && target_loc.y < MAP_SIZE
                        if !is_valid_coord do break

                        if target_loc.coords not_in antinodes do map_insert(&antinodes, target_loc.coords, 0)
                        prev_loc = target_loc
                    }
                }
            }
        }

        print_map(antinodes, antennas)
        fmt.printfln("Antinodes: %d", len(antinodes))
    }
}

print_map :: proc(antinode: map[[2]int]byte, antennas: []Antenna) {

    for y := 0; y < MAP_SIZE; y += 1 {		
        for x := 0; x < MAP_SIZE; x += 1 {
            loc := Location{xy = {x, y}}

            antenna: ^Antenna = nil
            for &a in antennas {
                if a.location.x == loc.x && a.location.y == loc.y {
                    antenna = &a
                    break
                }
            }

            has_antinode := loc.coords in antinode
            
            if has_antinode {
                if antenna != nil do fmt.printf("\e[31m%c\e[0m", antenna.frequency)
                else do fmt.print("\e[31m#\e[0m")
            } else {
                if antenna != nil do fmt.printf("%c", antenna.frequency)
                else do fmt.print(".")
            }
        }
        fmt.println()
    }
}