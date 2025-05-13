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

# 기존 함수들을 대체할 통합 액션 설정 함수 추가
# Unified function to get all action related configuration and messages
get_action_config() {
    local action="$1"
    local config_type="${2:-all}"  # 기본값으로 모든 설정 반환
    
    # 모든 액션별 설정과 메시지를 담을 associative array
    declare -A config
    
    case "$action" in
        "start")
            # 기본 메시지 키와 값
            config[already_msg_key]="$MSG_CONTAINER_ALREADY_RUNNING"
            config[action_msg_key]="$MSG_STARTING_CONTAINER"
            config[success_msg_key]="$MSG_CONTAINER_STARTED"
            config[fail_msg_key]="$MSG_CONTAINER_START_FAILED"
            config[check_state]="true"
            config[docker_cmd]="docker start"
            config[docker_compose_cmd]="start"
            
            # 컨테이너 상태 파라미터
            config[not_found_info]="$MSG_CONTAINER_NOT_FOUND_INFO"
            
            # 모든 컨테이너 액션 메시지
            config[start_msg]="$MSG_START_ALL"
            config[result_msg]="$MSG_START_ALL_RESULT"
            config[no_containers_msg]="$MSG_NO_CONTAINERS"
            config[spinner_action_text]="$MSG_SPINNER_STARTING"
            
            # 현재 프로젝트 액션 메시지
            config[project_start_msg]="$MSG_START_START"
            config[success_info]="\n${BLUE}$MSG_CONNECT_INFO${NC} dockit connect"
            
            # 숫자 인자 메시지
            config[invalid_number_msg]="$MSG_START_INVALID_NUMBER"
            
            # this 인자 메시지
            config[not_project_msg]="$MSG_START_NOT_PROJECT"
            ;;
            
        "stop")
            # 기본 메시지 키와 값
            config[already_msg_key]="$MSG_CONTAINER_ALREADY_STOPPED"
            config[action_msg_key]="$MSG_STOPPING_CONTAINER" 
            config[success_msg_key]="$MSG_CONTAINER_STOPPED"
            config[fail_msg_key]="$MSG_CONTAINER_STOP_FAILED"
            config[check_state]="false"
            config[docker_cmd]="docker stop"
            config[docker_compose_cmd]="stop"
            
            # 컨테이너 상태 파라미터
            config[not_found_info]=""
            
            # 모든 컨테이너 액션 메시지
            config[start_msg]="$MSG_STOP_ALL"
            config[result_msg]="$MSG_STOP_ALL_RESULT"
            config[no_containers_msg]="$MSG_NO_RUNNING_CONTAINERS"
            config[spinner_action_text]="$MSG_SPINNER_STOPPING"
            
            # 현재 프로젝트 액션 메시지
            config[project_start_msg]="$MSG_STOP_START"
            config[success_info]="\n${BLUE}$MSG_CONTAINER_STOPPED_INFO${NC}"
            
            # 숫자 인자 메시지
            config[invalid_number_msg]="$MSG_STOP_INVALID_NUMBER"
            
            # this 인자 메시지
            config[not_project_msg]="$MSG_STOP_NOT_PROJECT"
            ;;
            
        *)
            log "ERROR" "$(printf "$MSG_ACTION_NOT_SUPPORTED" "$action")"
            return 1
            ;;
    esac
    
    # 요청된 설정 타입에 따라 결과 반환
    case "$config_type" in
        "basic")
            echo "${config[already_msg_key]}|${config[action_msg_key]}|${config[success_msg_key]}|${config[fail_msg_key]}|${config[check_state]}|${config[docker_cmd]}"
            ;;
        "state")
            echo "${config[check_state]}|${config[already_msg_key]}|${config[not_found_info]}"
            ;;
        "messages")
            echo "${config[action_msg_key]}|${config[success_msg_key]}|${config[fail_msg_key]}|${config[docker_compose_cmd]}|${config[success_info]}"
            ;;
        "all_containers")
            echo "${config[start_msg]}|${config[result_msg]}|${config[no_containers_msg]}|${config[spinner_action_text]}"
            ;;
        "numeric_args")
            echo "${config[invalid_number_msg]}|${config[spinner_action_text]}"
            ;;
        "this_arg")
            echo "${config[not_project_msg]}"
            ;;
        "all") # 기본값: 모든 설정 반환
            # associative array를 문자열로 변환해 반환
            local result=""
            for key in "${!config[@]}"; do
                result+="$key:${config[$key]};"
            done
            echo "$result"
            ;;
        *)
            log "ERROR" "$(printf "$MSG_CONFIG_TYPE_NOT_SUPPORTED" "$config_type")"
            return 1
            ;;
    esac
    
    return 0
}

