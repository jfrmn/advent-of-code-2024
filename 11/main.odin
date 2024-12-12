package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:time"
import "core:math"
import "core:mem"
import "base:runtime"
import "core:thread"

INPUT :: #config(input, "normal")

when INPUT == "big" { // USE THIS FOR PART II
	INPUT_FILENAME :: "input.txt"
	NUM_BLINKS :: 75

} else when INPUT == "normal" { // USE THIS FOR PART I
	INPUT_FILENAME :: "input.txt"
	NUM_BLINKS :: 25

} else when INPUT == "small" {
	INPUT_FILENAME :: "input_small.txt"
	NUM_BLINKS :: 6

} else {
	INPUT_FILENAME :: "input_tiny.txt"
	NUM_BLINKS :: 1
}

read_input :: proc() -> []u64{
	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	entire_file_as_str := transmute(string)entire_file

	num_elems := strings.count(entire_file_as_str, " ") + 1
	result := make([]u64, num_elems)

	i := 0
	for num_as_str in strings.split_iterator(&entire_file_as_str, " ") {
		value, ok := strconv.parse_u64(num_as_str)
		assert(ok)

		result[i] = value
		i += 1
	}
	assert(i == num_elems)
	return result
}

map_insert_or_add :: proc (m: ^map[u64]u64, key: u64, value: u64) {
	_, prev_value, ok := runtime.map_get(m^, key)

	if ok do map_insert(m, key, value + prev_value)
	else do map_insert(m, key, value)
}

main :: proc() {
	numbers := read_input()
	defer delete(numbers)
	
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART ONE + TWO
	{
		source_map := make(map[u64]u64)
		target_map := make(map[u64]u64)
		defer {
			delete (source_map)
			delete (target_map)
		}

		for number in numbers do map_insert_or_add(&source_map, number, 1)

		for i in 0..<NUM_BLINKS {

			start := time.now()
			clear_map(&target_map)

			for num, amount in source_map {

				if num == 0 {
					map_insert_or_add(&target_map, 1, amount)
					continue
				}

				num_digits := 1
				for num >= u64(math.pow10_f64(f64(num_digits))) {
					num_digits += 1
				}
				
				if (num_digits % 2) == 0 {

					limit_half_digits := u64(math.pow10_f64(f64(num_digits / 2)))
					lower_digits := num % limit_half_digits
					upper_digits := math.floor_div(num, limit_half_digits)
		
					map_insert_or_add(&target_map, upper_digits, amount)
					map_insert_or_add(&target_map, lower_digits, amount)
					continue
				}

				new_value := num * 2024
				map_insert_or_add(&target_map, new_value, amount)
				continue
			}

			fmt.printfln("Blink #%d / %d in %fms", i, NUM_BLINKS, 
				time.duration_milliseconds(time.since(start)));

			source_map, target_map = target_map, source_map
		}

		total_numbers: u64 = 0
		for _, amount in source_map do total_numbers += amount
		fmt.printfln("Number count: %d - distinct numbers: %d", total_numbers, len(source_map))
	}
}