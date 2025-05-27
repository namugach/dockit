#!/bin/bash

# down 모듈 - Docker 개발 환경 종료
# down module - Terminate Docker development environment

# 공통 모듈 로드
# Load common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$MODULES_DIR/container_base.sh"

# 사용법 표시 함수
# Show usage function
show_usage() {
    log "INFO" "$MSG_DOWN_USAGE"
    echo -e "  dockit down <no> - $MSG_DOWN_USAGE_NO"
    echo -e "  dockit down this - $MSG_DOWN_USAGE_THIS"
    echo -e "  dockit down all - $MSG_DOWN_USAGE_ALL"
    echo ""
}

# "this" 인자 처리 (현재 프로젝트 컨테이너 제거)
# Handle "this" argument (remove current project container)
handle_this_argument() {
    # -- 1) dockit 프로젝트 디렉터리 확인 ----------------
    if [[ ! -d .dockit_project ]]; then
        log "WARNING" "$MSG_DOWN_NOT_PROJECT"
        return 1
    fi

    log "INFO" "$MSG_DOWN_START"
    
    # Docker Compose 파일이 있는지 확인
    # Check if Docker Compose file exists
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
        return 1
    fi
    
    # 환경 로드
    load_env
    
    # 컨테이너 중지 및 제거
    # Stop and remove container
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" down; then
        log "SUCCESS" "$MSG_CONTAINER_DOWN"
        
        # 레지스트리 상태 업데이트
        local project_id
        if project_id=$(get_current_project_id); then
            update_project_state "$project_id" "$PROJECT_STATE_DOWN"
            log "INFO" "Project status updated to stopped"
        else
            log "WARNING" "Could not update project status - project ID not found"
        fi
        return 0
    else
        log "ERROR" "$MSG_CONTAINER_STOP_FAILED"
        return 1
    fi
}

# 숫자 인자 처리 (번호로 컨테이너 제거)
# Handle numeric arguments (remove container by number)
handle_numeric_arguments() {
    local -a indices=("$@")            # 숫자 인자들만

    # 인자 전부 숫자인지 확인
    for idx in "${indices[@]}"; do
        [[ "$idx" =~ ^[0-9]+$ ]] || { log "ERROR" "$(printf "$MSG_DOWN_INVALID_NUMBER" "$idx")"; return 1; }
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
            log "ERROR" "$(printf "$MSG_DOWN_INVALID_NUMBER" "$idx")"
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
        
        local spinner="Project $idx ($project_name) $MSG_SPINNER_DOWNING"
        
        # 프로젝트별 down 작업을 백그라운드에서 실행
        add_task "$spinner" \
            "project_down_action '$project_path' '$project_id' >/dev/null 2>&1"
    done

    async_tasks "$MSG_TASKS_DONE"
}

# 프로젝트별 down 액션 함수
# Project-specific down action function
project_down_action() {
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
    
    # Docker Compose로 컨테이너 중지 및 제거
    if docker compose -f "$compose_file" down; then
        # 성공 시 레지스트리 상태 업데이트
        update_project_state "$project_id" "$PROJECT_STATE_DOWN"
        return 0
    else
        return 1
    fi
}

# "all" 인자 처리 (모든 프로젝트 제거)
# Handle "all" argument (remove all projects)
handle_all_argument() {
    log "INFO" "$MSG_DOWN_ALL"
    
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

    # 각 프로젝트에 대해 down 작업
    for project_id in "${project_ids[@]}"; do
        # 프로젝트 경로 가져오기
        local project_path=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
        local project_name=$(basename "$project_path")
        
        # 프로젝트 경로 유효성 확인
        if [ ! -d "$project_path" ] || [ ! -f "$project_path/.dockit_project/docker-compose.yml" ]; then
            log "WARNING" "Project $project_name not found or invalid, skipping..."
            continue
        fi
        
        local spinner="Project $project_name $MSG_SPINNER_DOWNING"
        
        add_task "$spinner" \
            "project_down_action '$project_path' '$project_id' >/dev/null 2>&1"
    done

    async_tasks "$MSG_TASKS_DONE"
}

# 메인 함수
# Main function
down_main() {
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
                log "ERROR" "$MSG_DOWN_INVALID_ARGS"
                show_usage
            fi
            ;;
    esac
    
    return 0
}

# 직접 실행 시
# When executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    down_main "$@"
fi 