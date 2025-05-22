#!/bin/bash

source ../core.sh

local work_space=("__a" "__b")

action() {
  local -n ws=$1
  # 컨테이너 정지 (all 인자 사용)
  log_step "컨테이너 정지" "dockit stop all"
  run_bash_command "dockit stop all"

  # 컨테이너 시작 (all 인자 사용)
  log_step "컨테이너 재시작" "dockit start all"
  run_bash_command "dockit start all"

  # 컨테이너 정지 (재정지 테스트)
  log_step "컨테이너 재정지" "dockit stop all"
  run_bash_command "dockit stop all"
}

test_init_run_clear "all" work_space action