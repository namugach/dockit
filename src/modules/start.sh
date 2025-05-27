#!/bin/bash

# Start module - Start Docker development environment
# start 모듈 - Docker 개발 환경 시작

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$MODULES_DIR/container_base.sh"

# 메시지 선언
MSG_NO_CONTAINERS="No containers found."



# "this" 인자 처리 (현재 프로젝트 컨테이너 시작)
# Handle "this" argument (start current project container)
handle_this_argument() {
    # -- 1) dockit 프로젝트 디렉터리 확인 ----------------
    if [[ ! -d .dockit_project ]]; then
        log "WARNING" "$MSG_START_NOT_PROJECT"
        return 1
    fi

    # -- 2) 시작 메시지 ----------------------------------
    log "INFO" "$MSG_START_START"

    # -- 3) docker-compose 파일 체크 ---------------------
    [[ -f $DOCKER_COMPOSE_FILE ]] || { log "ERROR" "$MSG_COMPOSE_NOT_FOUND"; return 1; }

    # -- 4) 환경 로드 ------------------------------------
    load_env

    # -- 5) 컨테이너 존재 여부 ----------------------------
    if ! container_exists "$CONTAINER_NAME"; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        
        # 컨테이너 생성 여부 확인
        echo -e "\n${YELLOW}$MSG_START_WANT_CREATE_CONTAINER${NC}"
        read -p "$MSG_SELECT_CHOICE [Y/n]: " create_container
        create_container=${create_container:-y}
        
        if [[ $create_container == "y" || $create_container == "Y" ]]; then
            log "INFO" "$MSG_START_CREATING_CONTAINER"
            
            # up 명령어 실행 (현재 프로젝트)
            if dockit up this; then
                log "SUCCESS" "$MSG_CONTAINER_STARTED"
                echo -e "\n${BLUE}$MSG_CONNECT_INFO${NC} dockit connect"
                return 0
            else
                log "ERROR" "$MSG_CONTAINER_START_FAILED"
                return 1
            fi
        else
            log "INFO" "$MSG_START_CREATE_CANCELLED"
            return 0
        fi
    fi

    # -- 6) 이미 실행 중인지 확인 ------------------------
    if is_container_running "$CONTAINER_NAME"; then
        log "WARNING" "$MSG_CONTAINER_ALREADY_RUNNING"
        return 3
    fi

    # -- 7) 실제 액션 수행 --------------------------------
    log "INFO" "$MSG_STARTING_CONTAINER"
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" start; then
        log "SUCCESS" "$MSG_CONTAINER_STARTED"
        
        # 레지스트리 상태 업데이트
        local project_id
        if project_id=$(get_current_project_id); then
            update_project_state "$project_id" "$PROJECT_STATE_RUNNING"
            log "INFO" "Project status updated to running"
        else
            log "WARNING" "Could not update project status - project ID not found"
        fi
        
        echo -e "\n${BLUE}$MSG_CONNECT_INFO${NC} dockit connect"
        return 0
    else
        log "ERROR" "$MSG_CONTAINER_START_FAILED"
        return 1
    fi
}

# 컨테이너 시작 함수
# Start container function
container_action() {
    local container_id="$1"
    local quiet="${2:-false}"  # 로그 출력 여부 (기본값: 출력함)
    
    # 컨테이너 존재 여부 확인
    # Check if container exists
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
    
    # 컨테이너 시작
    [ "$quiet" != "true" ] && log "INFO" "$(printf "$MSG_STARTING_CONTAINER" "$container_desc")"
    if docker start "$container_id"; then
        [ "$quiet" != "true" ] && log "SUCCESS" "$(printf "$MSG_CONTAINER_STARTED" "$container_desc")"
        return 0
    else
        [ "$quiet" != "true" ] && log "ERROR" "$(printf "$MSG_CONTAINER_START_FAILED" "$container_desc")"
        return 1
    fi
}

