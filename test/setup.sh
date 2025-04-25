#!/bin/bash

# setup 모듈 테스트 
# setup module test

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
source "$PROJECT_ROOT/src/modules/setup.sh"

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

# 시작 모킹 함수
# Mock up function
up_main() {
    echo "Mock up_main called with args: $@"
    return 0
}

# 접속 모킹 함수
# Mock connect function
connect_main() {
    echo "Mock connect_main called with args: $@"
    return 0
}

# Yes 입력을 시뮬레이션하는 테스트
# Test to simulate 'Yes' inputs
test_setup_with_yes_inputs() {
    # YES 입력 시뮬레이션
    # Simulate YES inputs
    yes_input() {
        echo "y"
    }
    
    # 사용자 입력 함수를 오버라이드
    # Override read command to simulate user input
    read() {
        yes_input
    }
    
    # 테스트 실행
    # Run test
    test_start "setup with all 'yes' inputs"
    output=$(setup_main 2>&1)
    
    # 각 모듈이 호출되었는지 검증
    # Verify each module was called
    assertContains "$output" "Mock init_main called" "init_main should be called"
    assertContains "$output" "Mock build_main called" "build_main should be called"
    assertContains "$output" "Mock up_main called" "up_main should be called"
    assertContains "$output" "Mock connect_main called" "connect_main should be called"
    
    test_end
}

# No 입력을 시뮬레이션하는 테스트 (Build 단계에서 No)
# Test to simulate 'No' input at Build stage
test_setup_with_no_at_build() {
    # NO 입력 시뮬레이션
    # Simulate NO input
    no_input() {
        echo "n"
    }
    
    # 사용자 입력 함수를 오버라이드
    # Override read command to simulate user input
    read() {
        no_input
    }
    
    # 테스트 실행
    # Run test
    test_start "setup with 'no' at build step"
    output=$(setup_main 2>&1)
    
    # 초기화는 호출되고 빌드는 건너뛰는지 검증
    # Verify init is called but build is skipped
    assertContains "$output" "Mock init_main called" "init_main should be called"
    assertContains "$output" "$MSG_SETUP_BUILD_SKIPPED" "Build should be skipped with message"
    assertNotContains "$output" "Mock up_main called" "up_main should not be called after build skip"
    
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
    test_setup_with_yes_inputs
    test_setup_with_no_at_build
    
    # 테스트 결과 요약
    # Summarize test results
    summarize_tests
}

# 스크립트가 직접 실행되면 테스트 실행
# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi 