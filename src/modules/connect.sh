#!/bin/bash

# connect 모듈 - Docker 개발 환경 접속
# connect module - Connect to Docker development environment

# 공통 모듈 로드
# Load common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$MODULES_DIR/container_base.sh"

# 사용법 표시 함수
# Show usage function
show_usage() {
    log "INFO" "$MSG_CONNECT_USAGE"
    echo -e "  dockit connect <no> - $MSG_CONNECT_USAGE_NO"
    echo -e "  dockit connect this - $MSG_CONNECT_USAGE_THIS"
    echo ""
}

# "this" 인자 처리 (현재 프로젝트 컨테이너에 접속)
# Handle "this" argument (connect to current project container)
handle_this_argument() {
    # -- 1) dockit 프로젝트 디렉터리 확인 ----------------
    if [[ ! -d .dockit_project ]]; then
        log "WARNING" "$MSG_CONNECT_NOT_PROJECT"
        return 1
    fi

    log "INFO" "$MSG_CONNECT_START"
    
    # 설정 로드
    # Load configuration
    load_env
    
    # Docker Compose 파일이 있는지 확인
    # Check if Docker Compose file exists
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
        return 1
    fi
    
    # 컨테이너 존재 여부 확인
    # Check if container exists
    if ! docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        
        # 컨테이너 생성 및 시작 여부 확인
        echo -e "\n${YELLOW}$MSG_CONNECT_WANT_CREATE_AND_START${NC}"
        read -p "$MSG_SELECT_CHOICE [Y/n]: " create_and_start
        create_and_start=${create_and_start:-y}
        
        if [[ $create_and_start == "y" || $create_and_start == "Y" ]]; then
            log "INFO" "$MSG_CONNECT_CREATING_AND_STARTING"
            
            # up 명령어 실행 (컨테이너 생성 및 시작)
            if dockit up this; then
                log "SUCCESS" "$MSG_CONTAINER_STARTED"
                
                # 레지스트리 상태 업데이트
                local project_id
                if project_id=$(get_current_project_id); then
                    update_project_state "$project_id" "$PROJECT_STATE_RUNNING"
                    log "INFO" "Project status updated to running"
                fi
            else
                log "ERROR" "$MSG_CONTAINER_START_FAILED"
                return 1
            fi
        else
            log "INFO" "$MSG_CONNECT_CREATE_START_CANCELLED"
            return 0
        fi
    fi
    
    # 컨테이너가 실행 중인지 확인
    # Check if container is running
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" != "true" ]; then
        log "WARNING" "$MSG_CONTAINER_NOT_RUNNING"
        
        # 컨테이너 시작 여부 확인
        # Ask if container should be started
        echo -e "\n${YELLOW}$MSG_CONNECT_WANT_START${NC}"
        read -p "$MSG_SELECT_CHOICE [Y/n]: " start_container
        start_container=${start_container:-y}
        
        if [[ $start_container == "y" || $start_container == "Y" ]]; then
            log "INFO" "$MSG_CONNECT_STARTING"
            
            # 컨테이너 시작
            # Start container
            if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" start; then
                log "SUCCESS" "$MSG_CONTAINER_STARTED"
                
                # 레지스트리 상태 업데이트
                local project_id
                if project_id=$(get_current_project_id); then
                    update_project_state "$project_id" "$PROJECT_STATE_RUNNING"
                    log "INFO" "Project status updated to running"
                fi
            else
                log "ERROR" "$MSG_CONTAINER_START_FAILED"
                return 1
            fi
        else
            log "INFO" "$MSG_CONNECT_CREATE_START_CANCELLED"
            return 0
        fi
    fi
    
    # 컨테이너 접속
    # Connect to container
    log "INFO" "$MSG_CONNECTING_CONTAINER"
    log "SUCCESS" "$MSG_CONNECTED"
    
    # 컨테이너에 접속 (exit code 무시)
    docker exec -it "$CONTAINER_NAME" /bin/bash || true
}

# 숫자 인자 처리 (번호로 컨테이너에 접속)
# Handle numeric arguments (connect to container by number)
handle_numeric_arguments() {
    local -a indices=("$@")            # 숫자 인자들

    # 복수 번호 처리 - 첫 번째만 사용하고 경고
    if [ ${#indices[@]} -gt 1 ]; then
        log "WARNING" "$MSG_CONNECT_MULTIPLE_WARNING"
        log "INFO" "$(printf "$MSG_CONNECT_USING_FIRST" "${indices[0]}")"
        indices=("${indices[0]}")  # 첫 번째만 유지
    fi

    local idx="${indices[0]}"
    
    # 인자가 숫자인지 확인
    [[ "$idx" =~ ^[0-9]+$ ]] || { log "ERROR" "$(printf "$MSG_CONNECT_INVALID_NUMBER" "$idx")"; return 1; }

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

    local array_idx=$((idx-1))                # 인덱스 → 배열 위치
    local project_id=${project_ids[$array_idx]:-}

    if [[ -z "$project_id" ]]; then
        log "ERROR" "$(printf "$MSG_CONNECT_INVALID_NUMBER" "$idx")"
        return 1
    fi

    # 프로젝트 경로 가져오기
    local project_path=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
    local project_name=$(basename "$project_path")
    
    # 프로젝트 경로 유효성 확인
    if [ ! -d "$project_path" ] || [ ! -f "$project_path/.dockit_project/docker-compose.yml" ]; then
        log "ERROR" "Project $idx ($project_name) not found or invalid"
        return 1
    fi
    
    # 프로젝트 디렉토리로 이동하여 접속
    log "INFO" "Connecting to project $idx ($project_name)..."
    
    # 프로젝트의 설정 파일에서 컨테이너 이름 가져오기
    local env_file="$project_path/.dockit_project/.env"
    if [ ! -f "$env_file" ]; then
        log "ERROR" "Project configuration not found: $env_file"
        return 1
    fi
    
    # 컨테이너 이름 추출
    local container_name=$(grep "^CONTAINER_NAME=" "$env_file" | cut -d'=' -f2 | tr -d '"')
    if [ -z "$container_name" ]; then
        log "ERROR" "Container name not found in project configuration"
        return 1
    fi
    
    # 컨테이너 존재 여부 확인
    if ! docker container inspect "$container_name" &>/dev/null; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        
        # 컨테이너 생성 및 시작 여부 확인
        echo -e "\n${YELLOW}$MSG_CONNECT_WANT_CREATE_AND_START${NC}"
        read -p "$MSG_SELECT_CHOICE [Y/n]: " create_and_start
        create_and_start=${create_and_start:-y}
        
        if [[ $create_and_start == "y" || $create_and_start == "Y" ]]; then
            log "INFO" "$MSG_CONNECT_CREATING_AND_STARTING"
            
            # 해당 프로젝트 디렉토리로 이동하여 up 실행
            local current_dir=$(pwd)
            cd "$project_path"
            if dockit up this; then
                log "SUCCESS" "$MSG_CONTAINER_STARTED"
                
                # 레지스트리 상태 업데이트
                update_project_state "$project_id" "$PROJECT_STATE_RUNNING"
                log "INFO" "Project status updated to running"
                
                cd "$current_dir"
            else
                log "ERROR" "$MSG_CONTAINER_START_FAILED"
                cd "$current_dir"
                return 1
            fi
        else
            log "INFO" "$MSG_CONNECT_CREATE_START_CANCELLED"
            return 0
        fi
    fi
    
    # 컨테이너가 실행 중인지 확인
    if [ "$(docker container inspect -f '{{.State.Running}}' "$container_name")" != "true" ]; then
        log "WARNING" "$MSG_CONTAINER_NOT_RUNNING"
        
        # 컨테이너 시작 여부 확인
        echo -e "\n${YELLOW}$MSG_CONNECT_WANT_START${NC}"
        read -p "$MSG_SELECT_CHOICE [Y/n]: " start_container
        start_container=${start_container:-y}
        
        if [[ $start_container == "y" || $start_container == "Y" ]]; then
            log "INFO" "$MSG_CONNECT_STARTING"
            
            # 컨테이너 시작 (docker compose 사용)
            local compose_file="$project_path/.dockit_project/docker-compose.yml"
            if [ -f "$compose_file" ]; then
                if docker compose -f "$compose_file" start; then
                    log "SUCCESS" "$MSG_CONTAINER_STARTED"
                    
                    # 레지스트리 상태 업데이트
                    update_project_state "$project_id" "$PROJECT_STATE_RUNNING"
                    log "INFO" "Project status updated to running"
                else
                    log "ERROR" "$MSG_CONTAINER_START_FAILED"
                    return 1
                fi
            else
                log "ERROR" "Docker Compose file not found: $compose_file"
                return 1
            fi
        else
            log "INFO" "$MSG_CONNECT_CREATE_START_CANCELLED"
            return 0
        fi
    fi
    
    # 컨테이너 접속
    log "INFO" "$MSG_CONNECTING_CONTAINER"
    log "SUCCESS" "$MSG_CONNECTED"
    
    # 컨테이너에 접속 (exit code 무시)
    docker exec -it "$container_name" /bin/bash || true
}

# 메인 함수
# Main function
connect_main() {
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
        *)
            # 숫자 인자 처리 시도
            if handle_numeric_arguments "$@"; then
                return 0
            else
                # 잘못된 인자 처리
                log "ERROR" "$MSG_CONNECT_INVALID_ARGS"
                show_usage
                return 1
            fi
            ;;
    esac
    
    return 0
}

# 직접 실행 시
# When executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    connect_main "$@"
fi 