#!/bin/bash

RESET_FILE_PATH="$(pwd)/../../../bin/_reset.sh"

# 컨테이너가 실행 중일 때 실행

# 색상 정의 로드
# Load color definitions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../src/utils/colors.sh"

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

projects_init() {
  local -n ref_workspaces=$1
  for workspace in "${ref_workspaces[@]}"; do
    run_bash_command "cd $workspace"
    run_bash_command "echo Y | dockit init"
    run_bash_command "cd -"
  done
}

projects_clear() {
  local -n ref_workspaces=$1
  for workspace in "${ref_workspaces[@]}"; do
    dockit_in_path "$workspace" "down";
    run_bash_command "rm -rf $workspace";
  done
}

projects_up() {
  local -n ref_workspaces=$1
  for workspace in "${ref_workspaces[@]}"; do
    dockit_init_boot_in_path "$workspace" 'up'
  done
}

# $1 = test_name: 테스트 이름 (기본값: dockit)
# $2 = workspaces: 작업 공간 배열 참조
# $3 = action_func: 테스트 액션 함수
# $4 = reset_file_path: 리셋 파일 경로 (기본값: $RESET_FILE_PATH)
test_init_run_clear() {
    local test_name="${1:-dockit}"
    local -n ref_workspaces=$2
    local action_func=$3
    local reset_file_path="${4:-$RESET_FILE_PATH}"
    
    # 테스트 시작
    log_step "테스트 시작: $test_name 테스트"

    # 기존 환경 정리
    log_step "기존 환경 정리"
    projects_clear $2
    
    # dockit 재설치
    run_bash_command "$reset_file_path"

    # 작업 디렉토리 생성
    log_step "작업 디렉토리 생성"
    run_bash_command "mkdir ${ref_workspaces[*]}"

    projects_up $2

    # 액션 실행
    log_info "path: ${ref_workspaces[*]}"
    $action_func $2

    # 환경 정리
    log_step "환경 정리 (dockit down)"
    projects_clear $2

    # 테스트 완료
    log_step "테스트 완료"
    log_success "모든 테스트가 성공적으로 완료되었습니다!"

    echo "test 완료"
}


test_reset_run() {
    local test_name="${1:-dockit}"
    local action_func=$2
    local reset_file_path="${3:-$RESET_FILE_PATH}"

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    log_step "테스트 시작 (초기화 및 실행): $test_name"
    run_bash_command "$reset_file_path"
    $action_func
    log_success "test_reset_run ${test_name} 완료"
}


tests_reset_run() {
    local test_name="${1:-dockit}"
    local -n ref_workspaces=$2
    local action_func=$3
    local reset_file_path="${4:-$RESET_FILE_PATH}"

    # 테스트 시작
    log_step "테스트 시작: $test_name 테스트"

    
    # dockit 재설치
    run_bash_command "$reset_file_path"

    # 작업 디렉토리 생성
    log_step "작업 디렉토리 생성"
    run_bash_command "mkdir -p ${ref_workspaces[*]}"

    projects_init $2
    
    log_info "workspaces: ${ref_workspaces[*]}"

    $action_func $2 

    log_success "test_reset_run ${test_name} 완료"
}
