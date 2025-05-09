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
            log "ERROR" "$(printf "$MSG_ACTION_NOT_SUPPORTED" "$action")"
            return 1
            ;;
    esac
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

# 액션 설정 파싱 함수
# Function to parse action configuration
parse_action_config() {
    local config="$1"
    local container_desc="$2"
    
    local already_msg_key=$(echo "$config" | cut -d'|' -f1)
    local action_msg_key=$(echo "$config" | cut -d'|' -f2)
    local success_msg_key=$(echo "$config" | cut -d'|' -f3)
    local fail_msg_key=$(echo "$config" | cut -d'|' -f4)
    
    # 전역 변수로 결과 설정
    PARSED_CHECK_STATE=$(echo "$config" | cut -d'|' -f5)
    PARSED_DOCKER_CMD=$(echo "$config" | cut -d'|' -f6)
    
    # 메시지 변수 참조 해결 및 컨테이너 설명 포맷팅
    PARSED_ALREADY_MSG=$(printf "${!already_msg_key}" "$container_desc")
    PARSED_ACTION_MSG=$(printf "${!action_msg_key}" "$container_desc")
    PARSED_SUCCESS_MSG=$(printf "${!success_msg_key}" "$container_desc")
    PARSED_FAIL_MSG=$(printf "${!fail_msg_key}" "$container_desc")
}

# 컨테이너 상태 확인 함수
# Function to check container state
check_container_state() {
    local container_id="$1"
    local check_state="$2"
    
    if [ "$check_state" = "true" ] && is_container_running "$container_id"; then
        return 0
    elif [ "$check_state" = "false" ] && ! is_container_running "$container_id"; then
        return 0
    fi
    return 1
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
    
    # 액션별 설정 로드
    local config=$(load_action_config "$action")
    [ $? -ne 0 ] && return 1
    
    # 설정 파싱
    parse_action_config "$config" "$container_desc"
    local already_msg="$PARSED_ALREADY_MSG"
    local action_msg="$PARSED_ACTION_MSG"
    local success_msg="$PARSED_SUCCESS_MSG"
    local fail_msg="$PARSED_FAIL_MSG"
    local check_state="$PARSED_CHECK_STATE"
    local docker_cmd="$PARSED_DOCKER_CMD"
    
    # 컨테이너가 이미 원하는 상태인지 확인
    # Check if container is already in desired state
    if check_container_state "$container_id" "$check_state"; then
        [ "$quiet" != "true" ] && log "WARNING" "$already_msg"
        return 0
    fi
    
    # 컨테이너 액션 수행
    # Perform container action
    [ "$quiet" != "true" ] && log "INFO" "$action_msg"
    
    if $docker_cmd "$container_id"; then
        [ "$quiet" != "true" ] && log "SUCCESS" "$success_msg"
        return 0
    else
        [ "$quiet" != "true" ] && log "ERROR" "$fail_msg"
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


# 컨테이너 상태 파라미터 설정 함수
# Function to set container state parameters
set_container_state_params() {
    local action="$1"
    local -n state_ref="$2"
    local -n already_msg_ref="$3"
    local -n not_found_info_ref="$4"
    
    case "$action" in
        "start")
            state_ref="true"
            already_msg_ref="$MSG_CONTAINER_ALREADY_RUNNING"
            not_found_info_ref="$MSG_CONTAINER_NOT_FOUND_INFO"
            ;;
        "stop")  # 명확하게 stop 케이스 지정
            state_ref="false"
            already_msg_ref="$MSG_CONTAINER_ALREADY_STOPPED"
            not_found_info_ref=""
            ;;
        *)  # 그 외 케이스
            log "ERROR" "$(printf "$MSG_ACTION_NOT_SUPPORTED" "$action")"
            return 1
            ;;
    esac
    
    return 0
}

# 컨테이너 존재 여부 확인
# Check if container exists
check_container_exists() {
    local action="$1"
    local not_found_info="$2"
    
    if ! container_exists "$CONTAINER_NAME"; then
        log "WARNING" "$MSG_CONTAINER_NOT_FOUND"
        if [ "$action" = "start" ] && [ -n "$not_found_info" ]; then
            echo -e "\n${YELLOW}$not_found_info${NC}"
            echo -e "${BLUE}dockit up${NC}"
            return 1
        fi
        return 2
    fi
    
    return 0
}

