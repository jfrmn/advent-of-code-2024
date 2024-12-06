package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:sort"

read_list_from_file :: proc() -> (left_nums: [dynamic]int, right_nums: [dynamic]int, ok: bool) {
	
	entire_file := os.read_entire_file("input.txt") or_return
	defer delete(entire_file)

	it := string(entire_file)
	for line in strings.split_lines_iterator(&it) {

		first_idx_space := strings.index_byte(line, ' ')
		last_idx_space := strings.last_index_byte(line, ' ')

		left_num := strconv.parse_int(
			strings.substring_to(line, first_idx_space) or_else ""
		) or_return

		right_num := strconv.parse_int(
			strings.substring_from(line, last_idx_space + 1) or_else ""
		) or_return

		append(&left_nums, left_num)
		append(&right_nums, right_num)
	}

	return left_nums, right_nums, true
}

main :: proc() {
	
	//
	// read input
	//
	left_nums, right_nums, ok := read_list_from_file()
	if !ok {
		fmt.printfln("failed to read input")
		return
	}

	assert(len(left_nums) == len(right_nums))
	
	//
	// calculate total distance
	//
	sort.heap_sort(left_nums[:])
	sort.heap_sort(right_nums[:])

	total_distance := 0
	for i in 0 ..< len(left_nums) {
		total_distance += abs(left_nums[i] - right_nums[i])
	}
	
	fmt.printfln("Total distance: %d", total_distance)

	//
	// calculate similarity score
	//
	score := 0
	for i in 0 ..< len(left_nums) {
		
		num := left_nums[i]
		
		appearances := 0
		for i in 0 ..< len(right_nums) {
			if right_nums[i] == num do appearances += 1
		}

		score += (appearances * num)
	}

	fmt.printfln("Similarity score: %d", score)
	return
}