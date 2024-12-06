package main

import "core:os"
import "core:strings"
import "core:fmt"
import "core:strconv"

INPUT_FILENAME :: "input.txt"
//INPUT_FILENAME :: "input_small.txt"

read_reports :: proc() -> (reports: [dynamic][dynamic]int) {
	entire_file, ok := os.read_entire_file(INPUT_FILENAME)
	if !ok do panic("failed to read input")
	defer delete(entire_file)

	entire_file_as_str := transmute(string)(entire_file)
	for line in strings.split_lines_iterator(&entire_file_as_str) {
		
		splited_line, err := strings.split(line, " ")
		if err != nil do panic("allocation error")
		defer delete(splited_line)

		report: [dynamic]int
		reserve(&report, len(splited_line))

		for item in splited_line {
			num, ok := strconv.parse_int(item)
			if !ok do panic("failed to parse int")
			append(&report, num)
		}

		append(&reports, report)
	}

	return reports
}

check_report_safety :: proc(report: [dynamic]int) -> bool {

	MAX_DELTA :: 3

	assert(len(report) > 2)

	asc := (report[0] < report[1])
	
	for i in 0 ..< len(report) - 1 {
		
		delta := report[i + 1] - report[i] if asc else report[i] - report[i + 1];
		
		if delta < 0 || abs(delta) > MAX_DELTA || delta == 0 {
			return false
		}
	}
	
	return true
}

check_report_saftety_with_problem_dampener :: proc(report: [dynamic]int) -> (bool, [dynamic]int) {
	
	// check if the report is safe
	safe := check_report_safety(report)

	// if not try to remove one item and check again
	// we aren't trying to be clever here, just brute force
	if !safe {

		for index_to_remove in 0 ..< len(report) {
			
			corrected_report := make([dynamic]int, len(report)-1)

			copy(corrected_report[:index_to_remove], report[:index_to_remove])
			copy(corrected_report[index_to_remove:], report[index_to_remove + 1:])

			safe = check_report_safety(corrected_report)
			if safe do return true, corrected_report

			delete(corrected_report)
		}

		return false, nil
	
	} else {
		return true, nil
	}

}

check_all_reports_for_safety :: proc(reports: [dynamic][dynamic]int, problem_dampener: bool) -> int {

	fmt.printfln("\n--- results %s 'problem dampener' ---", "WITH" if problem_dampener else "WITHOUT")

	check_proc := check_report_saftety_with_problem_dampener if problem_dampener else proc(report: [dynamic]int) -> (bool, [dynamic]int) { return check_report_safety(report), nil };

	num_safe_reports := 0
	for i in 0 ..< len(reports) {
		
		report := reports[i]
		is_safe, combination_that_worked := check_proc(report)
		
		fmt.printf("Report #%d is %s", i+1, "SAFE" if is_safe else "UNSAFE")
		if (combination_that_worked != nil) do fmt.printf(" (with: %v)", combination_that_worked)
		fmt.println()

		if is_safe do num_safe_reports += 1
	}

	return num_safe_reports
}

main :: proc() {

	reports := read_reports()
	
	num_safe_reports_no_pd := check_all_reports_for_safety(reports, false)
	fmt.printfln("Number of safe reports: %d / %d", num_safe_reports_no_pd, len(reports))

	num_safe_reports_w_pd := check_all_reports_for_safety(reports, true)
	fmt.printfln("Number of safe reports: %d / %d", num_safe_reports_w_pd, len(reports))
}