#!/bin/bash

# status 모듈 - Docker 개발 환경 상태 확인

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 메인 함수
status_main() {
    log "INFO" "$MSG_STATUS_START"
    
    # 설정 로드
    load_config
    
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
    
    # 컨테이너 상태 출력
    echo -e "\n${YELLOW}$MSG_CONTAINER_STATUS:${NC}"
    echo -e "$MSG_CONTAINER_NAME: ${GREEN}$CONTAINER_NAME${NC}"
    echo -e "$MSG_CONTAINER_ID: ${GREEN}$(docker container inspect -f '{{.Id}}' "$CONTAINER_NAME")${NC}"
    echo -e "$MSG_CONTAINER_STATE: ${GREEN}$(docker container inspect -f '{{.State.Status}}' "$CONTAINER_NAME")${NC}"
    echo -e "$MSG_CONTAINER_CREATED: ${GREEN}$(docker container inspect -f '{{.Created}}' "$CONTAINER_NAME")${NC}"
    echo -e "$MSG_CONTAINER_IMAGE: ${GREEN}$(docker container inspect -f '{{.Config.Image}}' "$CONTAINER_NAME")${NC}"
    
    # 컨테이너가 실행 중이면 추가 정보 출력
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
        echo -e "$MSG_CONTAINER_IP: ${GREEN}$(docker container inspect -f '{{.NetworkSettings.IPAddress}}' "$CONTAINER_NAME")${NC}"
        echo -e "$MSG_CONTAINER_PORTS: ${GREEN}$(docker container inspect -f '{{range $p, $conf := .NetworkSettings.Ports}}{{$p}} {{end}}' "$CONTAINER_NAME")${NC}"
    fi
    
    log "SUCCESS" "$MSG_STATUS_COMPLETE"
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    status_main "$@"
fi 