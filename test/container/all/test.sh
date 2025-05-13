#!/bin/bash

source ../core.sh

container_index="all"
work_space_a="__a"
work_space_b="__b"
work_space_group="$work_space_a $work_space_b"


# 테스트 시작
log_step "테스트 시작: $container_index 인자를 사용한 컨테이너 시작/정지 테스트"

# 기존 환경 정리
log_step "기존 환경 정리"
dockit_in_path $work_space_a "down"
dockit_in_path $work_space_b "down"
run_bash_command $RESET_FILE_PATH
run_bash_command "rm -rf $work_space_group"


log_step "작업 디렉토리 생성"
run_bash_command "mkdir $work_space_group"

dockit_init_boot_in_path $work_space_a "up"
dockit_init_boot_in_path $work_space_b "up"

# 컨테이너 정지 ($container_index 인자 사용)
log_step "컨테이너 정지 (dockit stop $container_index)"
run_bash_command "dockit stop $container_index"

# 컨테이너 시작 (@ 인자 사용)
log_step "컨테이너 재시작 (dockit start $container_index)"
run_bash_command "dockit start $container_index"

# 컨테이너 정지 (재정지 테스트)
log_step "컨테이너 재정지 (dockit stop $container_index)"
run_bash_command "dockit stop $container_index"

# 환경 정리
log_step "환경 정리 (dockit down)"
dockit_init_boot_in_path $work_space_a "down"
dockit_init_boot_in_path $work_space_b "down"

run_bash_command "rm -rf $work_space_group"

# 테스트 완료
log_step "테스트 완료"
log_success "모든 테스트가 성공적으로 완료되었습니다!"

echo "test 완료"