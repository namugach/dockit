#!/bin/bash

# module_test.sh - 모듈 테스트 공통 프레임워크

# 사용법: ./src/dev/module_test.sh [모듈명]
# 예: ./src/dev/module_test.sh migrate

# 기본 환경 설정
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export MODULES_DIR="${PROJECT_ROOT}/src/modules"
export CONFIG_DIR="${PROJECT_ROOT}/.dockit"
export TEST_DIR="${PROJECT_ROOT}/test"
export UTILS_DIR="${PROJECT_ROOT}/src/utils"

# 테스트용 임시 디렉토리 설정
export TEST_TMP_DIR="/tmp/dockit_test_$RANDOM"
mkdir -p "$TEST_TMP_DIR"

# 유틸리티 모듈 로드 (가능한 경우)
# Load utility modules if available
source "$UTILS_DIR/utils.sh"

# 종료 시 임시 디렉토리 정리
cleanup() {
    # 모듈별 정리 함수가 있으면 호출
    if type cleanup_test &>/dev/null; then
        cleanup_test
    fi

    # 임시 디렉토리 정리
    rm -rf "$TEST_TMP_DIR"
    log_info "테스트 환경 정리 완료"
}
trap cleanup EXIT

# 메시지 함수 오버라이드
get_message() {
    echo "$1"
}

# 테스트 결과 추적
TEST_PASSED=0
TEST_FAILED=0

# 테스트 케이스 실행 함수
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    echo "===== 테스트 실행: $test_name ====="
    if $test_func; then
        log_info "테스트 성공: $test_name"
        TEST_PASSED=$((TEST_PASSED + 1))
        return 0
    else
        log_error "테스트 실패: $test_name"
        TEST_FAILED=$((TEST_FAILED + 1))
        return 1
    fi
}

# 모듈 로드 함수
load_module() {
    local module_name="$1"
    if [ -f "$MODULES_DIR/${module_name}.sh" ]; then
        source "$MODULES_DIR/${module_name}.sh"
        log_info "모듈 로드됨: ${module_name}.sh"
        return 0
    else
        log_error "모듈을 찾을 수 없음: ${module_name}.sh"
        return 1
    fi
}

# 테스트 환경 설정을 위한 설정 파일 생성 함수
create_test_config() {
    local config_dir="$1"
    mkdir -p "$config_dir"
    
    # 환경 설정 파일
    cat > "$config_dir/.env" << EOF
VERSION=1.0.0
WORKSPACE=/workspace
TIMEZONE=Asia/Seoul
EOF

    log_info "테스트 설정 파일 생성됨: $config_dir/.env"
}

# 모듈별 테스트 파일 확인
check_module_test_file() {
    local module_name="$1"
    local test_file="${PROJECT_ROOT}/src/dev/${module_name}_test.sh"
    
    if [ -f "$test_file" ]; then
        return 0
    else
        log_error "테스트 스크립트를 찾을 수 없음: ${module_name}_test.sh"
        return 1
    fi
}

# 메인 함수
main() {
    local module_name="$1"
    
    if [ -z "$module_name" ]; then
        log_error "모듈 이름을 지정해주세요."
        echo "사용법: $0 [모듈명]"
        exit 1
    fi
    
    log_info "모듈 테스트 시작: $module_name"
    
    # 테스트 환경 준비
    create_test_config "$TEST_TMP_DIR"
    export CONFIG_DIR="$TEST_TMP_DIR"
    
    # 모듈 로드
    if ! load_module "$module_name"; then
        exit 1
    fi
    
    # 모듈별 테스트 실행
    if check_module_test_file "$module_name"; then
        source "${PROJECT_ROOT}/src/dev/${module_name}_test.sh"
        if type run_module_tests &>/dev/null; then
            run_module_tests
        else
            log_error "run_module_tests 함수를 찾을 수 없습니다: ${module_name}_test.sh"
            exit 1
        fi
    else
        exit 1
    fi
    
    # 테스트 결과 요약
    echo ""
    echo "===== 테스트 결과 요약 ====="
    echo "성공: $TEST_PASSED"
    echo "실패: $TEST_FAILED"
    
    if [ $TEST_FAILED -eq 0 ]; then
        log_info "모든 테스트 통과!"
        exit 0
    else
        log_error "일부 테스트 실패!"
        exit 1
    fi
}

# 스크립트 실행
main "$@" 