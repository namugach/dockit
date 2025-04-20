#!/bin/bash

# Up module - Start Docker development environment in background
# up 모듈 - Docker 개발 환경을 백그라운드에서 시작

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Main function
# 메인 함수
up_main() {
    log "INFO" "$MSG_UP_START"
    
    # Check if Docker Compose file exists
    # Docker Compose 파일이 있는지 확인
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
        exit 1
    fi
    
    # Check container status
    # 컨테이너 상태 확인
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
            log "WARNING" "$MSG_CONTAINER_ALREADY_RUNNING"
            exit 0
        fi
    fi
    
    # Start container in background
    # 컨테이너를 백그라운드에서 시작
    log "INFO" "$MSG_STARTING_IN_BACKGROUND"
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d; then
        log "SUCCESS" "$MSG_CONTAINER_STARTED"
        log "INFO" "$MSG_CONTAINER_RUNNING_BACKGROUND"
        
        # Print container status
        # 컨테이너 상태 출력
        log "INFO" "$MSG_CONTAINER_INFO: $CONTAINER_NAME"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.ID}}\t{{.Status}}\t{{.Ports}}"
    else
        log "ERROR" "$MSG_CONTAINER_START_FAILED"
        log "INFO" "$MSG_CHECK_DOCKER"
        log "INFO" "$MSG_CHECK_PORTS"
        log "INFO" "$MSG_CHECK_IMAGE"
        exit 1
    fi
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    up_main "$@"
fi 