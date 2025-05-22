#!/bin/bash

source ../core.sh

local work_space=("__a")

action() {
  local -n ws=$1
  # 컨테이너 정지 (number 인자 사용)
  dockit list
}

test_init_run_clear "number" work_space action