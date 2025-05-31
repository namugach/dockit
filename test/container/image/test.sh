#!/bin/bash

source ../core.sh

workspaces=("img_test_a" "img_test_b" "img_test_c")  # 이미지 테스트용 3개 workspace

dockit down all

action() {
  local -n ws=$1
  
  log_step "이미지 관리 기능 통합 테스트 시작"
  
  # Phase 1: 여러 프로젝트에서 이미지 빌드
  log_step "Phase 1: 테스트 이미지들 빌드"
  for dir in "${ws[@]}"; do
    log_info "Building image in $dir"
    cd "$dir"
    run_bash_command "echo 'y' | dockit init"
    run_bash_command "dockit build this"
    cd -
  done
  
  # Phase 2: image list 테스트
  log_step "Phase 2: image list 기능 테스트"
  local list_output
  list_output=$(dockit image list)
  log_info "Image list output:"
  echo "$list_output"
  
  # 이미지 개수 확인 (3개 이상이어야 함)
  local image_count
  image_count=$(echo "$list_output" | grep -c "dockit-" || echo "0")
  if [ "$image_count" -ge 3 ]; then
    log_success "✓ Found $image_count dockit images (expected: >= 3)"
  else
    log_error "✗ Found only $image_count dockit images (expected: >= 3)"
  fi
  
  # Phase 3: image remove 테스트 (번호로)
  log_step "Phase 3: image remove 기능 테스트 (번호 방식)"
  log_info "Removing image #1 by number"
  local remove_output
  remove_output=$(echo "y" | dockit image remove 1 2>&1)
  log_info "Remove output: $remove_output"
  
  if echo "$remove_output" | grep -q "Successfully removed"; then
    log_success "✓ Image removal by number works"
  else
    log_error "✗ Image removal by number failed"
  fi
  
  # Phase 4: image remove 테스트 (이름으로)
  log_step "Phase 4: image remove 기능 테스트 (이름 방식)"
  
  # 남은 이미지 이름 하나 가져오기
  local remaining_image
  remaining_image=$(dockit image list | grep "dockit-" | head -1 | awk '{print $NF}')
  
  if [ -n "$remaining_image" ]; then
    log_info "Removing image by name: $remaining_image"
    local remove_name_output
    remove_name_output=$(echo "y" | dockit image remove "$remaining_image" 2>&1)
    log_info "Remove by name output: $remove_name_output"
    
    if echo "$remove_name_output" | grep -q "Successfully removed"; then
      log_success "✓ Image removal by name works"
    else
      log_error "✗ Image removal by name failed"
    fi
  else
    log_info "No remaining images to test name removal"
  fi
  
  # Phase 5: image prune 테스트
  log_step "Phase 5: image prune 기능 테스트"
  log_info "Testing prune functionality"
  local prune_output
  prune_output=$(echo "y" | dockit image prune 2>&1)
  log_info "Prune output: $prune_output"
  
  if echo "$prune_output" | grep -q "Successfully removed\|No unused"; then
    log_success "✓ Image prune works correctly"
  else
    log_error "✗ Image prune failed"
  fi
  
  # Phase 6: 새로운 이미지들 다시 생성 (clean 테스트용)
  log_step "Phase 6: clean 테스트를 위한 이미지 재생성"
  for dir in "${ws[@]}"; do
    log_info "Rebuilding image in $dir for clean test"
    cd "$dir"
    run_bash_command "dockit build this"
    cd -
  done
  
  # Phase 7: image clean 테스트 (취소 시나리오)
  log_step "Phase 7: image clean 기능 테스트 (취소 시나리오)"
  log_info "Testing clean cancellation"
  local clean_cancel_output
  clean_cancel_output=$(printf "y\nCANCEL\n" | dockit image clean 2>&1)
  log_info "Clean cancel output: $clean_cancel_output"
  
  if echo "$clean_cancel_output" | grep -q "cancelled"; then
    log_success "✓ Image clean cancellation works"
  else
    log_error "✗ Image clean cancellation failed"
  fi
  
  # Phase 8: 이미지가 아직 남아있는지 확인
  log_step "Phase 8: 취소 후 이미지 잔존 확인"
  local remaining_after_cancel
  remaining_after_cancel=$(dockit image list | grep -c "dockit-" || echo "0")
  if [ "$remaining_after_cancel" -gt 0 ]; then
    log_success "✓ Images still exist after clean cancellation ($remaining_after_cancel images)"
  else
    log_error "✗ Images unexpectedly removed after cancellation"
  fi
  
  # Phase 9: image clean 테스트 (실제 삭제)
  log_step "Phase 9: image clean 기능 테스트 (실제 삭제)"
  log_info "Testing actual clean execution"
  local clean_execute_output
  clean_execute_output=$(printf "y\nDELETE\n" | dockit image clean 2>&1)
  log_info "Clean execute output: $clean_execute_output"
  
  if echo "$clean_execute_output" | grep -q "Successfully removed\|No dockit images"; then
    log_success "✓ Image clean execution works"
  else
    log_error "✗ Image clean execution failed"
  fi
  
  # Phase 10: 모든 이미지가 제거되었는지 확인
  log_step "Phase 10: clean 후 이미지 완전 제거 확인"
  local final_count
  final_count=$(dockit image list | grep -c "dockit-" || echo "0")
  if [ "$final_count" -eq 0 ]; then
    log_success "✓ All dockit images successfully removed ($final_count remaining)"
  else
    log_error "✗ Some images still remain after clean ($final_count remaining)"
  fi
  
  # Phase 11: 빈 상태에서 각 명령어 테스트
  log_step "Phase 11: 빈 상태에서 명령어 동작 확인"
  
  log_info "Testing list on empty state"
  local empty_list_output
  empty_list_output=$(dockit image list 2>&1)
  if echo "$empty_list_output" | grep -q "No dockit images found"; then
    log_success "✓ Empty state list works"
  else
    log_error "✗ Empty state list failed"
  fi
  
  log_info "Testing prune on empty state"
  local empty_prune_output
  empty_prune_output=$(dockit image prune 2>&1)
  if echo "$empty_prune_output" | grep -q "No dockit images found"; then
    log_success "✓ Empty state prune works"
  else
    log_error "✗ Empty state prune failed"
  fi
  
  log_info "Testing clean on empty state"
  local empty_clean_output
  empty_clean_output=$(dockit image clean 2>&1)
  if echo "$empty_clean_output" | grep -q "No dockit images found"; then
    log_success "✓ Empty state clean works"
  else
    log_error "✗ Empty state clean failed"
  fi
  
  log_step "이미지 관리 기능 통합 테스트 완료"
  log_success "모든 image 모듈 기능이 정상적으로 작동합니다!"
}

tests_reset_run "이미지 관리 통합 테스트" workspaces action
