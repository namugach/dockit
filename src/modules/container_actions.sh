#!/bin/bash


# container_actions.sh - 컨테이너 액션 관련 공통 함수
# container_actions.sh - Common functions for container actions

# Load utils
# 유틸리티 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$UTILS_DIR/async_tasks.sh"

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

# 액션별 메시지 및 설정 로드
# Load messages and settings for specific action
load_action_config() {
    local action="$1"
    
    case "$action" in
        "start")
            echo "MSG_CONTAINER_ALREADY_RUNNING|MSG_STARTING_CONTAINER|MSG_CONTAINER_STARTED|MSG_CONTAINER_START_FAILED|true|docker start"
            ;;
        "stop")
            echo "MSG_CONTAINER_ALREADY_STOPPED|MSG_STOPPING_CONTAINER|MSG_CONTAINER_STOPPED|MSG_CONTAINER_STOP_FAILED|false|docker stop"
            ;;
        *)
            log "ERROR" "Invalid action: $action"
            return 1
            ;;
    esac
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
        if [ "$quiet" != "true" ]; then
            log "ERROR" "$MSG_CONTAINER_NOT_FOUND"
        fi
        return 1
    fi
    
    # 액션별 설정 로드
    local config=$(load_action_config "$action")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local already_msg=$(echo "$config" | cut -d'|' -f1)
    local action_msg=$(echo "$config" | cut -d'|' -f2)
    local success_msg=$(echo "$config" | cut -d'|' -f3)
    local fail_msg=$(echo "$config" | cut -d'|' -f4)
    local check_state=$(echo "$config" | cut -d'|' -f5)
    local docker_cmd=$(echo "$config" | cut -d'|' -f6)
    
    already_msg=${!already_msg}
    action_msg=${!action_msg}
    success_msg=${!success_msg}
    fail_msg=${!fail_msg}
    
    # 컨테이너 간단 정보 가져오기
    local container_short=${container_id:0:12}
    local name=$(docker inspect --format "{{.Name}}" "$container_id" 2>/dev/null | sed 's/^\///')
    local container_desc="$container_short"
    if [ -n "$name" ]; then
        container_desc="$container_desc ($name)"
    fi
    
    # 컨테이너가 이미 원하는 상태인지 확인
    # Check if container is already in desired state
    if [ "$check_state" = "true" ] && is_container_running "$container_id"; then
        if [ "$quiet" != "true" ]; then
            log "WARNING" "$(printf "$already_msg" "$container_desc")"
        fi
        return 0
    elif [ "$check_state" = "false" ] && ! is_container_running "$container_id"; then
        if [ "$quiet" != "true" ]; then
            log "WARNING" "$(printf "$already_msg" "$container_desc")"
        fi
        return 0
    fi
    
    # 컨테이너 액션 수행
    # Perform container action
    if [ "$quiet" != "true" ]; then
        log "INFO" "$(printf "$action_msg" "$container_desc")"
    fi
    
    if $docker_cmd "$container_id"; then
        if [ "$quiet" != "true" ]; then
            log "SUCCESS" "$(printf "$success_msg" "$container_desc")"
        fi
        return 0
    else
        if [ "$quiet" != "true" ]; then
            log "ERROR" "$(printf "$fail_msg" "$container_desc")"
        fi
        return 1
    fi
}

# 프로젝트 설정 로드 함수
# Function to load project configuration
load_project_config() {
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
        return 1
    fi
    
    # 설정 로드
    # Load configuration
    load_env
    return 0
}

# 프로젝트 컨테이너 상태 확인 함수
# Function to check project container state
check_project_container_state() {
    local action="$1"
    local check_state=""
    local already_msg=""
    local not_found_info=""
    
    if [ "$action" = "start" ]; then
        check_state="true"
        already_msg="$MSG_CONTAINER_ALREADY_RUNNING"
        not_found_info="$MSG_CONTAINER_NOT_FOUND_INFO"
    else
        check_state="false"
        already_msg="$MSG_CONTAINER_ALREADY_STOPPED"
        not_found_info=""
    fi
    
    # 컨테이너 존재 여부 확인
    # Check if container exists
    if ! container_exists "$CONTAINER_NAME"; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        if [ "$action" = "start" ] && [ -n "$not_found_info" ]; then
            echo -e "\n${YELLOW}$not_found_info${NC}"
            echo -e "${BLUE}dockit up${NC}"
            return 1
        fi
        return 2
    fi
    
    # 컨테이너가 이미 원하는 상태인지 확인
    # Check if container is already in desired state
    if [ "$check_state" = "true" ] && is_container_running "$CONTAINER_NAME"; then
        log "WARNING" "$already_msg"
        return 3
    elif [ "$check_state" = "false" ] && ! is_container_running "$CONTAINER_NAME"; then
        log "WARNING" "$already_msg"
        return 3
    fi
    
    return 0
}

