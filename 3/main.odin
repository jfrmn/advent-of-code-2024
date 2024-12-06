package main

import "core:os"
import "core:fmt"
import "core:slice"
import "core:strings"
import "core:strconv"

INPUT_FILENAME :: "input.txt"

KEYWORD_MUL :: "mul("
KEYWORD_DO :: "do"
KEYWORD_DONT :: "don't"

extract_number :: proc(input: ^[]u8) -> (num: [3]u8, num_len: int) {

	for i in 0..<min(3, len(input)) {
		if input[i] < '0' || input[i] > '9' do break
		
		num[i] = input[i]
		num_len += 1
	}

	if num_len > 0 do input^ = input[num_len:]

	return num, num_len
}

main :: proc() {
	input, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(input)

	remaining_input := input[:]

	// str := `xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))mul(*,4)+mul(4,*)`
	// remaining_input := transmute([]u8)str

	total: u64 = 0
	mul_is_enabled: bool = true
	for !slice.is_empty(remaining_input) {

		// fmt.printfln("remaining (%d): %s", len(remaining_input), remaining_input[:min(len(remaining_input), 100)])
		
		// FOR PART ONE:
		// idx := strings.index(transmute(string)remaining_input, "mul(")
		// if idx == -1 do break
		// remaining_input = remaining_input[idx + 4:]

		idx, width := strings.index_multi(transmute(string)remaining_input, {KEYWORD_MUL, KEYWORD_DONT, KEYWORD_DO})
		if idx == -1 do break
		remaining_input = remaining_input[idx + width:]

		// we don't get what keyword we found just the length of the keyword (???)
		// luckly we can still use that and determine the keyword
		if width == len(KEYWORD_DO) {
			mul_is_enabled = true

		} else if width == len(KEYWORD_DONT) {
			mul_is_enabled = false
		
		} else {
			assert(width == len(KEYWORD_MUL))
		}
		
		first_num_length := 0
		first_num, _ := strconv.parse_u64(transmute(string)remaining_input, 10, &first_num_length)
		
		remaining_input = remaining_input[first_num_length:]
		if slice.is_empty(remaining_input) do break
		if first_num_length > 3 do continue

		if remaining_input[0] != ',' do continue
		remaining_input = remaining_input[1:]
		if slice.is_empty(remaining_input) do break

		second_num_length := 0
		second_num, _ := strconv.parse_u64(transmute(string)remaining_input, 10, &second_num_length)

		remaining_input = remaining_input[second_num_length:]
		if slice.is_empty(remaining_input) do break
		if second_num_length > 3 do continue

		if remaining_input[0] != ')' do continue
		remaining_input = remaining_input[1:]
		
		product := first_num * second_num
		fmt.printfln("%d x %d = %d %s", first_num, second_num, product, "[DISABLED]" if !mul_is_enabled else "")

		if mul_is_enabled do total += product
	}

	fmt.printfln("total = %d", total)
}