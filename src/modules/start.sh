#!/bin/bash

# Start module - Start Docker development environment
# start 모듈 - Docker 개발 환경 시작

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Main function
# 메인 함수
start_main() {
    log "INFO" "$MSG_START_START"
    
    # 설정 로드
    # Load configuration
    load_env
    
    # Docker Compose 파일이 있는지 확인
    # Check if Docker Compose file exists
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
        exit 1
    fi
    
    # 컨테이너 존재 여부 확인
    # Check if container exists
    if ! docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        echo -e "\n${YELLOW}$MSG_CONTAINER_NOT_FOUND_INFO${NC}"
        echo -e "${BLUE}dockit up${NC}"
        exit 1
    fi
    
    # 컨테이너가 이미 실행 중인지 확인
    # Check if container is already running
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
        log "WARNING" "$MSG_CONTAINER_ALREADY_RUNNING"
        exit 0
    fi
    
    # 컨테이너 시작
    # Start container
    log "INFO" "$MSG_STARTING_CONTAINER"
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" start; then
        log "SUCCESS" "$MSG_CONTAINER_STARTED"
        
        # 연결 방법 안내
        # Show connect instruction
        echo -e "\n${BLUE}$MSG_CONNECT_INFO${NC} dockit connect"
    else
        log "ERROR" "$MSG_CONTAINER_START_FAILED"
        exit 1
    fi
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start_main "$@"
fi 