# 액션별 메시지 및 설정 로드
# Load messages and settings for specific action
load_action_config() {
    local action="$1"
    get_action_config "$action" "basic"
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




# this 인자 처리 함수
# Handle 'this' argument function
handle_this_argument() {
    local action="$1"  # "start" 또는 "stop"
    
    # 액션에 따른 메시지 설정
    local not_project_msg=$(get_action_config "$action" "this_arg")
    
    # 현재 디렉토리가 dockit 프로젝트인지 확인
    # Check if current directory is a dockit project
    if [ -d ".dockit_project" ]; then
        # 액션 시작 메시지 설정 및 출력
        local config=$(get_action_config "$action" "all")
        if [ $? -ne 0 ]; then
            return 1
        fi
        
        # config에서 project_start_msg 추출
        local start_msg=""
        for item in $(echo "$config" | tr ';' '\n'); do
            local key=$(echo "$item" | cut -d':' -f1)
            local value=$(echo "$item" | cut -d':' -f2-)
            
            if [ "$key" = "project_start_msg" ]; then
                start_msg="$value"
                break
            fi
        done
        
        log "INFO" "$start_msg"
        
        if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
            log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
            return 1
        fi
        
        # 설정 로드
        load_env
        
        local check_state=""
        local already_msg=""
        local not_found_info=""
        
        # 상태 관련 설정 가져오기
        local state_config=$(get_action_config "$action" "state")
        if [ $? -ne 0 ]; then
            return 1
        fi
        
        # 설정에서 값 추출
        check_state=$(echo "$state_config" | cut -d'|' -f1)
        already_msg=$(echo "$state_config" | cut -d'|' -f2)
        not_found_info=$(echo "$state_config" | cut -d'|' -f3)
        
        # 컨테이너 존재 여부 확인
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
        if [ "$check_state" = "true" ] && is_container_running "$CONTAINER_NAME"; then
            log "WARNING" "$already_msg"
            return 3
        elif [ "$check_state" = "false" ] && ! is_container_running "$CONTAINER_NAME"; then
            log "WARNING" "$already_msg"
            return 3
        fi
        
        # 액션 메시지 및 명령어 설정
        local action_msg=""
        local success_msg=""
        local fail_msg=""
        local docker_compose_cmd=""
        local success_info=""
        
        # 메시지 관련 설정 가져오기
        local messages_config=$(get_action_config "$action" "messages")
        if [ $? -ne 0 ]; then
            return 1
        fi
        
        # 설정에서 값 추출
        action_msg=$(echo "$messages_config" | cut -d'|' -f1)
        success_msg=$(echo "$messages_config" | cut -d'|' -f2)
        fail_msg=$(echo "$messages_config" | cut -d'|' -f3) 
        docker_compose_cmd=$(echo "$messages_config" | cut -d'|' -f4)
        success_info=$(echo "$messages_config" | cut -d'|' -f5)
        
        # 컨테이너 액션 수행
        log "INFO" "$action_msg"
        if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" $docker_compose_cmd; then
            log "SUCCESS" "$success_msg"
            
            # 성공 후 추가 정보 출력
            if [ -n "$success_info" ]; then
                echo -e "$success_info"
            fi
            return 0
        else
            log "ERROR" "$fail_msg"
            return 1
        fi
    else
        log "WARNING" "$not_project_msg"
    fi
}


# 숫자 인자 처리
handle_numeric_arguments() {
    local action="$1"; shift
    local -a indices=("$@")            # 숫자 인자들만

    # 메시지 설정 가져오기
    local config
    config=$(get_action_config "$action" "numeric_args") || return 1
    local invalid_msg spinner_tpl
    IFS='|' read -r invalid_msg spinner_tpl <<<"$config"

    # 인자 전부 숫자인지 확인
    for idx in "${indices[@]}"; do
        [[ "$idx" =~ ^[0-9]+$ ]] || { log "ERROR" "$(printf "$invalid_msg" "$idx")"; return 1; }
    done

    # 컨테이너 ID 목록 (최근 생성 순서 역순)
    mapfile -t container_ids < <(docker ps -a --filter "label=com.dockit=true" --format "{{.ID}}" | tac)

    # 각 인덱스 처리
    for idx in "${indices[@]}"; do
        local array_idx=$((idx-1))                # 인덱스 → 배열 위치
        local cid=${container_ids[$array_idx]:-}

        if [[ -z "$cid" ]]; then
            log "ERROR" "$(printf "$invalid_msg" "$idx")"
            continue
        fi

        local short=${cid:0:12}
        local name=$(docker inspect --format "{{.Name}}" "$cid" | sed 's/^\///')
        [[ -n "$name" ]] && short="$short ($name)"

        local spinner=$(printf "$MSG_CONTAINER_ACTION_FORMAT" "$short" "$spinner_tpl")

        add_task "$spinner" \
            "perform_container_action \"$action\" \"$cid\" true >/dev/null 2>&1"
    done

    async_tasks "$MSG_TASKS_DONE"
}

# 모든 컨테이너 액션 수행 - 비동기 방식
# Perform action on all containers - async way
perform_all_containers_action() {
    local action="$1"  # "start" 또는 "stop"
    
    # 액션별 메시지 설정 (set_all_containers_action_messages 함수 내용을 직접 통합)
    local config=$(get_action_config "$action" "all_containers")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # 설정에서 값 추출
    local start_msg=$(echo "$config" | cut -d'|' -f1)
    local result_msg=$(echo "$config" | cut -d'|' -f2)
    local no_containers_msg=$(echo "$config" | cut -d'|' -f3)
    local spinner_action_text=$(echo "$config" | cut -d'|' -f4)
    
    log "INFO" "$start_msg"
    
    # 컨테이너 목록 가져오기 (get_containers_for_action 함수 내용을 직접 통합)
    local container_ids=""
    if [ "$action" = "start" ]; then
        container_ids=$(docker ps -a --filter "label=com.dockit=true" --format "{{.ID}}")
    else  # stop
        container_ids=$(docker ps -a --filter "label=com.dockit=true" --filter "status=running" --format "{{.ID}}")
    fi
    
    if [ -z "$container_ids" ]; then
        log "INFO" "$no_containers_msg"
        return 0
    fi
    
    # 결과 저장용 임시 파일
    local temp_result=$(mktemp)
    echo "0 0" > "$temp_result"  # 성공, 실패 카운트 초기화
    
    # 컨테이너 작업 추가
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
    
    # 비동기 작업 실행 (메시지 표시 있음)
    async_tasks "$MSG_TASKS_DONE"
    
    # 결과 처리
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
    
    return 0
}
