#!/bin/bash

# connect 모듈 - Docker 개발 환경 접속

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 메인 함수
connect_main() {
    log "INFO" "$MSG_CONNECT_START"
    
    # Docker Compose 파일이 있는지 확인
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
        exit 1
    fi
    
    # 컨테이너 상태 확인
    if ! docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        log "INFO" "$MSG_START_CONTAINER_FIRST"
        exit 1
    fi
    
    # 컨테이너가 실행 중인지 확인
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" != "true" ]; then
        log "WARNING" "$MSG_CONTAINER_NOT_RUNNING"
        log "INFO" "$MSG_START_CONTAINER_FIRST"
        exit 1
    fi
    
    # 컨테이너 접속
    log "INFO" "$MSG_CONNECTING_CONTAINER"
    if docker exec -it "$CONTAINER_NAME" /bin/bash; then
        log "SUCCESS" "$MSG_CONNECTED"
    else
        log "ERROR" "$MSG_CONNECT_FAILED"
        exit 1
    fi
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    connect_main "$@"
fi 