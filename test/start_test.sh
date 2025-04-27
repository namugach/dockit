#!/bin/bash

# 테스트 디렉토리 결정
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

# 모듈 경로 설정
MODULE_DIR="$PROJECT_ROOT/src/modules"
START_MODULE="$MODULE_DIR/start.sh"

# 테스트 로그 함수
log_test() {
    local level="$1"
    local message="$2"
    
    echo "[$level] $message"
}

# 테스트 실패 함수
fail_test() {
    local message="$1"
    
    log_test "FAIL" "$message"
    exit 1
}

# 모듈 존재 여부 확인
if [ ! -f "$START_MODULE" ]; then
    fail_test "start.sh module not found at: $START_MODULE"
fi

log_test "INFO" "Testing start.sh module..."

# 테스트 1: 모듈 직접 실행
test_module_direct_execution() {
    log_test "TEST" "Testing module direct execution"
    
    # 인자 없이 실행
    output=$("$START_MODULE" 2>&1)
    
    if ! echo "$output" | grep -q "usage"; then
        fail_test "Failed to show usage when run without arguments"
    fi
    
    log_test "PASS" "Module direct execution test passed"
}

# 테스트 2: 잘못된 인자 테스트
test_invalid_args() {
    log_test "TEST" "Testing invalid arguments"
    
    # 잘못된 인자로 실행
    output=$("$START_MODULE" "invalid_arg" 2>&1)
    
    if ! echo "$output" | grep -q "Invalid" && ! echo "$output" | grep -q "invalid"; then
        fail_test "Failed to handle invalid arguments correctly"
    fi
    
    log_test "PASS" "Invalid arguments test passed"
}

# 테스트 3: 함수 유효성 테스트
test_function_validity() {
    log_test "TEST" "Testing function validity"
    
    # start.sh 소스로 로드
    source "$START_MODULE"
    
    # 필수 함수 존재 확인
    if ! declare -f start_main > /dev/null; then
        fail_test "Required function start_main not found"
    fi
    
    if ! declare -f start_container > /dev/null; then
        fail_test "Required function start_container not found"
    fi
    
    if ! declare -f start_current_project > /dev/null; then
        fail_test "Required function start_current_project not found"
    fi
    
    if ! declare -f get_container_id_by_index > /dev/null; then
        fail_test "Required function get_container_id_by_index not found"
    fi
    
    if ! declare -f start_all_containers > /dev/null; then
        fail_test "Required function start_all_containers not found"
    fi
    
    log_test "PASS" "Function validity test passed"
}

# 모든 테스트 실행
run_all_tests() {
    test_module_direct_execution
    test_invalid_args
    test_function_validity
    
    log_test "SUCCESS" "All tests passed!"
}

# 모든 테스트 실행
run_all_tests 