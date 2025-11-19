#!/bin/bash
# FitWatch VM Test Suite
# Tests all components of the FitWatch system

echo "=================================="
echo "FitWatch VM Test Suite"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

test_count=0
pass_count=0

run_test() {
    test_count=$((test_count + 1))
    echo -e "${BLUE}Test $test_count: $1${NC}"
    if eval "$2" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        pass_count=$((pass_count + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
    echo ""
}

# Test 1: Simple assembly execution
run_test "Execute simple assembly" \
    "python3 src/vm.py examples/assembly/simple.fasm"

# Test 2: Conditional logic with high energy
run_test "Conditional with high energy (should include Leg Press)" \
    "python3 src/vm.py examples/assembly/routine.fasm --sensor ENERGY_LEVEL=8 | grep -q 'Leg Press'"

# Test 3: Conditional logic with low energy
run_test "Conditional with low energy (should skip Leg Press)" \
    "! python3 src/vm.py examples/assembly/routine.fasm --sensor ENERGY_LEVEL=5 | grep -q 'Leg Press'"

# Test 4: Time-based long routine
run_test "Time-based routine (long workout)" \
    "python3 src/vm.py examples/assembly/time_based.fasm --sensor TIME_AVAILABLE=45 | grep -q 'Bench Press'"

# Test 5: Time-based short routine
run_test "Time-based routine (short workout)" \
    "python3 src/vm.py examples/assembly/time_based.fasm --sensor TIME_AVAILABLE=20 | grep -q 'Quick Warm-up'"

# Test 6: FitScript compilation
run_test "Compile FitScript to assembly" \
    "build/fitscript examples/fitscript/leg_day.fit -o /tmp/test_output.fasm"

# Test 7: Full pipeline (compile + run)
run_test "Full pipeline (FitScript to JSON)" \
    "build/fitscript examples/fitscript/leg_day.fit -o /tmp/test_temp.fasm && python3 src/vm.py /tmp/test_temp.fasm --sensor ENERGY_LEVEL=8 -o /tmp/test_routine.json"

# Test 8: JSON output format
run_test "Verify JSON output structure" \
    "python3 -m json.tool /tmp/test_routine.json > /dev/null"

# Test 9: Multiplication example (Turing completeness)
run_test "Execute multiplication (5×3=15, Turing completeness demo)" \
    "python3 src/vm.py examples/assembly/multiplication.fasm | grep -q 'Jumping Jacks' && [ $(python3 src/vm.py examples/assembly/multiplication.fasm 2>/dev/null | grep -c 'Jumping Jacks') -eq 15 ]"

# Test 10: Heart rate adaptive
run_test "Heart rate adaptive routine" \
    "python3 src/vm.py examples/assembly/heart_rate_adaptive.fasm --sensor HEART_RATE=110"

# Test 11: Stack PUSH/POP behavior
run_test "Stack PUSH/POP restores the original counter" \
    "[ $(python3 src/vm.py examples/assembly/stack_demo.fasm | grep -c 'Stack Push-ups') -eq 3 ]"

# Test 12: FitScript conditional compilation (language test)
run_test "FitScript else branch (low energy workout)" \
    "build/fitscript examples/fitscript/conditional_example.fit -o /tmp/test_conditional.fasm && python3 src/vm.py /tmp/test_conditional.fasm --sensor ENERGY_LEVEL=5 | grep -q 'Low Energy Workout'"

# Test 13: FitScript stack example (language-level PUSH/POP)
run_test "FitScript stack example (uses PUSH/POP)" \
    "build/fitscript examples/fitscript/stack_example.fit -o /tmp/test_stack.fasm && [ \$(python3 src/vm.py /tmp/test_stack.fasm | grep -c 'Stack Push-ups') -eq 3 ]"

# Test 14: FitScript recursive flow (nested stack usage)
run_test "FitScript recursive flow demo" \
    "build/fitscript examples/fitscript/recursive_flow.fit -o /tmp/test_recursive.fasm && [ \$(python3 src/vm.py /tmp/test_recursive.fasm | grep -c 'Recursive Leaf') -eq 12 ]"

echo ""
echo "=================================="
echo "Test Results"
echo "=================================="
echo -e "Total tests: $test_count"
echo -e "${GREEN}Passed: $pass_count${NC}"
echo -e "${RED}Failed: $((test_count - pass_count))${NC}"

if [ $pass_count -eq $test_count ]; then
    echo -e "\n${GREEN}All tests passed! 🎉${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed.${NC}"
    exit 1
fi
