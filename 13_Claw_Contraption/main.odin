package main

import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:os"
import "core:math"
import "core:slice"

ClawMaschine :: struct {
	offset_button_a: [2]u64,
	offset_button_b: [2]u64,
	prize_location: [2]u64
}

INPUT_FILENAME :: "input_small.txt" when #config(small, false) else "input.txt"

read_input :: proc() -> []ClawMaschine {
	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	entire_file_as_str := transmute(string)entire_file

	result := make([dynamic]ClawMaschine)

	curr_claw_maschine := ClawMaschine{}
	for line in strings.split_lines_iterator(&entire_file_as_str) {

		remaining_line := line
		parse_len := 0
		if strings.starts_with(line, "Button A: ") || strings.starts_with(line, "Button B: ") {

			offset := &curr_claw_maschine.offset_button_a if strings.starts_with(line, "Button A: ") else &curr_claw_maschine.offset_button_b
			remaining_line = remaining_line[len("Button ?: X+"):]

			offset.x, _ = strconv.parse_u64(remaining_line, 10, &parse_len)
			if parse_len == 0 do fmt.panicf("failed to parse int: %s", remaining_line)

			remaining_line = remaining_line[parse_len:]
			remaining_line = strings.trim_prefix(remaining_line, ", Y+")
			offset.y, _ = strconv.parse_u64(remaining_line, 10, &parse_len)
			if parse_len == 0 do fmt.panicf("failed to parse int: %s", remaining_line)

		} else if strings.starts_with(line, "Prize") {
			remaining_line = strings.trim_prefix(remaining_line, "Prize: X=")
			
			curr_claw_maschine.prize_location.x, _ = strconv.parse_u64(remaining_line, 10, &parse_len)
			if parse_len == 0 do fmt.panicf("failed to parse int: %s", remaining_line)

			remaining_line = remaining_line[parse_len:]
			remaining_line = strings.trim_prefix(remaining_line, ", Y=")
			
			curr_claw_maschine.prize_location.y, _ = strconv.parse_u64(remaining_line, 10, &parse_len)
			if parse_len == 0 do fmt.panicf("failed to parse int: %s", remaining_line)
		
		} else {
			assert(len(line) == 0)
			append(&result, curr_claw_maschine)
			curr_claw_maschine = ClawMaschine{}
		}
	}

	append(&result, curr_claw_maschine)

	return result[:]
}

MAX_BUTTON_PRESSES :: 200

Button :: enum {
	A,
	B
}

check_button_combination :: proc(button_presses_a: u64, button_presses_b: u64, offset_button_a: u64, offset_button_b: u64, prize_location: u64) -> bool {
	return (button_presses_a * offset_button_a + button_presses_b * offset_button_b) == prize_location
}

main :: proc() {
	input := read_input()

	//
	// PART II
	//
	for &claw_maschine in input {
		claw_maschine.prize_location.x += 10000000000000
		claw_maschine.prize_location.y += 10000000000000
	}

	total_coins: u64 = 0 
	cm_loop: for claw_maschine, cm in input {
		
		//
		// find all possible combinations to get to X
		//
		possible_combinations_x := make([dynamic][2]u64)

		max_button_presses := 
			u64(f64(claw_maschine.prize_location.x) / (math.min(
				f64(claw_maschine.offset_button_a.x),
				f64(claw_maschine.offset_button_b.x))) + 0.5)
		// max_button_presses := math.min(
		// 	MAX_BUTTON_PRESSES,
		// 	int(f32(claw_maschine.prize_location.x) / (math.min(
		// 		f32(claw_maschine.offset_button_a.x),
		// 		f32(claw_maschine.offset_button_b.x))) + 0.5))
		fmt.printfln("max_button_presses: %d", max_button_presses)
		for num_presses in 1..=max_button_presses {
			
			for i in 0..<num_presses {
				presses_a := i 
				presses_b := num_presses - i
				if check_button_combination(presses_a, presses_b, claw_maschine.offset_button_a.x, claw_maschine.offset_button_b.x, claw_maschine.prize_location.x) {
					append(&possible_combinations_x, [2]u64 {presses_a, presses_b})
				}
			}
		}

		//
		// check if y matches
		//
		fmt.printf("claw maschine %d (prize: X=%d, Y=%d):", cm, claw_maschine.prize_location.x, claw_maschine.prize_location.y)
		for button_presses in possible_combinations_x {

			if check_button_combination(button_presses[0], button_presses[1], claw_maschine.offset_button_a.y, claw_maschine.offset_button_b.y, claw_maschine.prize_location.y) {
				fmt.printfln(" A: %d, B: %d", button_presses[0], button_presses[1])
				total_coins += (button_presses[0] * 3) + button_presses[1]
				continue cm_loop
			}
		}

		fmt.println(" NO SOLUTION")
	}

	fmt.printfln("Total coins: %d", total_coins)
}
 