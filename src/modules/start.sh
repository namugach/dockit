#!/bin/bash

# Start module - Start Docker development environment
# start 모듈 - Docker 개발 환경 시작

# Load common module
# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# Main function
# 메인 함수
start_main() {
    log "INFO" "$MSG_START_START"
    
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
    
    # Start container
    # 컨테이너 시작
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d; then
        log "SUCCESS" "$MSG_CONTAINER_STARTED"
        
        # Ask if user wants to connect to container
        # 컨테이너 접속 여부 확인
        echo -e "\n${YELLOW}$MSG_CONNECT_CONTAINER_NOW?${NC}"
        read -p "$MSG_SELECT_CHOICE [Y/n]: " connect_container
        connect_container=${connect_container:-y}
        
        if [[ $connect_container == "y" || $connect_container == "Y" ]]; then
            log "INFO" "$MSG_CONNECTING_CONTAINER"
            docker exec -it "$CONTAINER_NAME" /bin/bash
        else
            log "INFO" "$MSG_SKIPPING_CONNECT"
            echo -e "\n${BLUE}$MSG_CONNECT_LATER${NC} ./dockit.sh connect"
        fi
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
    start_main "$@"
fi 