# 현재 디렉토리 기반 컨테이너 액션 함수
# Function to perform action on container based on current directory
perform_current_project_action() {
    local action="$1"  # "start" 또는 "stop"
    
    # 액션 시작 메시지
    local start_msg=""
    if [ "$action" = "start" ]; then
        start_msg="$MSG_START_START"
    else
        start_msg="$MSG_STOP_START"
    fi
    log "INFO" "$start_msg"
    
    # 프로젝트 설정 로드
    if ! load_project_config; then
        return 1
    fi
    
    # 컨테이너 상태 확인
    check_project_container_state "$action"
    local state_check=$?
    
    if [ $state_check -eq 1 ] || [ $state_check -eq 2 ] || [ $state_check -eq 3 ]; then
        return $state_check
    fi
    
    # 액션 메시지 및 명령어 설정
    local action_msg=""
    local success_msg=""
    local fail_msg=""
    local docker_compose_cmd=""
    local success_info=""
    
    if [ "$action" = "start" ]; then
        action_msg="$MSG_STARTING_CONTAINER"
        success_msg="$MSG_CONTAINER_STARTED"
        fail_msg="$MSG_CONTAINER_START_FAILED"
        docker_compose_cmd="start"
        success_info="\n${BLUE}$MSG_CONNECT_INFO${NC} dockit connect"
    else
        action_msg="$MSG_STOPPING_CONTAINER"
        success_msg="$MSG_CONTAINER_STOPPED"
        fail_msg="$MSG_CONTAINER_STOP_FAILED"
        docker_compose_cmd="stop"
        success_info="\n${BLUE}$MSG_CONTAINER_STOPPED_INFO${NC}"
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

# 액션 타입에 따른 컨테이너 목록 가져오기
# Get container list based on action type
get_containers_for_action() {
    local action="$1"
    
    if [ "$action" = "start" ]; then
        docker ps -a --filter "label=com.dockit=true" --format "{{.ID}}"
    else  # stop
        docker ps -a --filter "label=com.dockit=true" --filter "status=running" --format "{{.ID}}"
    fi
}

# 모든 컨테이너 액션 수행 - 비동기 방식
# Perform action on all containers - async way
perform_all_containers_action() {
    local action="$1"  # "start" 또는 "stop"
    
    # 액션별 메시지 설정
    local start_msg=""
    local result_msg=""
    local no_containers_msg=""
    local spinner_action_text=""
    
    if [ "$action" = "start" ]; then
        start_msg="$MSG_START_ALL"
        result_msg="$MSG_START_ALL_RESULT"
        no_containers_msg="$MSG_NO_CONTAINERS"
        spinner_action_text="시작 중"
    else  # stop
        start_msg="$MSG_STOP_ALL"
        result_msg="$MSG_STOP_ALL_RESULT"
        no_containers_msg="$MSG_NO_RUNNING_CONTAINERS"
        spinner_action_text="중지 중"
    fi
    
    log "INFO" "$start_msg"
    
    # 컨테이너 목록 가져오기
    local container_ids=$(get_containers_for_action "$action")
    
    if [ -z "$container_ids" ]; then
        log "INFO" "$no_containers_msg"
        return 0
    fi
    
    # 결과 저장용 임시 파일
    local temp_result=$(mktemp)
    echo "0 0" > "$temp_result"  # 성공, 실패 카운트 초기화
    
    # 각 컨테이너에 대한 작업 추가
    for container_id in $container_ids; do
        local container_short=${container_id:0:12}
        
        # 컨테이너 기본 정보 가져오기
        local name=$(docker inspect --format "{{.Name}}" "$container_id" | sed 's/^\///')
        local container_desc="$container_short"
        if [ -n "$name" ]; then
            container_desc="$container_desc ($name)"
        fi
        
        # 직접 스피너 텍스트 생성
        local spinner_text="컨테이너 ${container_desc} ${spinner_action_text}"
        
        # 작업 추가
        add_task "$spinner_text" "
            if perform_container_action \"$action\" \"$container_id\" \"true\"; then
                # 성공 카운트 증가
                local counts=\$(cat \"$temp_result\")
                local success=\$(echo \"\$counts\" | cut -d' ' -f1)
                local fail=\$(echo \"\$counts\" | cut -d' ' -f2)
                echo \"\$((success+1)) \$fail\" > \"$temp_result\"
            else
                # 실패 카운트 증가
                local counts=\$(cat \"$temp_result\")
                local success=\$(echo \"\$counts\" | cut -d' ' -f1)
                local fail=\$(echo \"\$counts\" | cut -d' ' -f2)
                echo \"\$success \$((fail+1))\" > \"$temp_result\"
            fi
        "
    done
    
    # 비동기 작업 실행 (메시지 표시 없음)
    async_tasks_hide_finish_message
    
    # 결과 읽기
    local counts=$(cat "$temp_result")
    local success_count=$(echo "$counts" | cut -d' ' -f1)
    local fail_count=$(echo "$counts" | cut -d' ' -f2)
    
    # 임시 파일 삭제
    rm -f "$temp_result"
    
    # 결과 출력
    log "INFO" "$(printf "$result_msg" "$success_count" "$fail_count")"
}

# this 인자 처리 함수
# Handle 'this' argument function
handle_this_argument() {
    local action="$1"  # "start" 또는 "stop"
    
    # 액션에 따른 메시지 설정
    # Set messages according to action
    local not_project_msg=""
    if [ "$action" = "start" ]; then
        not_project_msg="$MSG_START_NOT_PROJECT"
    else  # stop
        not_project_msg="$MSG_STOP_NOT_PROJECT"
    fi
    
    # 현재 디렉토리가 dockit 프로젝트인지 확인
    # Check if current directory is a dockit project
    if [ -d ".dockit_project" ]; then
        perform_current_project_action "$action"
    else
        log "WARNING" "$not_project_msg"
    fi
}

set_action_messages() {
    local action="$1"
    declare -gA action_messages=()   # 전역 associative array로 선언

    case "$action" in
        "start")
            action_messages[invalid_number_msg]="$MSG_START_INVALID_NUMBER"
            action_messages[spinner_action_text]="시작 중??"
            ;;
        "stop")
            action_messages[invalid_number_msg]="$MSG_STOP_INVALID_NUMBER"
            action_messages[spinner_action_text]="중지 중??"
            ;;
    esac
}

check_if_all_numeric() {
    local -a check_args=("$@")
    for arg in "${check_args[@]}"; do
        if ! [[ "$arg" =~ ^[0-9]+$ ]]; then
            echo "false"
            break
        fi
    done
    echo "true"
}

# 숫자 인자 처리 함수
# Handle numeric arguments function
handle_numeric_arguments() {
    local action="$1"  # "start" 또는 "stop"
    shift
    local args=("$@")

        # 액션에 따른 메시지 설정
    # Set messages according to action
    set_action_messages "$action"
    local invalid_number_msg=${action_messages[invalid_number_msg]}
    local spinner_action_text=${action_messages[spinner_action_text]}
    
    # 모든 인자가 숫자인지 확인
    local all_numeric=$(check_if_all_numeric "${args[@]}")
    
    if ! $all_numeric; then
        return 1
    fi
    
    # 숫자에 해당하는 컨테이너 액션 수행 - 비동기 방식
    # 결과 저장용 임시 파일
    local temp_result=$(mktemp)
    
    for arg in "${args[@]}"; do
        local container_id=$(get_container_id_by_index "$arg")
        if [ -n "$container_id" ]; then
            local container_short=${container_id:0:12}
            
            # 컨테이너 기본 정보 가져오기
            local name=$(docker inspect --format "{{.Name}}" "$container_id" | sed 's/^\///')
            local container_desc="$container_short"
            if [ -n "$name" ]; then
                container_desc="$container_desc ($name)"
            fi
            
            # 직접 스피너 텍스트 생성
            local spinner_text="컨테이너 ${container_desc} ${spinner_action_text}"
            
            # 작업 추가
            add_task "$spinner_text" "
                perform_container_action \"$action\" \"$container_id\" \"true\"
            "
        else
            log "ERROR" "$(printf "$invalid_number_msg" "$arg")"
        fi
    done
    
    # 비동기 작업 실행 (메시지 표시 없음)
    async_tasks "작업 끝"
    
    return 0
} 