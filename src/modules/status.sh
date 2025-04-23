#!/bin/bash

# status 모듈 - Docker 개발 환경 상태 확인
# status module - Check Docker development environment status

# 공통 모듈 로드
# Load common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 메인 함수
# Main function
status_main() {
    log "INFO" "$MSG_STATUS_START"
    
    # 설정 로드
    # Load configuration
    load_env
    
    # Docker Compose 파일이 있는지 확인
    # Check if Docker Compose file exists
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
        exit 1
    fi
    
    # 프로젝트 dockit 설정 정보 출력
    # Display project dockit settings
    echo -e "\n${YELLOW}$MSG_STATUS_PROJECT_CONFIG:${NC}"
    echo -e "$MSG_STATUS_VERSION: ${GREEN}${DOCKIT_VERSION:-알 수 없음}${NC}"
    echo -e "$MSG_STATUS_IMAGE_NAME: ${GREEN}${IMAGE_NAME}${NC}"
    echo -e "$MSG_STATUS_CONTAINER_NAME: ${GREEN}${CONTAINER_NAME}${NC}"

    # 호스트/사용자 설정 정보 섹션
    echo -e "\n${YELLOW}$MSG_STATUS_HOST_CONFIG:${NC}"
    echo -e "$MSG_STATUS_USERNAME: ${GREEN}${USERNAME}${NC}"
    echo -e "$MSG_STATUS_USER_UID: ${GREEN}${USER_UID}${NC}"
    echo -e "$MSG_STATUS_USER_GID: ${GREEN}${USER_GID}${NC}"
    echo -e "$MSG_STATUS_WORKDIR: ${GREEN}${WORKDIR}${NC}"

    # 컨테이너 사용자 정보 섹션 (항상 표시)
    echo -e "\n${YELLOW}$MSG_STATUS_CONTAINER_USER_INFO:${NC}"
    echo -e "$MSG_STATUS_CONTAINER_USERNAME: ${GREEN}${CONTAINER_USERNAME:-N/A}${NC}"
    echo -e "$MSG_STATUS_CONTAINER_USER_UID: ${GREEN}${CONTAINER_USER_UID:-N/A}${NC}"
    echo -e "$MSG_STATUS_CONTAINER_USER_GID: ${GREEN}${CONTAINER_USER_GID:-N/A}${NC}"
    
    # 컨테이너 상태 확인
    # Check container status
    if ! docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        log "SUCCESS" "$MSG_STATUS_COMPLETE"
        exit 0
    fi
    
    # 컨테이너 상태 출력
    # Display container status
    echo -e "\n${YELLOW}$MSG_CONTAINER_STATUS:${NC}"
    echo -e "$MSG_CONTAINER_NAME: ${GREEN}$CONTAINER_NAME${NC}"
    echo -e "$MSG_CONTAINER_ID: ${GREEN}$(docker container inspect -f '{{.Id}}' "$CONTAINER_NAME")${NC}"
    echo -e "$MSG_CONTAINER_STATE: ${GREEN}$(docker container inspect -f '{{.State.Status}}' "$CONTAINER_NAME")${NC}"
    echo -e "$MSG_CONTAINER_CREATED: ${GREEN}$(docker container inspect -f '{{.Created}}' "$CONTAINER_NAME")${NC}"
    echo -e "$MSG_CONTAINER_IMAGE: ${GREEN}$(docker container inspect -f '{{.Config.Image}}' "$CONTAINER_NAME")${NC}"
    
    # 컨테이너가 실행 중이면 추가 정보 출력
    # Display additional information if container is running
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
        # IP 주소 가져오기: 더 안정적인 방법으로 변경
        local container_ip
        container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_NAME" 2>/dev/null)
        if [ -z "$container_ip" ]; then
            container_ip=$(docker exec -i "$CONTAINER_NAME" hostname -i 2>/dev/null || echo "")
        fi
        echo -e "$MSG_CONTAINER_IP: ${GREEN}${container_ip:-N/A}${NC}"
        
        # 포트 정보 가져오기
        local port_info
        port_info=$(docker inspect -f '{{range $p, $conf := .NetworkSettings.Ports}}{{$p}} -> {{range $conf}}{{.HostIp}}:{{.HostPort}}{{end}}{{printf ", "}}{{end}}' "$CONTAINER_NAME" 2>/dev/null)
        
        # 포트 정보가 없으면 포트 매핑 없음 메시지 표시
        if [ -z "$port_info" ] || [ "$port_info" = ", " ] || [ "$port_info" = " -> , " ]; then
            echo -e "$MSG_CONTAINER_PORTS: ${GREEN}$MSG_NO_PORTS_MAPPED${NC}"
        else
            echo -e "$MSG_CONTAINER_PORTS: ${GREEN}$port_info${NC}"
        fi
    fi
    
    log "SUCCESS" "$MSG_STATUS_COMPLETE"
}

# 직접 실행 시
# When executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    status_main "$@"
fi 