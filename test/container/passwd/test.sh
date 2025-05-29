#!/bin/bash

source ../core.sh

workspaces=("./")  # 비밀번호 테스트용으로 하나만 사용

dockit down all
action() {
  local -n ws=$1
  
  log_step "비밀번호 테스트 시작"
  
  # __a 디렉토리로 이동
  cd __a
  
  # 컨테이너 시작 (this 인자 추가)
  log_info "컨테이너 시작 중..."
  dockit up this
  
  # 잠시 대기 (컨테이너 완전 시작 대기)
  sleep 5
  
  # 컨테이너 상태 확인
  log_info "컨테이너 상태 확인"
  dockit status
  
  # 비밀번호 테스트를 위해 직접 docker exec 사용
  log_info "ubuntu 사용자 sudo 테스트 (비밀번호: 1234)"
  
  # 컨테이너 이름 가져오기
  CONTAINER_NAME=$(grep "CONTAINER_NAME=" .dockit_project/.env | cut -d'"' -f2)
  log_info "컨테이너 이름: $CONTAINER_NAME"
  
  # 직접 docker exec로 테스트
  echo "1234" | docker exec -i "$CONTAINER_NAME" sudo -S whoami
  
  if [ $? -eq 0 ]; then
    log_success "비밀번호 테스트 성공!"
  else
    log_error "비밀번호 테스트 실패!"
  fi
  
  # 추가 테스트: apt update 실행
  log_info "sudo apt update 테스트"
  echo "1234" | docker exec -i "$CONTAINER_NAME" sudo -S apt update
  
  cd -
}

tests_reset_run "비밀번호 테스트" workspaces action
