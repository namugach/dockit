#!/bin/bash

# Test script for list module
# list 모듈 테스트 스크립트

# 테스트 디렉토리 설정
# Set test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
DOCKIT_BIN="$PROJECT_ROOT/bin/dockit.sh"

# ANSI 색상 코드
# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 테스트 결과 카운터
# Test result counters
PASSED=0
FAILED=0
TOTAL=0

# 테스트 성공 메시지 출력 함수
# Function to print test success message
test_pass() {
    PASSED=$((PASSED + 1))
    TOTAL=$((TOTAL + 1))
    echo -e "${GREEN}[PASS]${NC} $1"
}

# 테스트 실패 메시지 출력 함수
# Function to print test failure message
test_fail() {
    FAILED=$((FAILED + 1))
    TOTAL=$((TOTAL + 1))
    echo -e "${RED}[FAIL]${NC} $1: $2"
}

# 테스트 안내 메시지 출력 함수
# Function to print test info message
test_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 테스트 환경 준비
# Prepare test environment
prepare_test_env() {
    test_info "Preparing test environment..."
    
    # 테스트 디렉토리 생성
    # Create test directories
    mkdir -p "$TEST_DIR/temp/list_test/a"
    mkdir -p "$TEST_DIR/temp/list_test/b"
    mkdir -p "$TEST_DIR/temp/list_test/c"
    
    # 각 디렉토리에 dockit 초기화
    # Initialize dockit in each directory
    cd "$TEST_DIR/temp/list_test/a"
    yes y | "$DOCKIT_BIN" init > /dev/null 2>&1
    
    cd "$TEST_DIR/temp/list_test/b"
    yes y | "$DOCKIT_BIN" init > /dev/null 2>&1
    
    cd "$TEST_DIR/temp/list_test/c"
    yes y | "$DOCKIT_BIN" init > /dev/null 2>&1
    
    # 복제된 프로젝트 테스트를 위한 디렉토리 및 파일 생성
    # Create directory and file for cloned project test
    mkdir -p "$TEST_DIR/temp/list_test/cloned"
    cp -r "$TEST_DIR/temp/list_test/a/.dockit_project" "$TEST_DIR/temp/list_test/cloned/"
    
    cd "$PROJECT_ROOT"
}

# 테스트 환경 정리
# Clean up test environment
cleanup_test_env() {
    test_info "Cleaning up test environment..."
    
    # 테스트 디렉토리 제거
    # Remove test directories
    rm -rf "$TEST_DIR/temp/list_test"
    
    # 레지스트리 파일이 유효한지 확인
    # Check if registry file is valid
    if [ -f "$HOME/.dockit/registry.json" ]; then
        if ! jq '.' "$HOME/.dockit/registry.json" > /dev/null 2>&1; then
            test_info "Fixing corrupted registry file..."
            echo '{}' > "$HOME/.dockit/registry.json"
        fi
    fi
}

# 테스트 보고서 출력
# Print test report
print_test_report() {
    echo ""
    echo "=== Test Report ==="
    echo -e "${GREEN}PASSED:${NC} $PASSED"
    echo -e "${RED}FAILED:${NC} $FAILED"
    echo -e "TOTAL: $TOTAL"
    echo "=================="
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        return 1
    fi
}

# 일반 리스트 출력 테스트
# Test regular list output
test_list_output() {
    test_info "Testing list command output..."
    
    local output
    output=$("$DOCKIT_BIN" list)
    
    # 출력에 "등록된 프로젝트" 또는 "Registered Projects" 포함 여부 확인
    # Check if output contains "등록된 프로젝트" or "Registered Projects"
    if echo "$output" | grep -q "Registered Projects\|등록된 프로젝트"; then
        test_pass "List command shows correct header"
    else
        test_fail "List command header" "Expected 'Registered Projects' in output"
    fi
    
    # 테스트 프로젝트 3개 이상 표시되는지 확인
    # Check if at least 3 test projects are displayed
    local project_count
    project_count=$(echo "$output" | grep -c "~/dockit/test/temp/list_test/")
    
    if [ "$project_count" -ge 3 ]; then
        test_pass "List command shows the test projects"
    else
        test_fail "List project count" "Expected at least 3 projects, got $project_count"
    fi
}

# 프로젝트 ID 동기화 테스트
# Test project ID synchronization
test_id_sync() {
    test_info "Testing project ID synchronization..."
    
    # 복제된 프로젝트 디렉토리로 이동
    # Change to cloned project directory
    cd "$TEST_DIR/temp/list_test/cloned"
    
    # 프로젝트 ID 저장
    # Save original project ID
    local original_id=""
    if [ -f ".dockit_project/id" ]; then
        original_id=$(cat ".dockit_project/id")
    fi
    
    # dockit list 실행하여 ID 동기화 트리거
    # Run dockit list to trigger ID synchronization
    "$DOCKIT_BIN" list > /dev/null
    
    # 새 ID 확인
    # Check new ID
    local new_id=""
    if [ -f ".dockit_project/id" ]; then
        new_id=$(cat ".dockit_project/id")
    fi
    
    if [ -n "$original_id" ] && [ -n "$new_id" ] && [ "$original_id" != "$new_id" ]; then
        test_pass "Project ID synchronized correctly for cloned project"
        
        # 새 ID가 레지스트리에 등록되었는지 확인
        # Check if new ID is registered in registry
        if grep -q "$new_id" "$HOME/.dockit/registry.json"; then
            test_pass "New ID is registered in registry"
        else
            test_fail "Registry registration" "New ID not found in registry"
        fi
    else
        test_fail "Project ID synchronization" "ID not changed for cloned project"
    fi
    
    cd "$PROJECT_ROOT"
}

# 메인 테스트 함수
# Main test function
main() {
    echo "=== Running list module tests ==="
    
    # 테스트 환경 준비
    # Prepare test environment
    prepare_test_env
    
    # 테스트 실행
    # Run tests
    test_list_output
    test_id_sync
    
    # 테스트 환경 정리
    # Clean up test environment
    cleanup_test_env
    
    # 테스트 보고서 출력
    # Print test report
    print_test_report
}

# 스크립트가 직접 실행될 때만 메인 함수 실행
# Execute main function only when script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi 