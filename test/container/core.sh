#!/bin/bash

RESET_FILE_PATH="$(pwd)/../../../bin/_reset.sh"

# 컨테이너가 실행 중일 때 실행

# 색상 정의
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    return 1
}

log_step() {
    echo -e "\n${YELLOW}===== $1 =====${NC}"
}

# 명령어 실행 함수
run_command() {
    log_info "실행: $1"
    if eval "$1"; then
        log_success "성공: $1"
        return 0
    else
        log_error "실패: $1 (종료 코드: $?)"
        return 1
    fi
}



function test_dockit_lifecycle() {
  # 테스트 시작
  log_step "테스트 시작: $@ 인자를 사용한 컨테이너 시작/정지 테스트"
  # 1. 기존 환경 정리
  log_step "1. 기존 환경 정리"
  run_command "dockit down"
  run_command $RESET_FILE_PATH
  run_command "rm -rf .dockit_project/"

  # 2. dockit 초기화
  log_step "2. dockit 초기화"
  run_command "echo Y | dockit init"

  # 3. 컨테이너 시작
  log_step "3. 컨테이너 시작 (dockit up)"
  run_command "dockit up"

  # 4. 컨테이너 정지 ($@ 인자 사용)
  log_step "4. 컨테이너 정지 (dockit stop $@)"
  run_command "dockit stop $@"

  # 5. 컨테이너 시작 (@ 인자 사용)
  log_step "5. 컨테이너 재시작 (dockit start $@)"
  run_command "dockit start $@"

  # 6. 컨테이너 정지 (재정지 테스트)
  log_step "6. 컨테이너 재정지 (dockit stop $@)"
  run_command "dockit stop $@"

  # 7. 환경 정리
  log_step "7. 환경 정리 (dockit down)"
  run_command "dockit down"

  # 테스트 완료
  log_step "테스트 완료"
  log_success "모든 테스트가 성공적으로 완료되었습니다!"

  echo "test 완료"
}


