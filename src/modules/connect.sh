#!/bin/bash

# connect 모듈 - Docker 개발 환경 접속
# connect module - Connect to Docker development environment

# 공통 모듈 로드
# Load common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 메인 함수
# Main function
connect_main() {
    log "INFO" "$MSG_CONNECT_START"
    
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
        echo -e "\n${YELLOW}$MSG_START_CONTAINER_FIRST${NC}"
        echo -e "${BLUE}dockit start${NC}"
        exit 1
    fi
    
    # 컨테이너가 실행 중인지 확인
    # Check if container is running
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" != "true" ]; then
        log "WARNING" "$MSG_CONTAINER_NOT_RUNNING"
        
        # 컨테이너 시작 여부 확인
        # Ask if container should be started
        echo -e "\n${YELLOW}$MSG_WANT_START_CONTAINER${NC}"
        read -p "$MSG_SELECT_CHOICE [Y/n]: " start_container
        start_container=${start_container:-y}
        
        if [[ $start_container == "y" || $start_container == "Y" ]]; then
            log "INFO" "$MSG_STARTING_CONTAINER"
            
            # 컨테이너 시작
            # Start container
            if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" start; then
                log "SUCCESS" "$MSG_CONTAINER_STARTED"
            else
                log "ERROR" "$MSG_CONTAINER_START_FAILED"
                exit 1
            fi
        else
            log "INFO" "$MSG_START_CANCELLED"
            exit 0
        fi
    fi
    
    # 컨테이너 접속
    # Connect to container
    log "INFO" "$MSG_CONNECTING_CONTAINER"
    log "SUCCESS" "$MSG_CONNECTED"
    
    if docker exec -it "$CONTAINER_NAME" /bin/bash; then
        # 접속 종료 후 메시지 없음
        :
    else
        log "ERROR" "$MSG_CONNECT_FAILED"
        exit 1
    fi
}

# 직접 실행 시
# When executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    connect_main "$@"
fi 