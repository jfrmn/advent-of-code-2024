package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:strconv"
import "core:math"

INPUT_FILENAME :: "input.txt"
// INPUT_FILENAME :: "input_small.txt"

read_input :: proc() -> ([][2]int, [][]int) {
	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	lines, alloc_err := strings.split_lines(transmute(string)entire_file)
	if alloc_err != nil do panic("allocation error")
	defer delete(lines)

	i: int = 0
	
	// parse rules
	rules: [dynamic][2]int
	for ; i < len(lines); i += 1 {

		line := lines[i]
		if len(line) == 0 do break
		
		split_parts := strings.split(line, "|")
		defer delete(split_parts)
		assert(len(split_parts) == 2)

		a, oka := strconv.parse_int(split_parts[0])
		if !oka do fmt.panicf("couldn't parse first number on line %d", i+1)
		
		b, okb := strconv.parse_int(split_parts[1])
		if !okb do fmt.panicf("couldn't parse second number on line %d", i+1)
		
		append(&rules, [2]int{a, b})
	}

	// skip empty line
	i += 1

	// parse update
	updates: [dynamic][]int
	for ; i < len(lines); i += 1 {

		line := lines[i]
		
		split_parts := strings.split(line, ",")
		defer delete(split_parts)
		
		update := make([]int, len(split_parts))
		for j in 0..<len(split_parts) {
			
			page, ok := strconv.parse_int(split_parts[j])
			if !ok do fmt.panicf("failed to parse page #%d on line %d", j+1, i+1)
			
			update[j] = page
		}
		
		append(&updates, update)
	}

	return rules[:], updates[:]
}

cleanup_updates :: proc(updates: [][]int) {
	for u in updates do delete(u)
	delete(updates)
}

check_update_order :: proc(update: []int, rules: [][2]int) -> (bool, int) {

	rule_loop: for rule, r in rules {

		pagenr_to_check := rule[0]
		pagenr_before := rule[1]

		for index_pagenr in 0..<len(update) {

			pagenr := update[index_pagenr]
			if pagenr != pagenr_to_check do continue
			
			index_before_page := 0
			found_before_page := false
			for ; index_before_page < len(update); index_before_page += 1 {
				if update[index_before_page] == pagenr_before {
					found_before_page = true
					break;
				}
			}
			
			// rule not relvant
			if !found_before_page do continue rule_loop

			assert(index_pagenr != index_before_page)
			if index_pagenr > index_before_page do return false, r
		}
	}

	return true, -1
}

get_middle_pagenr :: proc(update: []int) -> int {
	assert(len(update) % 2 == 1) // should be uneven

	flen := f32(len(update))
	middle_index := int(math.floor(flen / 2.0))
	return update[middle_index]
}

correct_update :: proc(update: []int, rules: [][2]int) -> []int {

	//
	// build dependencies
	//
	dependency_graph := make(map[int][dynamic]int)
	for page in update {

		dependencies_for_page := map_insert(&dependency_graph, page, make([dynamic]int))
		
		rule_loop: for rule in rules {
			
			if rule[0] != page do continue rule_loop
			
			// check if rule is relevant
			relevant := false
			for p in update { 
				if p == rule[1] {
					relevant = true;
					break
				}
			}

			if !relevant do continue rule_loop
								
			append(dependencies_for_page, rule[1])
		}
	}

	//
	// build new update
	//
	new_update := make([]int, len(update))
	insert_index := len(update) - 1

	graph_loop: for len(dependency_graph) > 0 {

		// find next page to insert
		for page, deps in dependency_graph {

			// check if deps already inserted
			all_deps_already_inserted := true
			deps_loop: for d in deps {
				for p in new_update {
					// page already inserted
					if p == d do continue deps_loop
				}

				// page NOT inserted
				all_deps_already_inserted = false
				break
			}
			
			// insert page if deps are fullfilled
			if all_deps_already_inserted {
				assert(insert_index >= 0)
				new_update[insert_index] = page
				insert_index -= 1

				delete_key(&dependency_graph, page)
				continue graph_loop
			}
		}

		assert(false, "found no page with all dependencies fullfilled")
	}

	return new_update[:]
}

main :: proc() {
	rules, updates := read_input()
	defer { delete(rules); cleanup_updates(updates) }
	
	sum_middle_pagenr_of_ordered := 0
	sum_middle_pagenr_of_corrected := 0
	for update, i in updates {

		ok, violated_rule := check_update_order(update, rules)
		
		fmt.printf("Update #%d: ", i+1)
		if ok {
			sum_middle_pagenr_of_ordered += get_middle_pagenr(update)
			fmt.println("OK")
			
		} else {
			fmt.printfln("VIOLATED [rule #%d: %d|%d]", violated_rule, rules[violated_rule][0], rules[violated_rule][1])

			new_update := correct_update(update, rules)
			defer delete(new_update)

			fmt.printfln("\t   CORRECTED: %v", new_update)

			sum_middle_pagenr_of_corrected += get_middle_pagenr(new_update)
		}
	}

	fmt.printfln("sum ordered: %d / sum corrected: %d", sum_middle_pagenr_of_ordered, sum_middle_pagenr_of_corrected)
}