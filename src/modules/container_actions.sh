#!/bin/bash


# container_actions.sh - 컨테이너 액션 관련 공통 함수
# container_actions.sh - Common functions for container actions

# 컨테이너 액션 함수 (시작 또는 정지)
# Function to perform action on a container (start or stop)
perform_container_action() {
    local action="$1"      # "start" 또는 "stop"
    local container_id="$2"
    
    # 액션에 따른 메시지 및 명령어 설정
    # Set messages and commands according to action
    case "$action" in
        "start")
            local already_msg="$MSG_CONTAINER_ALREADY_RUNNING"
            local action_msg="$MSG_STARTING_CONTAINER"
            local success_msg="$MSG_CONTAINER_STARTED"
            local fail_msg="$MSG_CONTAINER_START_FAILED"
            local check_state="true"  # 시작 시에는 실행 중인지 확인
            local docker_cmd="docker start"
            ;;
        "stop")
            local already_msg="$MSG_CONTAINER_ALREADY_STOPPED"
            local action_msg="$MSG_STOPPING_CONTAINER"
            local success_msg="$MSG_CONTAINER_STOPPED"
            local fail_msg="$MSG_CONTAINER_STOP_FAILED"
            local check_state="false"  # 정지 시에는 정지 상태인지 확인
            local docker_cmd="docker stop"
            ;;
        *)
            log "ERROR" "Invalid action: $action"
            return 1
            ;;
    esac
    
    # 컨테이너 존재 여부 확인
    # Check if container exists
    if ! docker container inspect "$container_id" &>/dev/null; then
        log "ERROR" "$(printf "$MSG_CONTAINER_NOT_FOUND" "$container_id")"
        return 1
    fi
    
    # 컨테이너가 이미 원하는 상태인지 확인
    # Check if container is already in desired state
    if [ "$(docker container inspect -f '{{.State.Running}}' "$container_id")" = "$check_state" ]; then
        log "WARNING" "$(printf "$already_msg" "$container_id")"
        return 0
    fi
    
    # 컨테이너 액션 수행
    # Perform container action
    log "INFO" "$(printf "$action_msg" "$container_id")"
    if $docker_cmd "$container_id"; then
        log "SUCCESS" "$(printf "$success_msg" "$container_id")"
        return 0
    else
        log "ERROR" "$(printf "$fail_msg" "$container_id")"
        return 1
    fi
}

# 현재 디렉토리 기반 컨테이너 액션 함수
# Function to perform action on container based on current directory
perform_current_project_action() {
    local action="$1"  # "start" 또는 "stop"
    
    # 액션에 따른 메시지 및 명령어 설정
    # Set messages and commands according to action
    case "$action" in
        "start")
            local start_msg="$MSG_START_START"
            local already_msg="$MSG_CONTAINER_ALREADY_RUNNING"
            local action_msg="$MSG_STARTING_CONTAINER"
            local success_msg="$MSG_CONTAINER_STARTED"
            local fail_msg="$MSG_CONTAINER_START_FAILED"
            local check_state="true"  # 시작 시에는 실행 중인지 확인
            local docker_compose_cmd="start"
            local not_found_info="$MSG_CONTAINER_NOT_FOUND_INFO"
            local success_info="\n${BLUE}$MSG_CONNECT_INFO${NC} dockit connect"
            ;;
        "stop")
            local start_msg="$MSG_STOP_START"
            local already_msg="$MSG_CONTAINER_ALREADY_STOPPED"
            local action_msg="$MSG_STOPPING_CONTAINER"
            local success_msg="$MSG_CONTAINER_STOPPED"
            local fail_msg="$MSG_CONTAINER_STOP_FAILED"
            local check_state="false"  # 정지 시에는 정지 상태인지 확인
            local docker_compose_cmd="stop"
            local not_found_info=""
            local success_info="\n${BLUE}$MSG_CONTAINER_STOPPED_INFO${NC}"
            ;;
        *)
            log "ERROR" "Invalid action: $action"
            return 1
            ;;
    esac
    
    log "INFO" "$start_msg"
    
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
        if [ "$action" = "start" ] && [ -n "$not_found_info" ]; then
            echo -e "\n${YELLOW}$not_found_info${NC}"
            echo -e "${BLUE}dockit up${NC}"
            return 1
        fi
        return 0
    fi
    
    # 컨테이너가 이미 원하는 상태인지 확인
    # Check if container is already in desired state
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "$check_state" ]; then
        log "WARNING" "$already_msg"
        return 0
    fi
    
    # 컨테이너 액션 수행
    # Perform container action
    log "INFO" "$action_msg"
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" $docker_compose_cmd; then
        log "SUCCESS" "$success_msg"
        
        # 성공 후 추가 정보 출력
        # Display additional info after success
        if [ -n "$success_info" ]; then
            echo -e "$success_info"
        fi
        return 0
    else
        log "ERROR" "$fail_msg"
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

