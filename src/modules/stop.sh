#!/bin/bash

# stop 모듈 - Docker 개발 환경 일시 중지

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 메인 함수
stop_main() {
    log "INFO" "$MSG_STOP_START"
    
    # Docker Compose 파일이 있는지 확인
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
        exit 1
    fi
    
    # 컨테이너 상태 확인
    if ! docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        exit 0
    fi
    
    # 컨테이너 중지
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" stop; then
        log "SUCCESS" "$MSG_CONTAINER_STOPPED"
    else
        log "ERROR" "$MSG_CONTAINER_STOP_FAILED"
        exit 1
    fi
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    stop_main "$@"
fi 