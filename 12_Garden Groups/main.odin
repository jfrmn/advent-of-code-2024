package main

import "core:os"
import "core:strings"
import "core:math"
import "core:fmt"
import "core:slice"

when #config(small, false) {
	INPUT_FILENAME :: "input_small.txt"
	MAP_SIZE :: 10
} else {
	INPUT_FILENAME :: "input.txt"
	MAP_SIZE :: 140
}

read_input :: proc() -> []u8 {
	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	result := make([dynamic]u8)

	entire_file_as_str := transmute(string)entire_file
	for line in strings.split_lines_iterator(&entire_file_as_str) {
		append(&result, line)
	}

	return result[:]
}

location_from_index :: proc(index: int) -> (x: int, y: int) {
	x = index % MAP_SIZE
	y = math.floor_div(index, MAP_SIZE)
	return x, y
}

location_to_index :: proc(x, y: int) -> (int, bool) {
	if x < 0 || x >= MAP_SIZE || y < 0 || y >= MAP_SIZE do return -1, false
	else do return (y * MAP_SIZE) + x, true
}

Cluster :: struct {
	id: int,
	letter: u8,
	color: int,
	boundingbox: [dynamic][3]int, // Set of x, y, Direction-Index
	area: int,
	sides: int,
}

Field :: struct {
	letter: u8,
	assigned_cluster_id: int
}

cluster_get_perimeter :: proc(c: Cluster) -> int {
	return len(c.boundingbox)
}

expand_cluster :: proc(cluster: ^Cluster, x: int, y: int, field_map: []Field) {

	directions : [4][2]int = {
		{ 0, -1}, // north
		{ 1,  0}, // east
		{ 0,  1}, // south
		{-1,  0}} // west
	
	for d in 0..<len(directions) {

		to_check_x := x + directions[d][0]
		to_check_y := y + directions[d][1]

		index, is_valid := location_to_index(to_check_x, to_check_y)
		if !is_valid {
			append(&cluster.boundingbox, [3]int {x, y, d})
			continue
		}

		field := &field_map[index]
		if field.letter != cluster.letter {
			append(&cluster.boundingbox, [3]int {x, y, d})
			continue
		}

		if field.assigned_cluster_id < 0 {
			field.assigned_cluster_id = cluster.id
			cluster.area += 1
			expand_cluster(cluster, to_check_x, to_check_y, field_map)
		
		} else {
			assert(field.assigned_cluster_id == cluster.id)
		}
	}
}

main :: proc() {
	input := read_input()
	defer delete(input)

	field_map := make([]Field, len(input))
	defer delete(field_map)
	for l, i in input do field_map[i] = Field {letter=l, assigned_cluster_id=-1}

	clusters := make([dynamic]Cluster)

	defer {
		for c in clusters do delete(c.boundingbox)
		delete(clusters)
	}

	//
	// create clustes
	//
	for i in 0..<len(field_map) {
		if field_map[i].assigned_cluster_id >= 0 do continue

		x, y := location_from_index(i)

		cluster_id := len(clusters)
		cluster := Cluster {
			id = cluster_id,
			letter = field_map[i].letter,
			// color = 31 + (i % 6),
			boundingbox = make([dynamic][3]int),
			area = 1 }

		field_map[i].assigned_cluster_id = cluster.id

		expand_cluster(&cluster, x, y, field_map)
		append(&clusters, cluster)
	}


	//
	// print map
	//
	for field, i in field_map {
		color := 0
		if field.assigned_cluster_id < 0 do color = 41
		else {
			clust := clusters[field.assigned_cluster_id]
			color = 31 + (clust.id % 6)
			
			x, y := location_from_index(i)
			for d in 0..<4 {
				key := [3]int {x, y, d}
				_, found := slice.linear_search(clust.boundingbox[:], key)
				if found {
					color += 60
					break
				}
			}
		}

		fmt.printf("\e[%dm%c\e[0m", color, field.letter)

		if (i % MAP_SIZE) == MAP_SIZE-1 do fmt.println()
	}

	// calculate sides (PART II)
	{
		for cluster in clusters {

			// for all directions
			for d in 0..<4 {
				
				sides := make(map[int]byte)

				for bb in cluster.boundingbox {
					if bb[2] != d do continue

					
					// use x coords for north + south and y for east and west
					relevant_coords_index := 0 if (d == 0 ||d == 2 ) else 1
					
					sidesbb[relevant_coords_index]
				}

			}

		}
	}

	//
	// print stats
	//
	{
		total_price := 0
		for cluster, c in clusters {
			fmt.printfln("\e[%dmCluster %c:\e[0m Perimeter: %d \tArea: %d", cluster.color, cluster.letter, cluster_get_perimeter(cluster), cluster.area)
			total_price += cluster_get_perimeter(cluster) * cluster.area
		}
		
		fmt.printfln("total price: %d", total_price)
	}
	
	fmt.printfln("num clusters: %d", len(clusters))
}