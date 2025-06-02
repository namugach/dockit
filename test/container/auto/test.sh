#!/bin/bash

source ../core.sh

workspaces=("./")  # 이미지 테스트용 3개 workspace

dockit down all
printf "y\nDELETE\n" | dockit image clean
action() {
  local -n ws=$1
  dockit run
}

tests_reset_run "join test" workspaces action