# 모든 컨테이너 액션 수행
# Perform action on all containers
perform_all_containers_action() {
    local action="$1"  # "start" 또는 "stop"
    
    # 액션에 따른 메시지 및 필터 설정
    # Set messages and filters according to action
    case "$action" in
        "start")
            local start_msg="$MSG_START_ALL"
            local result_msg="$MSG_START_ALL_RESULT"
            local container_ids=$(docker ps -a --filter "label=com.dockit=true" --format "{{.ID}}")
            local no_containers_msg="$MSG_NO_CONTAINERS"
            ;;
        "stop")
            local start_msg="$MSG_STOP_ALL"
            local result_msg="$MSG_STOP_ALL_RESULT"
            local container_ids=$(docker ps -a --filter "label=com.dockit=true" --filter "status=running" --format "{{.ID}}")
            local no_containers_msg="$MSG_NO_RUNNING_CONTAINERS"
            ;;
        *)
            log "ERROR" "Invalid action: $action"
            return 1
            ;;
    esac
    
    log "INFO" "$start_msg"
    
    if [ -z "$container_ids" ]; then
        log "INFO" "$no_containers_msg"
        return 0
    fi
    
    local success_count=0
    local fail_count=0
    
    for container_id in $container_ids; do
        if perform_container_action "$action" "$container_id"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done
    
    log "INFO" "$(printf "$result_msg" "$success_count" "$fail_count")"
}

# this 인자 처리 함수
# Handle 'this' argument function
handle_this_argument() {
    local action="$1"  # "start" 또는 "stop"
    
    # 액션에 따른 메시지 설정
    # Set messages according to action
    case "$action" in
        "start")
            local not_project_msg="$MSG_START_NOT_PROJECT"
            ;;
        "stop")
            local not_project_msg="$MSG_STOP_NOT_PROJECT"
            ;;
        *)
            log "ERROR" "Invalid action: $action"
            return 1
            ;;
    esac
    
    # 현재 디렉토리가 dockit 프로젝트인지 확인
    # Check if current directory is a dockit project
    if [ -d ".dockit_project" ]; then
        perform_current_project_action "$action"
    else
        log "WARNING" "$not_project_msg"
    fi
}

# 숫자 인자 처리 함수
# Handle numeric arguments function
handle_numeric_arguments() {
    local action="$1"  # "start" 또는 "stop"
    shift
    local args=("$@")
    
    # 액션에 따른 메시지 설정
    # Set messages according to action
    case "$action" in
        "start")
            local invalid_number_msg="$MSG_START_INVALID_NUMBER"
            ;;
        "stop")
            local invalid_number_msg="$MSG_STOP_INVALID_NUMBER"
            ;;
        *)
            log "ERROR" "Invalid action: $action"
            return 1
            ;;
    esac
    
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
    
    # 숫자에 해당하는 컨테이너 액션 수행
    for arg in "${args[@]}"; do
        local container_id=$(get_container_id_by_index "$arg")
        if [ -n "$container_id" ]; then
            perform_container_action "$action" "$container_id"
        else
            log "ERROR" "$(printf "$invalid_number_msg" "$arg")"
        fi
    done
    
    return 0
} 