#!/bin/bash

# Up module - Start Docker development environment in background
# up 모듈 - Docker 개발 환경을 백그라운드에서 시작

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 설정 파일에 컨테이너 사용자 정보 업데이트 함수
update_container_user_in_config() {
    local config_file="$1"
    local username="$2"
    local uid="$3"
    local gid="$4"
    
    # 기존 값 백업 및 업데이트
    sed -i.bak \
        -e "s/^CONTAINER_USERNAME=.*$/CONTAINER_USERNAME=\"$username\"/" \
        -e "s/^CONTAINER_USER_UID=.*$/CONTAINER_USER_UID=\"$uid\"/" \
        -e "s/^CONTAINER_USER_GID=.*$/CONTAINER_USER_GID=\"$gid\"/" \
        "$config_file"
    
    # 변경되지 않은 값이 있으면 새 값 추가
    if ! grep -q "^CONTAINER_USERNAME=" "$config_file"; then
        echo "CONTAINER_USERNAME=\"$username\"" >> "$config_file"
    fi
    if ! grep -q "^CONTAINER_USER_UID=" "$config_file"; then
        echo "CONTAINER_USER_UID=\"$uid\"" >> "$config_file"
    fi
    if ! grep -q "^CONTAINER_USER_GID=" "$config_file"; then
        echo "CONTAINER_USER_GID=\"$gid\"" >> "$config_file"
    fi
    
    return 0
}

# 컨테이너 사용자 정보 업데이트 함수
# Update container user information function
update_container_user_info() {
    # 컨테이너가 실행 중인지 확인
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)" != "true" ]; then
        log "WARNING" "$MSG_CONTAINER_NOT_RUNNING"
        return 1
    fi
    
    log "INFO" "컨테이너 사용자 정보 업데이트 중..."
    
    # 컨테이너 내부에서 사용자 정보 가져오기
    CONTAINER_USERNAME=$(docker exec -i "$CONTAINER_NAME" whoami 2>/dev/null || echo "unknown")
    CONTAINER_USER_UID=$(docker exec -i "$CONTAINER_NAME" id -u 2>/dev/null || echo "unknown")
    CONTAINER_USER_GID=$(docker exec -i "$CONTAINER_NAME" id -g 2>/dev/null || echo "unknown")
    
    # .env 파일 업데이트
    log "INFO" "설정 파일 업데이트 중..."
    

    
    # 설정 파일 존재 확인 및 업데이트 실행
    if [ -f "$CONFIG_ENV" ]; then
        update_container_user_in_config "$CONFIG_ENV" "$CONTAINER_USERNAME" "$CONTAINER_USER_UID" "$CONTAINER_USER_GID"
        log "SUCCESS" "컨테이너 사용자 정보가 업데이트되었습니다."
    else
        log "ERROR" "설정 파일을 찾을 수 없습니다."
        return 1
    fi
}

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
            # 컨테이너가 이미 실행 중이더라도 사용자 정보 업데이트
            update_container_user_info
            exit 0
        fi
    fi
    
    # Start container in background
    # 컨테이너를 백그라운드에서 시작
    log "INFO" "$MSG_STARTING_IN_BACKGROUND"
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d; then
        log "SUCCESS" "$MSG_CONTAINER_STARTED"
        log "INFO" "$MSG_CONTAINER_RUNNING_BACKGROUND"
        
        # 컨테이너 사용자 정보 업데이트
        update_container_user_info
        
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