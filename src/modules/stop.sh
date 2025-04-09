#!/bin/bash

# stop 모듈 - Docker 개발 환경 일시 중지
# stop module - Pause Docker development environment

# 공통 모듈 로드
# Load common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 메인 함수
# Main function
stop_main() {
    log "INFO" "$MSG_STOP_START"
    
    # Docker Compose 파일이 있는지 확인
    # Check if Docker Compose file exists
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
        exit 1
    fi
    
    # 컨테이너 상태 확인
    # Check container status
    if ! docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        exit 0
    fi
    
    # 컨테이너 중지
    # Stop container
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" stop; then
        log "SUCCESS" "$MSG_CONTAINER_STOPPED"
        echo -e "\n${BLUE}$MSG_CONTAINER_STOPPED_INFO${NC}"
    else
        log "ERROR" "$MSG_CONTAINER_STOP_FAILED"
        exit 1
    fi
}

# 직접 실행 시
# When executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    stop_main "$@"
fi 