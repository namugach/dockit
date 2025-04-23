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

# 컨테이너 이름 확인 및 설정 함수
# Container name check and setup function
ensure_container_name() {
    # 컨테이너 이름이 비어 있는지 확인
    if [ -z "$CONTAINER_NAME" ] && [ -f "$CONFIG_ENV" ]; then
        log "WARNING" "$MSG_CONTAINER_NAME_NOT_SET"
        # 설정 파일에서 직접 CONTAINER_NAME 값 읽기
        CONTAINER_NAME=$(grep -E "^CONTAINER_NAME=" "$CONFIG_ENV" | cut -d'"' -f2)
        log "INFO" "$(printf "$MSG_LOADED_CONTAINER_NAME" "$CONTAINER_NAME")"
    fi
    
    # 컨테이너 이름이 여전히 비어있으면 오류
    if [ -z "$CONTAINER_NAME" ]; then
        log "ERROR" "$MSG_CONTAINER_NAME_EMPTY"
        return 1
    fi
    
    log "INFO" "$(printf "$MSG_UPDATING_CONTAINER_USER_INFO" "$CONTAINER_NAME")"
    return 0
}

# 컨테이너 실행 상태 확인 함수
# Container running state check function
check_container_running() {
    local container_name="$1"
    
    # 컨테이너 상태를 docker ps로 간단히 확인
    if ! docker ps --quiet --filter "name=$container_name" | grep -q .; then
        log "WARNING" "$(printf "$MSG_CONTAINER_NOT_RUNNING_NAMED" "$container_name")"
        return 1
    fi
    
    log "INFO" "$(printf "$MSG_CONTAINER_IS_RUNNING" "$container_name") $MSG_WAITING_BRIEFLY"
    # 컨테이너가 완전히 초기화될 시간을 주기 위해 지연
    sleep 3
    return 0
}

# 컨테이너에서 사용자 정보 가져오기 함수
# Get user info from container function
get_container_user_info() {
    local container_name="$1"
    local -n username_ref="$2"
    local -n uid_ref="$3"
    local -n gid_ref="$4"
    
    # 컨테이너 내부에서 사용자 정보 가져오기
    log "INFO" "$MSG_GETTING_USER_INFO_FROM_CONTAINER"
    
    # 사용자 이름 가져오기
    username_ref=$(docker exec -i "$container_name" whoami 2>/dev/null || echo "unknown")
    if [ "$?" -ne 0 ] || [ -z "$username_ref" ] || [ "$username_ref" = "unknown" ]; then
        log "WARNING" "$(printf "$MSG_WHOAMI_COMMAND_FAILED" "$username_ref")"
        # 더 오래 기다려보고 다시 시도
        sleep 3
        username_ref=$(docker exec -i "$container_name" whoami 2>/dev/null || echo "unknown")
        log "INFO" "$(printf "$MSG_RETRY_RESULT" "$username_ref")"
    fi
    
    # UID와 GID 가져오기
    uid_ref=$(docker exec -i "$container_name" id -u 2>/dev/null || echo "unknown")
    gid_ref=$(docker exec -i "$container_name" id -g 2>/dev/null || echo "unknown")
    
    log "INFO" "$(printf "$MSG_RETRIEVED_CONTAINER_USER_INFO" "$username_ref" "$uid_ref" "$gid_ref")"
    
    # 정보를 가져오지 못한 경우 처리
    if [ "$username_ref" = "unknown" ] || [ -z "$username_ref" ]; then
        log "WARNING" "$MSG_FAILED_TO_GET_USER_INFO"
        return 1
    fi
    
    return 0
}

# 설정 파일에 컨테이너 사용자 정보 저장 함수
# Save container user info to config file function
save_user_info_to_config() {
    local config_file="$1"
    local username="$2"
    local uid="$3"
    local gid="$4"
    
    # .env 파일 업데이트
    log "INFO" "$MSG_UPDATING_CONFIG_FILE"
    
    # 설정 파일 존재 확인 및 업데이트 실행
    if [ -f "$config_file" ]; then
        update_container_user_in_config "$config_file" "$username" "$uid" "$gid"
        log "SUCCESS" "$MSG_CONTAINER_USER_INFO_UPDATED"
        log "INFO" "$(printf "$MSG_UPDATED_INFO" "$username" "$uid" "$gid")"
        return 0
    else
        log "ERROR" "$(printf "$MSG_CONFIG_FILE_NOT_FOUND" "$config_file")"
        return 1
    fi
}

