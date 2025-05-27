#!/bin/bash

source ../core.sh

workspaces=("__a" "__b")  # 전역 배열 선언 (local ❌)

dockit down all
action() {
  local -n ws=$1
  dockit list
  # for dir in "${ws[@]}"; do
    
  #   # 여기에 실제 테스트 동작 넣어도 돼
  # done
}

tests_reset_run "복수 작업 테스트" workspaces action
