#!/bin/bash

# Up module - Start Docker development environment in background
# up 모듈 - Docker 개발 환경을 백그라운드에서 시작

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$MODULES_DIR/container_base.sh"


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
    
    log "INFO" "$(printf "$MSG_CONTAINER_NAME_WITH_FORMAT" "$CONTAINER_NAME")"
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
    log "INFO" "$(printf "$MSG_UPDATING_CONTAINER_USER_INFO" "$CONTAINER_NAME")"
    
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
        log "INFO" "$(printf "$MSG_CONTAINER_NAME_WITH_FORMAT" "$CONTAINER_NAME")"
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
    # 이미지 존재 여부 확인
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        log "WARNING" "이미지를 찾을 수 없습니다: $IMAGE_NAME"
        
        # 자동 모드 또는 사용자 확인
        local build_image
        if [[ "$DOCKIT_AUTO_MODE" == "true" ]]; then
            # 자동 모드일 때는 자동으로 빌드
            build_image="y"
            log "INFO" "Auto mode: Building image automatically..."
        else
            echo -e "\n${YELLOW}이미지를 빌드하시겠습니까?${NC}"
            read -p "선택 [Y/n]: " build_image
            build_image=${build_image:-y}
        fi
        
        if [[ $build_image == "y" || $build_image == "Y" ]]; then
            log "INFO" "이미지를 빌드하는 중..."
            
            # build 모듈 로드 및 빌드 실행
            source "$MODULES_DIR/build.sh"
            if ! build_main "this"; then
                log "ERROR" "이미지 빌드에 실패했습니다"
                return 1
            fi
        else
            log "INFO" "이미지 빌드를 취소했습니다"
            return 1
        fi
    fi
    
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

# 사용법 표시 함수
# Show usage function
show_usage() {
    log "INFO" "$MSG_UP_USAGE"
    echo -e "  dockit up <no> - $MSG_UP_USAGE_NO"
    echo -e "  dockit up this - $MSG_UP_USAGE_THIS"
    echo -e "  dockit up all - $MSG_UP_USAGE_ALL"
    echo ""
}

# "this" 인자 처리 (현재 프로젝트 컨테이너를 백그라운드에서 시작)
# Handle "this" argument (start current project container in background)
handle_this_argument() {
    # -- 1) dockit 프로젝트 디렉터리 확인 ----------------
    if [[ ! -d .dockit_project ]]; then
        log "WARNING" "$MSG_UP_NOT_PROJECT"
        return 1
    fi

    log "INFO" "$MSG_UP_START"
    
    # 1. 설정 로드 및 기본 검증
    if ! load_and_validate_config; then
        return 1
    fi
    
    # 2. 컨테이너가 이미 실행 중인지 확인
    if is_container_already_running; then
        # 컨테이너가 이미 실행 중이더라도 사용자 정보 업데이트
        update_container_user_info
        
        # 레지스트리 상태 업데이트 (이미 실행 중인 경우)
        local project_id
        if project_id=$(get_current_project_id); then
            update_project_state "$project_id" "$PROJECT_STATE_RUNNING"
        fi
        return 0
    fi
    
    # 3. 컨테이너 시작
    if ! start_container; then
        return 1
    fi
    
    # 4. 컨테이너 사용자 정보 업데이트
    update_container_user_info
    
    # 5. 레지스트리 상태 업데이트 (성공적으로 시작된 경우)
    local project_id
    if project_id=$(get_current_project_id); then
        update_project_state "$project_id" "$PROJECT_STATE_RUNNING"
        log "INFO" "Project status updated to running"
    else
        log "WARNING" "Could not update project status - project ID not found"
    fi
    
    # 6. 컨테이너 상태 출력
    display_container_status
    
    return 0
}

# 컨테이너 up 액션 함수 (백그라운드에서 시작)
# Container up action function (start in background)
container_up_action() {
    local container_id="$1"
    local quiet="${2:-false}"  # 로그 출력 여부 (기본값: 출력함)
    
    # 컨테이너 존재 여부 확인
    if ! container_exists "$container_id"; then
        [ "$quiet" != "true" ] && log "ERROR" "$MSG_CONTAINER_NOT_FOUND"
        return 1
    fi
    
    # 컨테이너 정보 가져오기
    local container_desc=$(get_container_description "$container_id")
    
    # 이미 실행 중인지 확인
    if is_container_running "$container_id"; then
        [ "$quiet" != "true" ] && log "WARNING" "$(printf "$MSG_CONTAINER_ALREADY_RUNNING" "$container_desc")"
        return 0
    fi
    
    # 컨테이너 시작 (백그라운드)
    [ "$quiet" != "true" ] && log "INFO" "$(printf "$MSG_STARTING_IN_BACKGROUND" "$container_desc")"
    if docker start "$container_id"; then
        [ "$quiet" != "true" ] && log "SUCCESS" "$(printf "$MSG_CONTAINER_STARTED" "$container_desc")"
        return 0
    else
        [ "$quiet" != "true" ] && log "ERROR" "$(printf "$MSG_CONTAINER_START_FAILED" "$container_desc")"
        return 1
    fi
}

