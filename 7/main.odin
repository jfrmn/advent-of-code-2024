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
	for line in strings.split_lines_iterator(&entire_file_as_str) {

		remaining_line := line

		eq: Equation
		parsed_len: int
		eq.result, _ = strconv.parse_int(remaining_line, 10, &parsed_len)
		if parsed_len == 0 do fmt.panicf("strconv.parse_int failed: %s", remaining_line)

		remaining_line = line[parsed_len:]
		assert(strings.starts_with(remaining_line, ": "))
		remaining_line = remaining_line[2:]

		num_operands := strings.count(remaining_line, " ") + 1
		eq.operands = make([]int, num_operands)

		i := 0
		for num_as_str in strings.split_iterator(&remaining_line, " ") {
			eq.operands[i], _ = strconv.parse_int(transmute(string)num_as_str, 10)
			i += 1
		}
		assert(i == num_operands)

		append(&result, eq)
	}

	return result[:]
}

cleanup :: proc(input: []Equation) {
	for e in input do delete(e.operands)
	delete(input)
}

get_variation_of_operators :: proc(set_of_ops: []u8, num_ops_per_variation: int) -> [][]u8 {

	num_variations := int(math.pow_f32(
		f32(len(set_of_ops)),
		f32(num_ops_per_variation)))

	result := make([][]u8, num_variations)

	for i in 0..<num_variations {
		variation := make([]u8, num_ops_per_variation)
		
		remaining_value := i
		for j in 0..<num_ops_per_variation {
			if remaining_value == 0 {
				variation[j] = set_of_ops[0]
			} else {
				variation[j] = set_of_ops[remaining_value % len(set_of_ops)]
				remaining_value = int(remaining_value / len(set_of_ops))
			}
		}

		result[i] = variation
	}

	return result
}

cleanup_variations :: proc(variations: [][]u8) {
	for v in variations do delete(v)
	delete(variations)
}

main :: proc() {
	
	input := read_input()
	defer cleanup(input)

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART ONE
	{
		sum_of_results_of_valid_eqs := 0
		eq_loop1: for eq in input {

			variations := get_variation_of_operators([]u8{'+', '*'}, len(eq.operands) - 1)
			defer cleanup_variations(variations)

			for variation in variations{

				value := eq.operands[0]
				for i in 1..<len(eq.operands) {

					operand := eq.operands[i]
					operator := variation[i-1]

					     if (operator == '+') do value += operand
					else if (operator == '*') do value *= operand
					else do fmt.panicf("invalid operator")
				}

				if value == eq.result {
					
					fmt.printf("%d = %d", eq.result, eq.operands[0])
					for i in 1..<len(eq.operands) do fmt.printf(" %c %d", variation[i-1], eq.operands[i])
					fmt.println()

					sum_of_results_of_valid_eqs += eq.result
					continue eq_loop1
				}
			}

			fmt.printfln("%d NOT POSSBILE", eq.result)
		}

		fmt.printfln("sum of results of valid euations: %d", sum_of_results_of_valid_eqs)
	}

	fmt.println("--------------------")

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART TWO
	{
		sum_of_results_of_valid_eqs := 0
		eq_loop2: for eq in input {

			variations := get_variation_of_operators([]u8{'+', '*', '|'}, len(eq.operands) - 1)
			defer cleanup_variations(variations)

			sb: strings.Builder
			strings.builder_init(&sb)
			defer strings.builder_destroy(&sb)

			for variation in variations{

				value := eq.operands[0]
				for i in 1..<len(eq.operands) {

					operand := eq.operands[i]
					operator := variation[i-1]

					     if (operator == '+') do value += operand
					else if (operator == '*') do value *= operand
					else if (operator == '|') {
						strings.builder_reset(&sb)
						strings.write_int(&sb, value)
						strings.write_int(&sb, operand)
						value, _ = strconv.parse_int(strings.to_string(sb))

					} else do fmt.panicf("invalid operator")
				}

				if value == eq.result {
					
					fmt.printf("%d = %d", eq.result, eq.operands[0])
					for i in 1..<len(eq.operands) do fmt.printf(" %c %d", variation[i-1], eq.operands[i])
					fmt.println()

					sum_of_results_of_valid_eqs += eq.result
					continue eq_loop2
				}
			}

			fmt.printfln("%d NOT POSSBILE", eq.result)
		}

		fmt.printfln("sum of results of valid euations: %d", sum_of_results_of_valid_eqs)
	}
}
