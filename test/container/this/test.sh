#!/bin/bash

source ../core.sh

# 테스트 시작
log_step "테스트 시작: this 인자를 사용한 컨테이너 시작/정지 테스트"
# 기존 환경 정리
log_step "기존 환경 정리"
run_bash_command "dockit down"
run_bash_command $RESET_FILE_PATH
run_bash_command "rm -rf .dockit_project/"

# dockit 초기화
log_step "dockit 초기화"
run_bash_command "echo Y | dockit init"

# 컨테이너 시작
log_step "컨테이너 시작 (dockit up)"
run_bash_command "dockit up"

# 컨테이너 정지 (this 인자 사용)
log_step "컨테이너 정지 (dockit stop this)"
run_bash_command "dockit stop this"

# 컨테이너 시작 (@ 인자 사용)
log_step "컨테이너 재시작 (dockit start this)"
run_bash_command "dockit start this"

# 컨테이너 정지 (재정지 테스트)
log_step "컨테이너 재정지 (dockit stop this)"
run_bash_command "dockit stop this"

# 환경 정리
log_step "환경 정리 (dockit down)"
run_bash_command "dockit down"

# 테스트 완료
log_step "테스트 완료"
log_success "모든 테스트가 성공적으로 완료되었습니다!"

echo "test 완료"