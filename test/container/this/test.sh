#!/bin/bash

source ../core.sh

local work_space=("__a")

action() {
  local -n ws=$1
  for dir in "${ws[@]}"; do
    run_bash_command "cd $dir"
    log_step "컨테이너 정지 (dockit stop this)"
    run_bash_command "dockit stop this"

    # 컨테이너 시작 (this 인자 사용)
    log_step "컨테이너 재시작 (dockit start this)"
    run_bash_command "dockit start this"

    # 컨테이너 정지 (재정지 테스트)
    log_step "컨테이너 재정지 (dockit stop this)"
    run_bash_command "dockit stop this"
    run_bash_command "cd -"
  done
}

test_init_run_clear "this" work_space action
