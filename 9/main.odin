package main

import "core:os"
import "core:strconv"
import "core:fmt"

INPUT_FILENAME :: "input_small.txt" when #config(small, false) else "input.txt"

read_input :: proc() -> []u8 {
	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	result := make([]u8, len(entire_file))
	for c, i in entire_file {
		assert(c >= '0' && c <= '9')
		result[i] = c - '0'
	}

	return result
}

backward_it_find_next_file_fragment :: proc(bwit: ^int, disk_map: []i16) -> bool {
	for ; bwit^ >= 0; bwit^ -= 1 {
		if disk_map[bwit^] >= 0 do return true
	}
	return false
}

backward_it_find_next_file_block:: proc(bwit: ^int, block_map: []Block) -> (Block, bool) {
	for ; bwit^ >= 0; bwit^ -= 1 {
		block := block_map[bwit^]
		if block.file_id >= 0 do return block, true
	}
	return {}, false
}

Block :: struct {
	size: i16,
	file_id: i16,
	next: ^Block,
	prev: ^Block
}

main :: proc() {
	input := read_input()

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART ONE
	{
		// purly informational
		total_disk_space: u64 = 0
		for b in input do total_disk_space += u64(b)

		disk_map := make([]i16, total_disk_space)
		is_file := true
		offset: u64 = 0
		file_id: i16 = 0
		for block_size in input {
			
			if is_file {
				for i in 0..<u64(block_size) do disk_map[offset + i] = file_id
				file_id += 1
			} else {
				for i in 0..<u64(block_size) do disk_map[offset + i] = -1
			}

			is_file = !is_file
			offset += u64(block_size)
		}

		forward_it := 0
		backward_it := len(disk_map) - 1
		backward_it_find_next_file_fragment(&backward_it, disk_map)

		for ; forward_it < len(disk_map) && forward_it < backward_it; forward_it += 1 {
			if disk_map[forward_it] >= 0 do continue

			disk_map[forward_it] = disk_map[backward_it]
			disk_map[backward_it] = -1
			ok := backward_it_find_next_file_fragment(&backward_it, disk_map)
			assert(ok)
		}

		when #config(print_map, false) {
			for id in disk_map {
				if id >= 0 do fmt.printf("%d|", id)
				else do fmt.print(".|")
			}
			fmt.println()
		}

		checksum := 0
		for id, i in disk_map {
			if id >= 0 do checksum += i * int(id)
		}
		fmt.printfln("checksum: %d", checksum)
		fmt.printfln("total space: %d", total_disk_space)
	}

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// PART TWO
	{
		block_list_head, block_list_tail: ^Block = nil

		// create block list
		{
			block_list_head = new(Block) {
				size = input[0],
				file_id = 0,
				next = nil,
				prev = nil }

			prev_block: ^Block = block_list_head
			file_id: i16 = 1
			is_file := false
			for i in 1..<len(input)-1 {
				block_size := input[i]
				block := new(Block) {
					size = i16(block_size),
					file_id = is_file ? file_id : -1,
					next = nil,
					prev = prev_block }

				prev_block.next = block
				prev_block = block

				if is_file do file_id += 1
				is_file = !is_file
			}

			block_list_tail = new(Block) {
				size = i16(input[len(input)-1]),
				file_id = is_file ? file_id : -1,
				next = nil,
				prev = prev_block }
			prev_block.next = block_list_tail
		}

		backward_it := block_list_tail
		for {
			if backward_it.file_id < 0 {
				if backward_it.prev == nil do break
				backward_it = backward_it.prev
				continue
			}
			
			// find next file block
			block := block_list_head
			for {
				if block.file_id > 0 {
					block = block.next
					continue
				}

				if block == backward_it do break
				block = block.next
			}
			for i := 0; i < backward_it; i += 1 {
				if block_map[i].file_id >= 0 do continue
				if block_map[i].size + )

			}
		}
		
				
	}
}