#!/bin/bash

# run 모듈 테스트 
# run module test

# 스크립트 디렉토리 가져오기
# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "$SCRIPT_DIR")" && pwd)"
TEST_DIR="$SCRIPT_DIR"

# 테스트 유틸리티 로드
# Load test utilities
source "$TEST_DIR/test_utils.sh"

# 테스트할 모듈 로드
# Load the module to test
source "$PROJECT_ROOT/src/modules/run.sh"

# 각 단계를 모킹하기 위한 함수들
# Mock functions for each step

# 초기화 모킹 함수
# Mock initialization function
init_main() {
    echo "Mock init_main called with args: $@"
    return 0
}

# 빌드 모킹 함수 
# Mock build function
build_main() {
    echo "Mock build_main called with args: $@"
    return 0
}

# 컨테이너 백그라운드 시작 모킹 함수
# Mock up function
up_main() {
    echo "Mock up_main called with args: $@"
    return 0
}

# 컨테이너 시작 모킹 함수
# Mock start function
start_main() {
    echo "Mock start_main called with args: $@"
    return 0
}

# 자동 실행 테스트
# Test automatic run
test_run_automation() {
    # 테스트 실행
    # Run test
    test_start "run automated process"
    output=$(run_main 2>&1)
    
    # 각 모듈이 호출되었는지 검증
    # Verify each module was called
    assertContains "$output" "Mock init_main called" "init_main should be called"
    assertContains "$output" "Mock build_main called" "build_main should be called"
    assertContains "$output" "Mock up_main called" "up_main should be called"
    assertContains "$output" "Mock start_main called" "start_main should be called"
    
    test_end
}

# 명령줄 인자 전달 테스트
# Test command line arguments passing
test_run_with_args() {
    # 테스트 실행
    # Run test
    test_start "run with command line arguments"
    
    # 명령줄 인자를 전달하여 테스트
    # Test with command line arguments
    local test_args="--test-arg1 --test-arg2"
    output=$(run_main $test_args 2>&1)
    
    # 인자가 제대로 전달되는지 검증
    # Verify arguments are passed correctly
    assertContains "$output" "Mock init_main called with args: $test_args" "Arguments should be passed to init_main"
    assertContains "$output" "Mock build_main called with args: $test_args" "Arguments should be passed to build_main"
    assertContains "$output" "Mock up_main called with args: $test_args" "Arguments should be passed to up_main"
    assertContains "$output" "Mock start_main called with args: $test_args" "Arguments should be passed to start_main"
    
    test_end
}

# 모든 테스트 실행
# Run all tests
run_tests() {
    # 테스트 환경 설정
    # Setup test environment
    setup_test_env
    
    # 테스트 실행
    # Run tests
    test_run_automation
    test_run_with_args
    
    # 테스트 결과 요약
    # Summarize test results
    summarize_tests
}

# 스크립트가 직접 실행되면 테스트 실행
# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi 