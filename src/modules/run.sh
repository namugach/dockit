#!/bin/bash

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" "run"

# Load modules
# 모듈 로드
source "$MODULES_DIR/init.sh"
source "$MODULES_DIR/build.sh"
source "$MODULES_DIR/up.sh"
source "$MODULES_DIR/start.sh"

# 초기화 함수
# Initialization function
run_init() {
    log "INFO" "$MSG_RUN_INIT_START"
    # 1. 초기화 (init)
    echo "y" | init_main "$@"
    log "INFO" "$MSG_RUN_INIT_COMPLETE"
}

# 이미지 빌드 함수
# Image build function
run_build() {
    log "INFO" "$MSG_RUN_BUILD_START"
    # 2. 이미지 빌드 (build)
    echo "y" | build_main "this"
    log "INFO" "$MSG_RUN_BUILD_COMPLETE"
}

# 컨테이너 백그라운드 시작 함수
# Container background start function
run_up() {
    log "INFO" "$MSG_RUN_UP_START"
    # 3. 컨테이너 백그라운드에서 시작 (up)
    echo "y" | up_main "this"
    log "INFO" "$MSG_RUN_UP_COMPLETE"
}


# Run main function
# 실행 메인 함수
run_main() {
    log "INFO" "$MSG_RUN_START"
    
    # 1. 초기화 실행
    run_init "$@"
    
    # 2. 이미지 빌드 실행
    run_build "$@"
    
    # 3. 컨테이너 백그라운드에서 시작
    run_up "$@"
    
    
    log "SUCCESS" "$MSG_RUN_COMPLETE"
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_main "$@"
fi 