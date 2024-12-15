package main

import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:os"
import "core:math"
import "core:slice"

Claw_Maschine :: struct {
	offset_button_a: [2]i64,
	offset_button_b: [2]i64,
	prize_location: [2]i64
}

INPUT_FILENAME :: "input_small.txt" when #config(small, false) else "input.txt"

read_input :: proc() -> []Claw_Maschine {
	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	entire_file_as_str := transmute(string)entire_file

	result := make([dynamic]Claw_Maschine)

	curr_claw_maschine := Claw_Maschine{}
	for line in strings.split_lines_iterator(&entire_file_as_str) {

		remaining_line := line
		parse_len := 0
		if strings.starts_with(line, "Button A: ") || strings.starts_with(line, "Button B: ") {

			offset := &curr_claw_maschine.offset_button_a if strings.starts_with(line, "Button A: ") else &curr_claw_maschine.offset_button_b
			remaining_line = remaining_line[len("Button ?: X+"):]

			offset.x, _ = strconv.parse_i64(remaining_line, 10, &parse_len)
			if parse_len == 0 do fmt.panicf("failed to parse int: %s", remaining_line)

			remaining_line = remaining_line[parse_len:]
			remaining_line = strings.trim_prefix(remaining_line, ", Y+")
			offset.y, _ = strconv.parse_i64(remaining_line, 10, &parse_len)
			if parse_len == 0 do fmt.panicf("failed to parse int: %s", remaining_line)

		} else if strings.starts_with(line, "Prize") {
			remaining_line = strings.trim_prefix(remaining_line, "Prize: X=")
			
			curr_claw_maschine.prize_location.x, _ = strconv.parse_i64(remaining_line, 10, &parse_len)
			if parse_len == 0 do fmt.panicf("failed to parse int: %s", remaining_line)

			remaining_line = remaining_line[parse_len:]
			remaining_line = strings.trim_prefix(remaining_line, ", Y=")
			
			curr_claw_maschine.prize_location.y, _ = strconv.parse_i64(remaining_line, 10, &parse_len)
			if parse_len == 0 do fmt.panicf("failed to parse int: %s", remaining_line)
		
		} else {
			assert(len(line) == 0)
			append(&result, curr_claw_maschine)
			curr_claw_maschine = Claw_Maschine{}
		}
	}

	append(&result, curr_claw_maschine)

	return result[:]
}

solve :: proc(cm: Claw_Maschine) -> (i64, i64, bool) {

	
	/*
	* Px = Na * Oax + Nb * Obx
	* Py = Na * Oay + Nb * Oby
	*
	* 1. Solve for Na
	* Px = Na * Oax + Nb * Obx
	* Px - Na * Oax = Nb * Obx
	* Na = (Px - Nb * Obx) / Oax
	*
	* 2. Insert Nb in other formula and solve for Na
	* Py = ((Px - Nb * Obx) / Oax) * Oay + Nb * Oby
	* Py = ((Px / Oax) - ((Nb*Obx) / Oax) * Oay + Nb*Oby
	* Py = (((Px*Oay) / Oax) - ((Nb*Obx*Oay) / Oax) + Nb*Oby
	* Py*Oax = (Px*Oay) - (Nb*Obx*Oay) + Nb*Oby*Oax
	* Py*Oax - Px*Oay = -Nb*Obx*Oay + Nb*Oby*Oax
	* Py*Oax - Px*Oay = Nb(-Obx*Oay + Oby*Oax)
	* (Py*Oax - Px*Oay) / (-Obx*Oay + Oby*Oax) = Nb
	* Nb = (Py*Oax - Px*Oay) / (-Obx*Oay + Oby*Oax)
	*
	* 
	* Px = Prize X-Coords, Py = Prize Y-Coords
	* Na = Number of A presses, Nb = Number of B presses
	* Oax = Offset X for button A, Oay = Offset Y for button A
	* Obx = Offset X for button B, Oby = Offset Y for button B
	*/ 

	presses_button_b := (cm.prize_location.y * cm.offset_button_a.x - cm.prize_location.x * cm.offset_button_a.y) / (-cm.offset_button_b.x * cm.offset_button_a.y + cm.offset_button_b.y * cm.offset_button_a.x)
	presses_button_a := (cm.prize_location.x - presses_button_b * cm.offset_button_b.x) / cm.offset_button_a.x

	if presses_button_a * cm.offset_button_a.x + presses_button_b * cm.offset_button_b.x != cm.prize_location.x do return 0, 0, false;
	if presses_button_a * cm.offset_button_a.y + presses_button_b * cm.offset_button_b.y != cm.prize_location.y do return 0, 0, false;

	return presses_button_a, presses_button_b, true
}

main :: proc() {
	input := read_input()

	when #config(part2, false) {
		for &claw_maschine in input {
			claw_maschine.prize_location.x += 10000000000000
			claw_maschine.prize_location.y += 10000000000000
		}
	}

	total_coins: i64 = 0 
	cm_loop: for claw_maschine, cm in input {
		
		presses_a, presses_b, has_solution := solve(claw_maschine)

		fmt.printf("claw maschine %d (prize: X=%d, Y=%d):", cm, claw_maschine.prize_location.x, claw_maschine.prize_location.y)
		if has_solution {
			fmt.printfln(" A: %d - B: %d", presses_a, presses_b)
			total_coins += (presses_a * 3) + presses_b
		} else {
			fmt.printfln(" NO SOLUTION")
		}
	}

	fmt.printfln("Total coins: %d", total_coins)
}
 