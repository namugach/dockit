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
run_bash_command() {
    log_info "실행: $1"
    if eval "$1"; then
        log_success "성공: $1"
        return 0
    else
        log_error "실패: $1 (종료 코드: $?)"
        return 1
    fi
}

run_dockit_command() {
  local command=$1
  log_step "컨테이너 명령 실행 (dockit $command)"
  run_bash_command "dockit $command"
  run_bash_command "cd -"
}

dockit_in_path() {
  local work_path=$1
  local command=$2
  log_step "dockit $command"
  run_bash_command "cd $work_path"

  run_dockit_command $command
}


dockit_init_boot_in_path() {
  local work_path=$1
  local command=$2
  log_step "dockit 초기화"
  run_bash_command "cd $work_path"
  run_bash_command "echo Y | dockit init"

  run_dockit_command $command
}


test_dockit_lifecycle() {
  # 테스트 시작
  log_step "테스트 시작: $@ 인자를 사용한 컨테이너 시작/정지 테스트"
  # 1. 기존 환경 정리
  log_step "1. 기존 환경 정리"
  run_bash_command "dockit down"
  run_bash_command $RESET_FILE_PATH
  run_bash_command "rm -rf .dockit_project/"

  # 2. dockit 초기화
  log_step "2. dockit 초기화"
  run_bash_command "echo Y | dockit init"

  # 3. 컨테이너 시작
  log_step "3. 컨테이너 시작 (dockit up)"
  run_bash_command "dockit up"

  # 4. 컨테이너 정지 ($@ 인자 사용)
  log_step "4. 컨테이너 정지 (dockit stop $@)"
  run_bash_command "dockit stop $@"

  # 5. 컨테이너 시작 (@ 인자 사용)
  log_step "5. 컨테이너 재시작 (dockit start $@)"
  run_bash_command "dockit start $@"

  # 6. 컨테이너 정지 (재정지 테스트)
  log_step "6. 컨테이너 재정지 (dockit stop $@)"
  run_bash_command "dockit stop $@"

  # 7. 환경 정리
  log_step "7. 환경 정리 (dockit down)"
  run_bash_command "dockit down"

  # 테스트 완료
  log_step "테스트 완료"
  log_success "모든 테스트가 성공적으로 완료되었습니다!"

  echo "test 완료"
}

test() {
  local index=$1
  container_index="$index"
  work_space_a="__a"
  work_space_b="__b"
  work_space_group="$work_space_a $work_space_b"


  # 테스트 시작
  log_step "테스트 시작: $container_index 인자를 사용한 컨테이너 시작/정지 테스트"

  # 기존 환경 정리
  log_step "기존 환경 정리"
  dockit_in_path $work_space_a "down"
  dockit_in_path $work_space_b "down"
  run_bash_command $RESET_FILE_PATH
  run_bash_command "rm -rf $work_space_group"


  log_step "작업 디렉토리 생성"
  run_bash_command "mkdir $work_space_group"

  dockit_init_boot_in_path $work_space_a "up"
  dockit_init_boot_in_path $work_space_b "up"

  # 컨테이너 정지 ($container_index 인자 사용)
  log_step "컨테이너 정지 (dockit stop $container_index)"
  run_bash_command "dockit stop $container_index"

  # 컨테이너 시작 (@ 인자 사용)
  log_step "컨테이너 재시작 (dockit start $container_index)"
  run_bash_command "dockit start $container_index"

  # 컨테이너 정지 (재정지 테스트)
  log_step "컨테이너 재정지 (dockit stop $container_index)"
  run_bash_command "dockit stop $container_index"

  # 환경 정리
  log_step "환경 정리 (dockit down)"
  dockit_init_boot_in_path $work_space_a "down"
  dockit_init_boot_in_path $work_space_b "down"

  run_bash_command "rm -rf $work_space_group"

  # 테스트 완료
  log_step "테스트 완료"
  log_success "모든 테스트가 성공적으로 완료되었습니다!"

  echo "test 완료"
}