#!/bin/bash

source ../core.sh

workspaces=("./")  # 비밀번호 테스트용으로 하나만 사용

dockit down all
action() {
  local -n ws=$1
}

tests_reset_run "build" workspaces action
