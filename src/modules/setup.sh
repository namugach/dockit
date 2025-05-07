#!/bin/bash

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" "setup"

# Load modules
# 모듈 로드
source "$MODULES_DIR/init.sh"
source "$MODULES_DIR/build.sh"
source "$MODULES_DIR/up.sh"
source "$MODULES_DIR/connect.sh"

# 초기화 함수
# Initialization function
run_init() {
    # 1. 초기화 (init)
    init_main "$@"
}

# 이미지 빌드 함수
# Image build function
run_build() {
    # 2. 이미지 빌드 (build)
    echo -e "\n${YELLOW}$MSG_SETUP_BUILD_PROMPT${NC}"
    read -p "$MSG_SELECT_CHOICE [Y/n]: " build_choice
    build_choice=${build_choice:-y}
    
    if [[ $build_choice == "y" || $build_choice == "Y" ]]; then
        build_main "$@"
        return 0
    else
        log "INFO" "$MSG_SETUP_TERMINATED"
        exit 1
    fi
}

# 컨테이너 시작 함수
# Container start function
run_up() {
    # 3. 컨테이너 시작 (up)
    echo -e "\n${YELLOW}$MSG_START_CONTAINER_NOW${NC}"
    read -p "$MSG_SELECT_CHOICE [Y/n]: " up_choice
    up_choice=${up_choice:-y}
    
    if [[ $up_choice == "y" || $up_choice == "Y" ]]; then
        up_main "$@"
        return 0
    else
        log "INFO" "$MSG_SETUP_TERMINATED"
        exit 1
    fi
}

# 컨테이너 접속 함수
# Container connect function
run_connect() {
    # 4. 컨테이너 접속 (connect)
    echo -e "\n${YELLOW}$MSG_CONNECT_CONTAINER_NOW${NC}"
    read -p "$MSG_SELECT_CHOICE [Y/n]: " connect_choice
    connect_choice=${connect_choice:-y}
    
    if [[ $connect_choice == "y" || $connect_choice == "Y" ]]; then
        connect_main "$@"
        return 0
    else
        log "INFO" "$MSG_SETUP_TERMINATED"
        exit 1
    fi
}

# Setup main function
# 설정 메인 함수
setup_main() {
    log "INFO" "$MSG_SETUP_START"
    
    # 1. 초기화 실행
    run_init "$@"
    
    # 2. 이미지 빌드 실행
    run_build "$@"
    
    # 3. 컨테이너 시작 실행
    run_up "$@"
    
    # 4. 컨테이너 접속 실행
    run_connect "$@"

    
    log "SUCCESS" "$MSG_SETUP_COMPLETE"
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_main "$@"
fi