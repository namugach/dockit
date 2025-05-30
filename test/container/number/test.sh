#!/bin/bash

source ../core.sh

local work_space=("__a" "__b")

action() {
  local -n ws=$1
  # 컨테이너 정지 (number 인자 사용)
  log_step "컨테이너 정지" "dockit stop 1 2"
  run_bash_command "dockit stop 1 2"

  # 컨테이너 시작 (number 인자 사용)
  log_step "컨테이너 재시작" "dockit start 1 2"
  run_bash_command "dockit start 1 2"

  # 컨테이너 정지 (재정지 테스트)
  log_step "컨테이너 재정지" "dockit stop 1 2"
  run_bash_command "dockit stop 1 2"
}

test_init_run_clear "number" work_space action