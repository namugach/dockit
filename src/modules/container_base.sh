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

# 컨테이너 액션 수행 함수 (시작 또는 정지)
# Function to perform action on a container (start or stop)
perform_container_action() {
    local action="$1"      # "start" 또는 "stop"
    local container_id="$2"
    local quiet="${3:-false}"  # 로그 출력 여부 (기본값: 출력함)
    
    # 컨테이너 존재 여부 확인
    # Check if container exists
    if ! container_exists "$container_id"; then
        [ "$quiet" != "true" ] && log "ERROR" "$MSG_CONTAINER_NOT_FOUND"
        return 1
    fi
    
    # 컨테이너 정보 가져오기
    local container_desc=$(get_container_description "$container_id")
    
    # 액션이 start인 경우
    if [[ "$action" == "start" ]]; then
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
    # 액션이 stop인 경우
    elif [[ "$action" == "stop" ]]; then
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
    else
        log "ERROR" "$(printf "$MSG_ACTION_NOT_SUPPORTED" "$action")"
        return 1
    fi
}

# 컨테이너 ID 목록 가져오기 (필터 적용)
# Get container ID list with filter
get_container_ids() {
    local filter="$1"  # 필터 (예: 모든 컨테이너, 실행 중인 컨테이너 등)
    
    docker ps -a --filter "label=com.dockit=true" $filter --format "{{.ID}}"
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