# 컨테이너 사용자 정보 업데이트 함수
# Update container user information function
update_container_user_info() {
    # 1. 컨테이너 이름 확인
    if ! ensure_container_name; then
        return 1
    fi
    
    # 2. 컨테이너 실행 상태 확인
    if ! check_container_running "$CONTAINER_NAME"; then
        return 1
    fi
    
    # 3. 컨테이너에서 사용자 정보 가져오기
    local username uid gid
    if ! get_container_user_info "$CONTAINER_NAME" username uid gid; then
        return 1
    fi
    
    # 4. 설정 파일에 사용자 정보 저장
    if ! save_user_info_to_config "$CONFIG_ENV" "$username" "$uid" "$gid"; then
        return 1
    fi
    
    return 0
}

# 설정 로드 및 기본 검증 함수
# Load configuration and basic validation function
load_and_validate_config() {
    # 설정 로드
    load_env
    
    # 중요 변수 확인 및 디버깅
    if [ -z "$CONFIG_ENV" ]; then
        log "ERROR" "$MSG_CONFIG_ENV_NOT_SET"
        return 1
    fi
    
    # 컨테이너 이름 확인
    if [ -z "$CONTAINER_NAME" ]; then
        log "WARNING" "$MSG_CONTAINER_NAME_EMPTY_CHECKING"
        if [ -f "$CONFIG_ENV" ]; then
            CONTAINER_NAME=$(grep -E "^CONTAINER_NAME=" "$CONFIG_ENV" | cut -d'"' -f2)
            log "INFO" "$(printf "$MSG_LOADED_CONTAINER_NAME" "$CONTAINER_NAME")"
        fi
    else
        log "INFO" "$(printf "$MSG_CONTAINER_NAME" "$CONTAINER_NAME")"
    fi
    
    # Docker Compose 파일 확인
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
        return 1
    fi
    
    # 디버깅: 사용할 Docker Compose 파일 표시
    log "INFO" "$(printf "$MSG_USING_COMPOSE_FILE" "$DOCKER_COMPOSE_FILE")"
    
    return 0
}

# 컨테이너가 이미 실행 중인지 확인하는 함수
# Check if container is already running function
is_container_already_running() {
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
            log "WARNING" "$MSG_CONTAINER_ALREADY_RUNNING"
            return 0  # 이미 실행 중
        fi
    fi
    return 1  # 실행 중이지 않음
}

# 컨테이너 시작 함수
# Start container function
start_container() {
    # 컨테이너를 백그라운드에서 시작
    log "INFO" "$MSG_STARTING_IN_BACKGROUND"
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d; then
        log "SUCCESS" "$MSG_CONTAINER_STARTED"
        log "INFO" "$MSG_CONTAINER_RUNNING_BACKGROUND"
        return 0
    else
        log "ERROR" "$MSG_CONTAINER_START_FAILED"
        log "INFO" "$MSG_CHECK_DOCKER"
        log "INFO" "$MSG_CHECK_PORTS"
        log "INFO" "$MSG_CHECK_IMAGE"
        return 1
    fi
}

# 컨테이너 상태 출력 함수
# Display container status function
display_container_status() {
    log "INFO" "$(printf "$MSG_CONTAINER_INFO" "$CONTAINER_NAME")"
    docker ps --filter "name=$CONTAINER_NAME" --format "table {{.ID}}\t{{.Status}}\t{{.Ports}}"
}

# Main function
# 메인 함수
up_main() {
    log "INFO" "$MSG_UP_START"
    
    # 1. 설정 로드 및 기본 검증
    if ! load_and_validate_config; then
        exit 1
    fi
    
    # 2. 컨테이너가 이미 실행 중인지 확인
    if is_container_already_running; then
        # 컨테이너가 이미 실행 중이더라도 사용자 정보 업데이트
        update_container_user_info
        exit 0
    fi
    
    # 3. 컨테이너 시작
    if ! start_container; then
        exit 1
    fi
    
    # 4. 컨테이너 사용자 정보 업데이트
    update_container_user_info
    
    # 5. 컨테이너 상태 출력
    display_container_status
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    up_main "$@"
fi 