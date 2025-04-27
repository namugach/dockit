#!/bin/bash

# stop 모듈 - Docker 개발 환경 일시 중지
# stop module - Pause Docker development environment

# 공통 모듈 로드
# Load common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 컨테이너 정지 함수
# Function to stop a container
stop_container() {
    local container_id="$1"
    
    # 컨테이너 존재 여부 확인
    # Check if container exists
    if ! docker container inspect "$container_id" &>/dev/null; then
        log "ERROR" "$(printf "$MSG_CONTAINER_NOT_FOUND" "$container_id")"
        return 1
    fi
    
    # 컨테이너가 이미 정지되었는지 확인
    # Check if container is already stopped
    if [ "$(docker container inspect -f '{{.State.Running}}' "$container_id")" = "false" ]; then
        log "WARNING" "$(printf "$MSG_CONTAINER_ALREADY_STOPPED" "$container_id")"
        return 0
    fi
    
    # 컨테이너 정지
    # Stop container
    log "INFO" "$(printf "$MSG_STOPPING_CONTAINER" "$container_id")"
    if docker stop "$container_id"; then
        log "SUCCESS" "$(printf "$MSG_CONTAINER_STOPPED" "$container_id")"
        return 0
    else
        log "ERROR" "$(printf "$MSG_CONTAINER_STOP_FAILED" "$container_id")"
        return 1
    fi
}

# 현재 디렉토리 기반 컨테이너 정지 함수
# Function to stop container based on current directory
stop_current_project() {
    log "INFO" "$MSG_STOP_START"
    
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
        return 0
    fi
    
    # 컨테이너가 이미 정지되었는지 확인
    # Check if container is already stopped
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "false" ]; then
        log "WARNING" "$MSG_CONTAINER_ALREADY_STOPPED"
        return 0
    fi
    
    # 컨테이너 정지
    # Stop container
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" stop; then
        log "SUCCESS" "$MSG_CONTAINER_STOPPED"
        echo -e "\n${BLUE}$MSG_CONTAINER_STOPPED_INFO${NC}"
        return 0
    else
        log "ERROR" "$MSG_CONTAINER_STOP_FAILED"
        return 1
    fi
}

# 인덱스로 컨테이너 ID 가져오기
# Get container ID by index
get_container_id_by_index() {
    local index="$1"
    local container_ids=$(docker ps -a --filter "label=com.dockit=true" --format "{{.ID}}")
    
    # 인덱스에 해당하는 컨테이너 ID 가져오기
    local i=1
    for container_id in $(echo "$container_ids" | tac); do
        if [ "$i" -eq "$index" ]; then
            echo "$container_id"
            return 0
        fi
        ((i++))
    done
    
    return 1
}

# 모든 컨테이너 정지
# Stop all containers
stop_all_containers() {
    log "INFO" "$MSG_STOP_ALL"
    
    local container_ids=$(docker ps -a --filter "label=com.dockit=true" --filter "status=running" --format "{{.ID}}")
    
    if [ -z "$container_ids" ]; then
        log "INFO" "$MSG_NO_RUNNING_CONTAINERS"
        return 0
    fi
    
    local success_count=0
    local fail_count=0
    
    for container_id in $container_ids; do
        if stop_container "$container_id"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    log "INFO" "$(printf "$MSG_STOP_ALL_RESULT" "$success_count" "$fail_count")"
}

# 사용법 표시 함수
# Show usage function
show_usage() {
    log "INFO" "$MSG_STOP_USAGE"
    echo -e "  dockit stop <no> - $MSG_STOP_USAGE_NO"
    echo -e "  dockit stop this - $MSG_STOP_USAGE_THIS"
    echo -e "  dockit stop all - $MSG_STOP_USAGE_ALL"
    echo ""
}

# this 인자 처리 함수
# Handle 'this' argument function
handle_this_argument() {
    # 현재 디렉토리가 dockit 프로젝트인지 확인
    # Check if current directory is a dockit project
    if [ -d ".dockit_project" ]; then
        stop_current_project
    else
        log "WARNING" "$MSG_STOP_NOT_PROJECT"
    fi
}

# 숫자 인자 처리 함수
# Handle numeric arguments function
handle_numeric_arguments() {
    local args=("$@")
    
    # 모든 인자가 숫자인지 확인
    local all_numeric=true
    for arg in "${args[@]}"; do
        if ! [[ "$arg" =~ ^[0-9]+$ ]]; then
            all_numeric=false
            break
        fi
    done
    
    if ! $all_numeric; then
        return 1
    fi
    
    # 숫자에 해당하는 컨테이너 정지
    for arg in "${args[@]}"; do
        local container_id=$(get_container_id_by_index "$arg")
        if [ -n "$container_id" ]; then
            stop_container "$container_id"
        else
            log "ERROR" "$(printf "$MSG_STOP_INVALID_NUMBER" "$arg")"
        fi
    done
    
    return 0
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
            stop_all_containers
            ;;
        *)
            # 숫자 인자 처리 시도
            if handle_numeric_arguments "$@"; then
                return 0
            else
                # 잘못된 인자 처리
                log "ERROR" "$MSG_STOP_INVALID_ARGS"
                list_main "$@"
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