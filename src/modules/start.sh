#!/bin/bash

# Start module - Start Docker development environment
# start 모듈 - Docker 개발 환경 시작

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$MODULES_DIR/list.sh"

# 컨테이너 시작 함수
# Function to start a container
start_container() {
    local container_id="$1"
    
    # 컨테이너 존재 여부 확인
    # Check if container exists
    if ! docker container inspect "$container_id" &>/dev/null; then
        log "ERROR" "$(printf "$MSG_CONTAINER_NOT_FOUND" "$container_id")"
        return 1
    fi
    
    # 컨테이너가 이미 실행 중인지 확인
    # Check if container is already running
    if [ "$(docker container inspect -f '{{.State.Running}}' "$container_id")" = "true" ]; then
        log "WARNING" "$(printf "$MSG_CONTAINER_ALREADY_RUNNING" "$container_id")"
        return 0
    fi
    
    # 컨테이너 시작
    # Start container
    log "INFO" "$(printf "$MSG_STARTING_CONTAINER" "$container_id")"
    if docker start "$container_id"; then
        log "SUCCESS" "$(printf "$MSG_CONTAINER_STARTED" "$container_id")"
        return 0
    else
        log "ERROR" "$(printf "$MSG_CONTAINER_START_FAILED" "$container_id")"
        return 1
    fi
}

# 현재 디렉토리 기반 컨테이너 시작 함수
# Function to start container based on current directory
start_current_project() {
    log "INFO" "$MSG_START_START"
    
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
        echo -e "\n${YELLOW}$MSG_CONTAINER_NOT_FOUND_INFO${NC}"
        echo -e "${BLUE}dockit up${NC}"
        return 1
    fi
    
    # 컨테이너가 이미 실행 중인지 확인
    # Check if container is already running
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
        log "WARNING" "$MSG_CONTAINER_ALREADY_RUNNING"
        return 0
    fi
    
    # 컨테이너 시작
    # Start container
    log "INFO" "$MSG_STARTING_CONTAINER"
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" start; then
        log "SUCCESS" "$MSG_CONTAINER_STARTED"
        
        # 연결 방법 안내
        # Show connect instruction
        echo -e "\n${BLUE}$MSG_CONNECT_INFO${NC} dockit connect"
        return 0
    else
        log "ERROR" "$MSG_CONTAINER_START_FAILED"
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

# 모든 컨테이너 시작
# Start all containers
start_all_containers() {
    log "INFO" "$MSG_START_ALL"
    
    local container_ids=$(docker ps -a --filter "label=com.dockit=true" --format "{{.ID}}")
    local success_count=0
    local fail_count=0
    
    for container_id in $container_ids; do
        if start_container "$container_id"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    log "INFO" "$(printf "$MSG_START_ALL_RESULT" "$success_count" "$fail_count")"
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
        list_main "$@"
        echo ""
        log "INFO" "$MSG_START_USAGE"
        echo -e "  dockit start <no> - $MSG_START_USAGE_NO"
        echo -e "  dockit start this - $MSG_START_USAGE_THIS"
        echo -e "  dockit start all - $MSG_START_USAGE_ALL"
        return 0
    fi
    
    # 첫 번째 인자가 'this'인 경우 현재 디렉토리 컨테이너 시작
    # If first argument is 'this', start current directory container
    if [ "$1" = "this" ]; then
        # 현재 디렉토리가 dockit 프로젝트인지 확인
        # Check if current directory is a dockit project
        if [ -d ".dockit_project" ]; then
            start_current_project
        else
            log "WARNING" "$MSG_START_NOT_PROJECT"
        fi
        return 0
    fi
    
    # 첫 번째 인자가 "all"인 경우 모든 컨테이너 시작
    # If first argument is "all", start all containers
    if [ "$1" = "all" ]; then
        start_all_containers
        return 0
    fi
    
    # 숫자 인자들로 특정 컨테이너 시작
    # Start specific containers with numeric arguments
    local all_numeric=true
    for arg in "$@"; do
        if ! [[ "$arg" =~ ^[0-9]+$ ]]; then
            all_numeric=false
            break
        fi
    done
    
    if $all_numeric; then
        for arg in "$@"; do
            local container_id=$(get_container_id_by_index "$arg")
            if [ -n "$container_id" ]; then
                start_container "$container_id"
            else
                log "ERROR" "$(printf "$MSG_START_INVALID_NUMBER" "$arg")"
            fi
        done
        return 0
    fi
    
    # 잘못된 인자 처리
    # Handle invalid arguments
    log "ERROR" "$MSG_START_INVALID_ARGS"
    log "INFO" "$MSG_START_USAGE"
    echo -e "  dockit start <no> - $MSG_START_USAGE_NO"
    echo -e "  dockit start this - $MSG_START_USAGE_THIS"
    echo -e "  dockit start all - $MSG_START_USAGE_ALL"
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start_main "$@"
fi 