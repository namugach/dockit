#!/bin/bash

# container_base.sh - 컨테이너 액션 관련 공통 함수
# container_base.sh - Common utility functions for containers

# Load utils
# 유틸리티 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$UTILS_DIR/async_tasks.sh"

# 사용법 표시 함수
# Show usage function
show_usage() {
    log "INFO" "$MSG_STOP_USAGE"
    echo -e "  dockit stop <no> - $MSG_STOP_USAGE_NO"
    echo -e "  dockit stop this - $MSG_STOP_USAGE_THIS"
    echo -e "  dockit stop all - $MSG_STOP_USAGE_ALL"
    echo ""
}

# 컨테이너 존재 여부 확인 함수
# Function to check if container exists
container_exists() {
    local container_id="$1"
    docker container inspect "$container_id" &>/dev/null
    return $?
}

# 컨테이너 실행 상태 확인 함수
# Function to check container running state
is_container_running() {
    local container_id="$1"
    [ "$(docker container inspect -f '{{.State.Running}}' "$container_id")" = "true" ]
    return $?
}

# 컨테이너 설명 가져오기 함수
# Function to get container description
get_container_description() {
    local container_id="$1"
    local container_short=${container_id:0:12}
    local name=$(docker inspect --format "{{.Name}}" "$container_id" 2>/dev/null | sed 's/^\///')
    
    local container_desc="$container_short"
    [ -n "$name" ] && container_desc="$container_desc ($name)"
    
    echo "$container_desc"
}

# 도커 컨테이너 정보 캐싱
# Cache docker container info
get_container_info() {
    local container_id="$1"
    local info_type="$2"  # name, status 등
    
    case "$info_type" in
        "name")
            docker inspect --format "{{.Name}}" "$container_id" 2>/dev/null | sed 's/^\///'
            ;;
        "status")
            docker inspect --format "{{.State.Status}}" "$container_id" 2>/dev/null
            ;;
        "running")
            docker inspect --format "{{.State.Running}}" "$container_id" 2>/dev/null
            ;;
        *)
            echo ""
            return 1
            ;;
    esac
    
    return 0
}

# 컨테이너 ID 목록 가져오기 (필터 적용)
# Get container ID list with filter
get_container_ids() {
    local filter="$1"  # 필터 (예: 모든 컨테이너, 실행 중인 컨테이너 등)
    
    docker ps -a --filter "label=com.dockit=true" $filter --format "{{.ID}}"
}

# perform_container_action 함수는 start_container와 stop_container로 분리되어
# 각각 start.sh와 stop.sh 파일로 이동되었습니다.

handle_this_argument() {
    local docker_cmd=$1
    local -n MSG=$2  # 객체처럼 넘긴 메시지 구조체

    # [[ -d .dockit_project ]] || { log "WARNING" "${MSG[not_project]}"; return 1; }
    if [[ ! -d .dockit_project ]]; then
        log "WARNING" "${MSG[not_project]}"
        return 1
    fi

    log "INFO" "${MSG[start]}"

    [[ -f $DOCKER_COMPOSE_FILE ]] || { log "ERROR" "$MSG_COMPOSE_NOT_FOUND"; return 1; }

    load_env

    if ! container_exists "$CONTAINER_NAME"; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        echo -e "\n${YELLOW}$MSG_CONTAINER_NOT_FOUND_INFO${NC}\n${BLUE}dockit up${NC}"
        return 2
    fi

    # 명령어에 따라 다르게 처리
    if [[ "$docker_cmd" == "start" ]]; then
        # start 명령어: 이미 실행 중인지 확인
        if is_container_running "$CONTAINER_NAME"; then
            log "WARNING" "${MSG[not_active]}"
            return 3
        fi
    elif [[ "$docker_cmd" == "stop" ]]; then
        # stop 명령어: 이미 정지되었는지 확인
        if ! is_container_running "$CONTAINER_NAME"; then
            local container_desc=$(get_container_description "$CONTAINER_NAME")
            log "WARNING" "$(printf "${MSG[not_active]}" "$container_desc")"
            return 3
        fi
    fi

    log "INFO" "${MSG[doing]}"
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" "$docker_cmd"; then
        log "SUCCESS" "${MSG[done]}"
        echo -e "\n${BLUE}${MSG[info]}${NC}"
        return 0
    else
        log "ERROR" "${MSG[fail]}"
        return 1
    fi
}