# 숫자 인자 처리 (번호로 컨테이너 시작)
# Handle numeric arguments (start container by number)
handle_numeric_arguments() {
    local -a indices=("$@")            # 숫자 인자들만

    # 인자 전부 숫자인지 확인
    for idx in "${indices[@]}"; do
        [[ "$idx" =~ ^[0-9]+$ ]] || { log "ERROR" "$(printf "$MSG_START_INVALID_NUMBER" "$idx")"; return 1; }
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
            log "ERROR" "$(printf "$MSG_START_INVALID_NUMBER" "$idx")"
            continue
        fi

        # 프로젝트 경로 가져오기
        local project_path=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
        local container_name=$(generate_container_name "$project_path")
        
        # 컨테이너 ID 찾기 (정확한 이름 매칭)
        local cid=$(docker ps -aq --filter "name=^${container_name}$" --filter "label=com.dockit=true" | head -1)
        
        if [[ -n "$cid" ]]; then
            # 컨테이너가 존재하는 경우
            local short=${cid:0:12}
            local name=$(get_container_info "$cid" "name")
            [[ -n "$name" ]] && short="$short ($name)"

            local spinner=$(printf "$MSG_CONTAINER_ACTION_FORMAT" "$short" "$MSG_SPINNER_STARTING")

            add_task "$spinner" \
                "container_action '$cid' true >/dev/null 2>&1 && update_project_state '$project_id' '$PROJECT_STATE_RUNNING'"
        else
            # 컨테이너가 없는 경우 - up 명령어 실행 여부 확인
            local project_name=$(basename "$project_path")
            log "WARNING" "Container not found for project: $project_name"
            
            # 컨테이너 생성 여부 확인
            echo -e "\n${YELLOW}$MSG_START_WANT_CREATE_CONTAINER${NC}"
            read -p "$MSG_SELECT_CHOICE [Y/n]: " create_container
            create_container=${create_container:-y}
            
            if [[ $create_container == "y" || $create_container == "Y" ]]; then
                log "INFO" "$MSG_START_CREATING_CONTAINER"
                
                # 해당 프로젝트 디렉토리로 이동하여 up 실행
                local current_dir=$(pwd)
                cd "$project_path"
                if dockit up this; then
                    log "SUCCESS" "$(printf "$MSG_CONTAINER_STARTED" "$project_name")"
                    # 컨테이너가 생성되었으므로 다시 컨테이너 ID 찾기
                    local new_cid=$(docker ps -aq --filter "name=^${container_name}$" --filter "label=com.dockit=true" | head -1)
                    if [[ -n "$new_cid" ]]; then
                        update_project_state "$project_id" "$PROJECT_STATE_RUNNING"
                    fi
                else
                    log "ERROR" "$(printf "$MSG_CONTAINER_START_FAILED" "$project_name")"
                fi
                cd "$current_dir"
            else
                log "INFO" "$MSG_START_CREATE_CANCELLED"
            fi
        fi
    done

    async_tasks "$MSG_TASKS_DONE"
}


# Main function
# 메인 함수
start_main() {
    # Docker 사용 가능 여부 확인
    if ! command -v docker &> /dev/null; then
        log "ERROR" "$MSG_COMMON_DOCKER_NOT_FOUND"
        return 1
    fi

    # 인자가 없는 경우 컨테이너 목록 표시
    # If no arguments, show container list
    if [ $# -eq 0 ]; then
        show_usage "$@"
        return 0
    fi
    
    # 첫 번째 인자에 따른 처리
    case "$1" in
        "this")
            # this 인자 처리
            handle_this_argument
            ;;
        "all")
            # all 인자 처리 - 레지스트리 상태 업데이트 포함
            log "INFO" "$MSG_START_ALL"
            
            # 모든 dockit 컨테이너 가져오기
            mapfile -t cids < <(docker ps -a --filter label=com.dockit=true --format '{{.ID}}')
            
            if [[ ${#cids[@]} -eq 0 ]]; then
                log "INFO" "$MSG_NO_CONTAINERS"
                return 0
            fi
            
            # 각 컨테이너에 대해 시작 작업 및 레지스트리 업데이트
            for cid in "${cids[@]}"; do
                local short=${cid:0:12}
                local name=$(get_container_info "$cid" "name")
                [[ -n "$name" ]] && short="$short ($name)"
                
                local spinner=$(printf "$MSG_CONTAINER_ACTION_FORMAT" "$short" "$MSG_SPINNER_STARTING")
                
                # 컨테이너에서 프로젝트 ID 찾기
                local project_id=$(find_project_info_by_container "$cid")
                
                if [[ -n "$project_id" ]]; then
                    add_task "$spinner" \
                        "container_action '$cid' true >/dev/null 2>&1 && update_project_state '$project_id' '$PROJECT_STATE_RUNNING'"
                else
                    add_task "$spinner" \
                        "container_action '$cid' true >/dev/null 2>&1"
                fi
            done
            
            async_tasks "$MSG_TASKS_DONE"
            ;;
        *)
            # 숫자 인자 처리 시도
            if handle_numeric_arguments "$@"; then
                return 0
            else
                # 잘못된 인자 처리
                log "ERROR" "$MSG_START_INVALID_ARGS"
                show_usage
            fi
            ;;
    esac
    
    return 0
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start_main "$@"
fi 