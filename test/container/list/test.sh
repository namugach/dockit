#!/bin/bash

source ../core.sh

local work_space=("__a" "__b")

action() {
  local -n ws=$1
  # 컨테이너 정지 (number 인자 사용)
  dockit list
}

test_base "number" work_space action