# 프로젝트 컨테이너 상태 확인 함수
# Function to check project container state
check_project_container_state() {
    local action="$1"
    local check_state=""
    local already_msg=""
    local not_found_info=""
    
    # 액션에 따른 상태 및 메시지 설정
    # Set state and messages according to action
    set_container_state_params "$action" check_state already_msg not_found_info
    if [ $? -ne 0 ]; then
        return 1
    fi
    

    
    # 컨테이너 존재 여부 확인 실행
    if ! check_container_exists "$action" "$not_found_info"; then
        return $?
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


# 액션 시작 메시지 설정 함수
# Function to set action start message
set_action_start_message() {
    local action="$1"
    local -n msg_ref="$2"
    
    if [ "$action" = "start" ]; then
        msg_ref="$MSG_START_START"
    else
        msg_ref="$MSG_STOP_START"
    fi
}

# 액션 메시지 및 명령어 설정 함수
# Function to set action messages and commands
set_action_messages_and_commands() {
    local action="$1"
    local -n action_msg_ref="$2"
    local -n success_msg_ref="$3"
    local -n fail_msg_ref="$4"
    local -n docker_compose_cmd_ref="$5"
    local -n success_info_ref="$6"
    
    case "$action" in
        "start")
            action_msg_ref="$MSG_STARTING_CONTAINER"
            success_msg_ref="$MSG_CONTAINER_STARTED"
            fail_msg_ref="$MSG_CONTAINER_START_FAILED"
            docker_compose_cmd_ref="start"
            success_info_ref="\n${BLUE}$MSG_CONNECT_INFO${NC} dockit connect"
            ;;
        "stop")  # 명확하게 stop 케이스 지정
            action_msg_ref="$MSG_STOPPING_CONTAINER"
            success_msg_ref="$MSG_CONTAINER_STOPPED"
            fail_msg_ref="$MSG_CONTAINER_STOP_FAILED"
            docker_compose_cmd_ref="stop"
            success_info_ref="\n${BLUE}$MSG_CONTAINER_STOPPED_INFO${NC}"
            ;;
        *)  # 그 외 케이스
            log "ERROR" "$(printf "$MSG_ACTION_NOT_SUPPORTED" "$action")"
            return 1
            ;;
    esac
    
    return 0
}

# 현재 디렉토리 기반 컨테이너 액션 함수
# Function to perform action on container based on current directory
perform_current_project_action() {
    local action="$1"  # "start" 또는 "stop"
    
    # 액션 시작 메시지 설정 및 출력
    set_action_start_message "$action" start_msg
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
    
    set_action_messages_and_commands "$action" action_msg success_msg fail_msg docker_compose_cmd success_info
    
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

# 모든 컨테이너 액션용 메시지 설정 함수
# Function to set messages for all containers action
set_all_containers_action_messages() {
    local action="$1"
    local -n start_msg_ref="$2"
    local -n result_msg_ref="$3"
    local -n no_containers_msg_ref="$4"
    local -n spinner_action_text_ref="$5"
    
    case "$action" in
        "start")
            start_msg_ref="$MSG_START_ALL"
            result_msg_ref="$MSG_START_ALL_RESULT"
            no_containers_msg_ref="$MSG_NO_CONTAINERS"
            spinner_action_text_ref="$MSG_SPINNER_STARTING"
            ;;
        "stop")  # 명확하게 stop 케이스 지정
            start_msg_ref="$MSG_STOP_ALL"
            result_msg_ref="$MSG_STOP_ALL_RESULT"
            no_containers_msg_ref="$MSG_NO_RUNNING_CONTAINERS"
            spinner_action_text_ref="$MSG_SPINNER_STOPPING"
            ;;
        *)  # 그 외 케이스
            log "ERROR" "$(printf "$MSG_ACTION_NOT_SUPPORTED" "$action")"
            return 1
            ;;
    esac
    
    return 0
}

