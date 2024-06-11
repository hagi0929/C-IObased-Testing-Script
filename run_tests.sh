#!/bin/bash

EXEC="./build/pq1"
TEST_DIR="./test"
INPUT_PATTERN="public*.in"
OUTPUT_PATTERN="public%.expect"
TEMP_OUTPUT="./build/temp.out"
REPORT_FILE="./build/test_report.txt"
MAX_ERRORS=200
CONTEXT_LINES=5

# Create build directory if it doesn't exist
mkdir -p ./build

# Clean previous temporary and report files
rm -f $TEMP_OUTPUT $REPORT_FILE

# Function to convert input pattern to match output file
derive_output_file() {
    local input_file=$1
    local base_name=$(basename "$input_file" .in)
    local output_file="${base_name%.in}.expect"
    echo "$TEST_DIR/$output_file"
}

# Function to log differences
log_difference() {
    local expected_file=$1
    local actual_file=$2
    local max_lines=$3
    local context_lines=$4
    local errors=0

    diff --side-by-side --color=always --minimal --suppress-common-lines "$expected_file" "$actual_file" | \
    while IFS= read -r line; do
        if [ $errors -lt $max_lines ]; then
            echo "$line" | tee -a $REPORT_FILE
            errors=$((errors+1))
        fi
    done

    echo "Number of mismatched lines: $errors" | tee -a $REPORT_FILE

    if [ $errors -gt $max_lines ]; then
        echo "... and $((errors - max_lines)) more differences" | tee -a $REPORT_FILE
    fi

    return $errors
}

# Function to run a single test
run_test() {
    local input_file=$1
    local output_file=$(derive_output_file "$input_file")

    if [ ! -f $output_file ]; then
        echo "No matching output file for $input_file" | tee -a $REPORT_FILE
        return
    fi

    $EXEC < $input_file > $TEMP_OUTPUT
    if diff -q $TEMP_OUTPUT $output_file > /dev/null; then
        echo "$input_file: PASS" | tee -a $REPORT_FILE
        return 0
    else
        echo "$input_file: FAIL" | tee -a $REPORT_FILE
        diff --side-by-side --suppress-common-lines $TEMP_OUTPUT $output_file


        # diff --side-by-side --color=always --suppress-common-lines $TEMP_OUTPUT $output_file
        # log_difference $output_file $TEMP_OUTPUT $MAX_ERRORS $CONTEXT_LINES
        return 1
    fi
}

# Main function to run all tests
run_all_tests() {
    echo "Running tests..." | tee $REPORT_FILE
    local total_tests=0
    local passed_tests=0
    for input_file in $TEST_DIR/$INPUT_PATTERN; do
        run_test $input_file
        if [ $? -eq 0 ]; then
            passed_tests=$((passed_tests+1))
        fi
        total_tests=$((total_tests+1))
    done
    rm -f $TEMP_OUTPUT
    echo "Testing completed. Report generated at $REPORT_FILE" | tee -a $REPORT_FILE

    # Summary
    echo -e "\nSummary:" | tee -a $REPORT_FILE
    echo "Total tests: $total_tests" | tee -a $REPORT_FILE
    echo "Passed tests: $passed_tests" | tee -a $REPORT_FILE
    echo "Failed tests: $((total_tests - passed_tests))" | tee -a $REPORT_FILE
}

# Command-line interface
if [ "$1" == "run" ]; then
    run_all_tests
elif [ "$1" == "clean" ]; then
    rm -f $TEMP_OUTPUT $REPORT_FILE
    echo "Cleaned temporary and report files."
else
    echo "Usage: $0 {run|clean}"
fi
