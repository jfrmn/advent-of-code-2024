package main

import "core:os"
import "core:strings"
import "core:fmt"

INPUT_FILENAME :: "input.txt"
COLUMNS_IN_ORGINAL :: 140
// INPUT_FILENAME :: "input_small.txt"
// COLUMNS_IN_ORGINAL :: 10
// INPUT_FILENAME :: "input_test.txt"
// COLUMNS_IN_ORGINAL :: 6

cleanup :: proc(input: []string) {
	for ln in input do delete(ln)
	delete(input)
}

transform_to_reverse:: proc(input: []string) -> []string {
	result := make([]string, len(input))
	for i in 0..<len(input) {
		result[i] = strings.reverse(input[i])		
	}
	return result
}

transform_to_vertical :: proc(orginal: []string) -> []string {
	result := make([]string, COLUMNS_IN_ORGINAL)

	for c in 0..<COLUMNS_IN_ORGINAL {

		top_bottom_line := make([]u8, len(orginal))
		for l in 0..<len(orginal) do top_bottom_line[l] = orginal[l][c]

		result[c] = transmute(string)top_bottom_line
	}
	return result
}

transform_to_diag_tl_br :: proc(orginal: []string) -> []string {
	result := make([dynamic]string)

	// first half
	for start_col in 0..<COLUMNS_IN_ORGINAL {
		
		line := make([dynamic]u8)

		ln := 0
		col := start_col
		for ln < len(orginal) && col < COLUMNS_IN_ORGINAL {
			
			x :string = orginal[ln]
			append(&line, x[col])
			ln += 1
			col += 1
		}
		
		append(&result, transmute(string)line[:])
	}

	// second half
	for start_line in 1..<len(orginal) {
		
		line := make([dynamic]u8)

		ln := start_line
		col := 0
		for ln < len(orginal) && col < COLUMNS_IN_ORGINAL {
			
			x :string = orginal[ln]
			append(&line, x[col])
			ln += 1
			col += 1
		}
		
		append(&result, transmute(string)line[:])
	}

	return result[:]
}

transform_to_diag_tr_bl :: proc(orginal: []string) -> []string {
	result := make([dynamic]string)

	// first half
	for start_col := COLUMNS_IN_ORGINAL - 1; start_col >= 0; start_col -= 1 {
			
		line := make([dynamic]u8)

		ln := 0
		col := start_col
		for ln < len(orginal) && col >= 0 {
			
			x :string = orginal[ln]
			append(&line, x[col])
			ln += 1
			col -= 1
		}
		
		append(&result, transmute(string)line[:])
	}

	// second half
	for start_line in 1..<len(orginal) {
		
		line := make([dynamic]u8)

		ln := start_line
		col := COLUMNS_IN_ORGINAL - 1
		for ln < len(orginal) && col < COLUMNS_IN_ORGINAL {
			
			x :string = orginal[ln]
			append(&line, x[col])
			ln += 1
			col -= 1
		}
		
		append(&result, transmute(string)line[:])
	}

	return result[:]
}

find_xmax_occurences :: proc(input: []string) -> u64 {
	occurences := 0
	for ln in input do occurences += strings.count(ln, "XMAS")
	return u64(occurences)
}

print :: proc(input: []string) {
	for ln in input do fmt.println(ln)
	fmt.println()
}

main :: proc() {

	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	orginal_input, alloc_err := strings.split_lines(transmute(string)entire_file)
	if alloc_err != nil do panic("allocation error")
	defer delete(orginal_input)

	// FOR TESTING
	{
		// print(orginal_input)
		// reversed := transform_to_reverse(orginal_input)
		// defer cleanup(reversed)
		// print(reversed)

		// vertiacl := transform_to_vertical(orginal_input)
		// defer cleanup(vertiacl)
		// print(vertiacl)
		
		// diag_tl_rb := transform_to_diag_tl_br(orginal_input)
		// defer cleanup(diag_tl_rb)
		// print(diag_tl_rb)
		
		// diag_rb_tl := transform_to_reverse(diag_tl_rb)
		// defer cleanup(diag_rb_tl)
		// print(diag_rb_tl)

		// diag_tr_bl := transform_to_diag_tr_bl(orginal_input)
		// defer cleanup(diag_tr_bl)
		// print(diag_tr_bl)

		// diag_bl_tr := transform_to_reverse(diag_tr_bl)
		// defer cleanup(diag_bl_tr)
		// print(diag_bl_tr)
	}

	total : u64 = 0

	// horizontal
	{
		total += find_xmax_occurences(orginal_input)
		
		reversed := transform_to_reverse(orginal_input)
		defer cleanup(reversed)
		total += find_xmax_occurences(reversed)
	}

	// vertial
	{
		vert := transform_to_vertical(orginal_input)
		defer cleanup(vert)
		total += find_xmax_occurences(vert)

		vert_reversed := transform_to_reverse(vert)
		defer cleanup(vert_reversed)
		total += find_xmax_occurences(vert_reversed)
	}

	// diagonal left to right
	{
		// tl to br
		diag_tl_br := transform_to_diag_tl_br(orginal_input)
		defer cleanup(diag_tl_br)
		total += find_xmax_occurences(diag_tl_br)

		// br to tl
		diag_br_tl := transform_to_reverse(diag_tl_br)
		defer cleanup(diag_br_tl)
		total += find_xmax_occurences(diag_br_tl)
	}
	
	// diagonal right to left
	{
		// tr to bl
		diag_tr_bl := transform_to_diag_tr_bl(orginal_input)
		defer cleanup(diag_tr_bl)
		total += find_xmax_occurences(diag_tr_bl)

		// tr to bl
		diag_bl_tr := transform_to_reverse(diag_tr_bl)
		defer cleanup(diag_bl_tr)
		total += find_xmax_occurences(diag_bl_tr)
	}

	fmt.println(total)
}