# 컨테이너 작업 추가 함수
# Function to add container tasks
add_container_tasks() {
    local action="$1"
    local spinner_action_text="$2"
    local temp_result="$3"
    local container_ids="$4"
    
    for container_id in $container_ids; do
        local container_short=${container_id:0:12}
        
        # 컨테이너 기본 정보 가져오기
        local name=$(docker inspect --format "{{.Name}}" "$container_id" | sed 's/^\///')
        local container_desc="$container_short"
        if [ -n "$name" ]; then
            container_desc="$container_desc ($name)"
        fi
        
        # 직접 스피너 텍스트 생성
        local spinner_text=$(printf "$MSG_CONTAINER_ACTION_FORMAT" "${container_desc}" "${spinner_action_text}")
        
        # 작업 추가 - 완료 메시지가 출력되지 않도록 수정
        add_task "$spinner_text" "
            if perform_container_action \"$action\" \"$container_id\" \"true\" > /dev/null 2>&1; then
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
}

# 결과 처리 함수
# Function to process results
process_action_results() {
    local temp_result="$1"
    local result_msg="$2"
    
    # 결과 읽기
    local counts=$(cat "$temp_result")
    local success_count=$(echo "$counts" | cut -d' ' -f1)
    local fail_count=$(echo "$counts" | cut -d' ' -f2)
    
    # 임시 파일 삭제
    rm -f "$temp_result"
    
    # 결과 출력 - 완료 메시지가 이미 표시되었으므로 여기서는 결과 메시지만 조용히 로깅
    if [ "$fail_count" -gt 0 ]; then
        log "INFO" "$(printf "$result_msg" "$success_count" "$fail_count")"
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
    
    if ! set_all_containers_action_messages "$action" start_msg result_msg no_containers_msg spinner_action_text; then
        return 1
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
    
    # 컨테이너 작업 추가
    add_container_tasks "$action" "$spinner_action_text" "$temp_result" "$container_ids"
    
    # 비동기 작업 실행 (메시지 표시 있음)
    async_tasks "$MSG_TASKS_DONE"
    
    # 결과 처리
    process_action_results "$temp_result" "$result_msg"
    
    return 0
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

# 액션에 따른 메시지 설정
# Set messages according to action  
set_action_messages() {
    local action="$1"
    declare -gA action_messages=()   # 전역 associative array로 선언

    case "$action" in
        "start")
            action_messages[invalid_number_msg]="$MSG_START_INVALID_NUMBER"
            action_messages[spinner_action_text]="$MSG_SPINNER_STARTING"
            ;;
        "stop")  # 명확하게 stop 케이스 지정
            action_messages[invalid_number_msg]="$MSG_STOP_INVALID_NUMBER"
            action_messages[spinner_action_text]="$MSG_SPINNER_STOPPING"
            ;;
        *)  # 그 외 케이스
            log "ERROR" "$(printf "$MSG_ACTION_NOT_SUPPORTED" "$action")"
            return 1
            ;;
    esac
}

# 모든 인자가 숫자인지 확인
# Check if all arguments are numeric  
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

# 컨테이너 작업 처리 함수
# Function to process container tasks
process_container_tasks() {
    local action="$1"
    local spinner_action_text="$2"
    local invalid_number_msg="$3"
    shift 3
    local container_indices=("$@")
    
    for container_index in "${container_indices[@]}"; do
        local container_id=$(get_container_id_by_index "$container_index")
        if [ -n "$container_id" ]; then
            local container_short=${container_id:0:12}
            
            # 컨테이너 기본 정보 가져오기
            local name=$(docker inspect --format "{{.Name}}" "$container_id" | sed 's/^\///')
            local container_desc="$container_short"
            if [ -n "$name" ]; then
                container_desc="$container_desc ($name)"
            fi
            
            # 직접 스피너 텍스트 생성
            local spinner_text=$(printf "$MSG_CONTAINER_ACTION_FORMAT" "${container_desc}" "${spinner_action_text}")
            
            # 작업 추가 - 출력 리다이렉션으로 메시지 숨기기
            add_task "$spinner_text" "
                perform_container_action \"$action\" \"$container_id\" \"true\" > /dev/null 2>&1
            "
        else
            log "ERROR" "$(printf "$invalid_number_msg" "$container_index")"
        fi
    done
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
    
    # 컨테이너 작업 처리 함수 호출
    process_container_tasks "$action" "$spinner_action_text" "$invalid_number_msg" "${args[@]}"
    
    # 비동기 작업 실행 (메시지 표시 없음)
    async_tasks "$MSG_TASKS_DONE"
    
    return 0
} 