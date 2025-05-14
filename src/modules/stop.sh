#!/bin/bash

# stop 모듈 - Docker 개발 환경 일시 중지
# stop module - Pause Docker development environment

# 공통 모듈 로드
# Load common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$MODULES_DIR/container_base.sh"

# "this" 인자 처리 (현재 프로젝트 컨테이너 정지)
# Handle "this" argument (stop current project container)
handle_this_argument() {
    # -- 1) dockit 프로젝트 디렉터리 확인 ----------------
    if [[ ! -d .dockit_project ]]; then
        log "WARNING" "$MSG_STOP_NOT_PROJECT"
        return 1
    fi

    # -- 2) 시작 메시지 ----------------------------------
    log "INFO" "$MSG_STOP_START"

    # -- 3) docker-compose 파일 체크 ---------------------
    [[ -f $DOCKER_COMPOSE_FILE ]] || { log "ERROR" "$MSG_COMPOSE_NOT_FOUND"; return 1; }

    # -- 4) 환경 로드 ------------------------------------
    load_env

    # -- 5) 컨테이너 존재 여부 ----------------------------
    if ! container_exists "$CONTAINER_NAME"; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        return 2
    fi

    # -- 6) 이미 정지된 상태인지 확인 --------------------
    if ! is_container_running "$CONTAINER_NAME"; then
        log "WARNING" "$MSG_CONTAINER_ALREADY_STOPPED"
        return 3
    fi

    # -- 7) 실제 액션 수행 --------------------------------
    log "INFO" "$MSG_STOPPING_CONTAINER"
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" stop; then
        log "SUCCESS" "$MSG_CONTAINER_STOPPED"
        echo -e "\n${BLUE}$MSG_CONTAINER_STOPPED_INFO${NC}"
        return 0
    else
        log "ERROR" "$MSG_CONTAINER_STOP_FAILED"
        return 1
    fi
}

# 컨테이너 정지 함수
# Stop container function
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
    
    # 이미 정지된 상태인지 확인
    if ! is_container_running "$container_id"; then
        [ "$quiet" != "true" ] && log "WARNING" "$(printf "$MSG_CONTAINER_ALREADY_STOPPED" "$container_desc")"
        return 0
    fi
    
    # 컨테이너 정지
    [ "$quiet" != "true" ] && log "INFO" "$(printf "$MSG_STOPPING_CONTAINER" "$container_desc")"
    if docker stop "$container_id"; then
        [ "$quiet" != "true" ] && log "SUCCESS" "$(printf "$MSG_CONTAINER_STOPPED" "$container_desc")"
        return 0
    else
        [ "$quiet" != "true" ] && log "ERROR" "$(printf "$MSG_CONTAINER_STOP_FAILED" "$container_desc")"
        return 1
    fi
}

# 숫자 인자 처리 (번호로 컨테이너 정지)
# Handle numeric arguments (stop container by number)
handle_numeric_arguments() {
    local -a indices=("$@")            # 숫자 인자들만

    # 인자 전부 숫자인지 확인
    for idx in "${indices[@]}"; do
        [[ "$idx" =~ ^[0-9]+$ ]] || { log "ERROR" "$(printf "$MSG_STOP_INVALID_NUMBER" "$idx")"; return 1; }
    done

    # 컨테이너 ID 목록 (최근 생성 순서 역순)
    mapfile -t container_ids < <(docker ps -a --filter "label=com.dockit=true" --format "{{.ID}}" | tac)

    # 각 인덱스 처리
    for idx in "${indices[@]}"; do
        local array_idx=$((idx-1))                # 인덱스 → 배열 위치
        local cid=${container_ids[$array_idx]:-}

        if [[ -z "$cid" ]]; then
            log "ERROR" "$(printf "$MSG_STOP_INVALID_NUMBER" "$idx")"
            continue
        fi

        local short=${cid:0:12}
        local name=$(get_container_info "$cid" "name")
        [[ -n "$name" ]] && short="$short ($name)"

        local spinner=$(printf "$MSG_CONTAINER_ACTION_FORMAT" "$short" "$MSG_SPINNER_STOPPING")

        add_task "$spinner" \
            "container_action '$cid' true >/dev/null 2>&1"
    done

    async_tasks "$MSG_TASKS_DONE"
}


# 메인 함수
# Main function
stop_main() {
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
            # all 인자 처리
            # _perform_all_containers_action
            local docker_cmd=(docker ps -a --filter label=com.dockit=true --filter status=running --format '{{.ID}}')
            perform_all_containers_action \
              "$MSG_STOP_ALL" \
              "$MSG_STOP_ALL_RESULT" \
              "$MSG_NO_RUNNING_CONTAINERS" \
              "$MSG_SPINNER_STOPPING" \
              docker_cmd
            ;;
        *)
            # 숫자 인자 처리 시도
            if handle_numeric_arguments "$@"; then
                return 0
            else
                # 잘못된 인자 처리
                log "ERROR" "$MSG_STOP_INVALID_ARGS"
                show_usage "$@"
            fi
            ;;
    esac
    
    return 0
}

# 직접 실행 시
# When executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    stop_main "$@"
fi 