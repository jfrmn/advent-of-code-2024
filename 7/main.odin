package main

import "core:os"
import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:math"

INPUT_FILENAME :: "input.txt"
// INPUT_FILENAME :: "input_small.txt"

Equation :: struct {
	result: int,
	operands: []int
}

read_input :: proc() -> []Equation {

	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	result := make([dynamic]Equation)

	entire_file_as_str := transmute(string)(entire_file)
	for line in strings.split_lines_after_iterator(&entire_file_as_str) {

		remaining_line := line

		eq: Equation
		parsed_len: int
		eq.result, _ = strconv.parse_int(remaining_line, 10, &parsed_len)
		if parsed_len == 0 do fmt.panicf("strconv.parse_int failed: %s", remaining_line)

		remaining_line = line[parsed_len:]
		assert(strings.starts_with(remaining_line, ": "))
		remaining_line = line[2:]

		num_operands := strings.count(remaining_line, " ") + 1
		eq.operands = make([]int, num_operands)

		i := 0
		for num_as_str in strings.split_iterator(&remaining_line, " ") {
			eq.operands[i], _ = strconv.parse_int(transmute(string)remaining_line, 10)
			i += 1
		}

		append(&result, eq)
	}

	return result[:]
}

cleanup :: proc(input: []Equation) {
	for e in input do delete(e.operands)
	delete(input)
}

main :: proc() {
	
	input := read_input()
	defer cleanup(input)

	// PART ONE
	{
		sum_of_results_of_valid_eqs := 0
		eq_loop: for eq in input {

			for operator_mask in 0..<uint(math.pow2_f64(len(eq.operands)) - 1) {

				value := eq.operands[0]
				for i in 1..<len(eq.operands) {

					operand := eq.operands[i]

					assert(i >= 1)
					bit_index := cast(uint)(i-1)
					operator := (operator_mask >> bit_index) & 0x1
					
					if (operator == 0)      do value += operand
					else if (operator == 1) do value *= operand
					else do fmt.panicf("unknown operator %d", operator)
				}

				if value == eq.result {
					
					fmt.printf("%d = %d", eq.result, eq.operands[0])
					for i in 1..<len(eq.operands) {
						bit_index := cast(uint)(i-1)
						op := "+" if (operator_mask >> bit_index) & 0x1 == 0 else "*"
						fmt.printf(" %s %d", op, eq.operands[i])
					}
					fmt.println()

					sum_of_results_of_valid_eqs += eq.result
					continue eq_loop
				}
			}

			fmt.printfln("%d NOT POSSBILE", eq.result)
		}

		fmt.printfln("sum of results of valid euations: %d", sum_of_results_of_valid_eqs)
	}

}