# 숫자 인자 처리 (번호로 컨테이너를 백그라운드에서 시작)
# Handle numeric arguments (start container by number in background)
handle_numeric_arguments() {
    local -a indices=("$@")            # 숫자 인자들만

    # 인자 전부 숫자인지 확인
    for idx in "${indices[@]}"; do
        [[ "$idx" =~ ^[0-9]+$ ]] || { log "ERROR" "$(printf "$MSG_UP_INVALID_NUMBER" "$idx")"; return 1; }
    done

    # 레지스트리에서 프로젝트 목록 가져오기
    local registry_file="$HOME/.dockit/registry.json"
    if [ ! -f "$registry_file" ]; then
        log "ERROR" "Registry file not found"
        return 1
    fi
    
    local registry_json=$(cat "$registry_file")
    local project_ids=()
    
    # 프로젝트 ID 배열 생성
    while IFS= read -r project_id; do
        project_ids+=("$project_id")
    done < <(echo "$registry_json" | jq -r 'keys[]')

    # 각 인덱스 처리
    for idx in "${indices[@]}"; do
        local array_idx=$((idx-1))                # 인덱스 → 배열 위치
        local project_id=${project_ids[$array_idx]:-}

        if [[ -z "$project_id" ]]; then
            log "ERROR" "$(printf "$MSG_UP_INVALID_NUMBER" "$idx")"
            continue
        fi

        # 프로젝트 경로 가져오기
        local project_path=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
        local project_name=$(basename "$project_path")
        
        # 프로젝트 경로 유효성 확인
        if [ ! -d "$project_path" ] || [ ! -f "$project_path/.dockit_project/docker-compose.yml" ]; then
            log "ERROR" "Project $idx ($project_name) not found or invalid"
            continue
        fi
        
        local spinner="Project $idx ($project_name) $MSG_SPINNER_UPPING"
        
        # 프로젝트별 up 작업을 백그라운드에서 실행
        add_task "$spinner" \
            "project_up_action '$project_path' '$project_id' >/dev/null 2>&1"
    done

    async_tasks "$MSG_TASKS_DONE"
}

# 프로젝트별 up 액션 함수
# Project-specific up action function
project_up_action() {
    local project_path="$1"
    local project_id="$2"
    
    # 프로젝트 디렉토리로 이동
    cd "$project_path" || return 1
    
    # 설정 로드
    if [ -f ".dockit_project/.env" ]; then
        source ".dockit_project/.env"
    else
        return 1
    fi
    
    # Docker Compose 파일 확인
    local compose_file=".dockit_project/docker-compose.yml"
    if [ ! -f "$compose_file" ]; then
        return 1
    fi
    
    # 컨테이너가 이미 실행 중인지 확인
    if [ -n "$CONTAINER_NAME" ] && docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
            # 이미 실행 중인 경우 레지스트리 상태만 업데이트
            update_project_state "$project_id" "$PROJECT_STATE_RUNNING"
            return 0
        fi
    fi
    
    # 이미지 존재 여부 확인
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        # 이미지가 없는 경우 빌드 실행 (백그라운드 작업에서는 자동으로 빌드)
        # build 모듈 로드 및 빌드 실행
        source "$MODULES_DIR/build.sh"
        if ! build_main "this" >/dev/null 2>&1; then
            # 빌드 실패 시 상태 업데이트
            update_project_state "$project_id" "$PROJECT_STATE_ERROR"
            return 1
        fi
    fi
    
    # Docker Compose로 컨테이너 시작
    if docker compose -f "$compose_file" up -d; then
        # 성공 시 레지스트리 상태 업데이트
        update_project_state "$project_id" "$PROJECT_STATE_RUNNING"
        return 0
    else
        return 1
    fi
}

# "all" 인자 처리 (모든 프로젝트를 백그라운드에서 시작)
# Handle "all" argument (start all projects in background)
handle_all_argument() {
    log "INFO" "$MSG_UP_ALL"
    
    # 레지스트리에서 모든 프로젝트 가져오기
    local registry_file="$HOME/.dockit/registry.json"
    if [ ! -f "$registry_file" ]; then
        log "ERROR" "Registry file not found"
        return 1
    fi
    
    local registry_json=$(cat "$registry_file")
    local project_ids=()
    
    # 프로젝트 ID 배열 생성
    while IFS= read -r project_id; do
        project_ids+=("$project_id")
    done < <(echo "$registry_json" | jq -r 'keys[]')

    if [[ ${#project_ids[@]} -eq 0 ]]; then
        log "INFO" "$MSG_NO_CONTAINERS"
        return 0
    fi

    # 각 프로젝트에 대해 up 작업
    for project_id in "${project_ids[@]}"; do
        # 프로젝트 경로 가져오기
        local project_path=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
        local project_name=$(basename "$project_path")
        
        # 프로젝트 경로 유효성 확인
        if [ ! -d "$project_path" ] || [ ! -f "$project_path/.dockit_project/docker-compose.yml" ]; then
            log "WARNING" "Project $project_name not found or invalid, skipping..."
            continue
        fi
        
        local spinner="Project $project_name $MSG_SPINNER_UPPING"
        
        add_task "$spinner" \
            "project_up_action '$project_path' '$project_id' >/dev/null 2>&1"
    done

    async_tasks "$MSG_TASKS_DONE"
}

# Main function
# 메인 함수
up_main() {
    # Docker 사용 가능 여부 확인
    if ! command -v docker &> /dev/null; then
        log "ERROR" "$MSG_COMMON_DOCKER_NOT_FOUND"
        return 1
    fi

    # 인자가 없는 경우 사용법 표시
    if [ $# -eq 0 ]; then
        show_usage
        return 0
    fi
    
    # 첫 번째 인자에 따른 처리
    case "$1" in
        "this")
            # this 인자 처리
            handle_this_argument
            ;;
        "all")
            # all 인자 처리
            handle_all_argument
            ;;
        *)
            # 숫자 인자 처리 시도
            if handle_numeric_arguments "$@"; then
                return 0
            else
                # 잘못된 인자 처리
                log "ERROR" "$MSG_UP_INVALID_ARGS"
                show_usage
            fi
            ;;
    esac
    
    return 0
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    up_main "$@"
fi 