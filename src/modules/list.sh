#!/bin/bash

# List module - Show registered dockit projects from registry
# list 모듈 - 레지스트리에서 등록된 dockit 프로젝트 표시

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$UTILS_DIR/async_tasks.sh"
source "$MODULES_DIR/registry.sh"

# Function to format time elapsed since last update
# 마지막 업데이트 이후 경과 시간을 형식화하는 함수
format_time_elapsed() {
    local timestamp="$1"
    local now=$(date +%s)
    local elapsed=$((now - timestamp))
    
    if [ $elapsed -lt 60 ]; then
        echo "${elapsed}s ago"
    elif [ $elapsed -lt 3600 ]; then
        local minutes=$((elapsed / 60))
        echo "${minutes}m ago"
    elif [ $elapsed -lt 86400 ]; then
        local hours=$((elapsed / 3600))
        echo "${hours}h ago"
    else
        local days=$((elapsed / 86400))
        echo "${days}d ago"
    fi
}

# Function to format path with ~ shorthand
# 경로를 ~ 약식으로 형식화하는 함수
format_path() {
    local path="$1"
    echo "$path" | sed "s|$HOME|~|"
}

# Function to check if a project path is valid
# 프로젝트 경로가 유효한지 확인하는 함수
is_path_valid() {
    local path="$1"
    
    if [ ! -d "$path" ] || [ ! -f "$path/.dockit_project/id" ]; then
        return 1
    fi
    
    return 0
}

# Function to get short ID (first 12 characters)
# 짧은 ID를 가져오는 함수 (처음 12자)
get_short_id() {
    local id="$1"
    echo "${id:0:12}"
}

# Function to check for ID collisions
# ID 충돌을 확인하는 함수
check_id_collision() {
    local registry="$1"
    local short_ids=()
    local full_ids=()
    
    # Extract all IDs from registry
    while IFS= read -r id; do
        full_ids+=("$id")
        short_ids+=("${id:0:12}")
    done < <(echo "$registry" | jq -r 'keys[]')
    
    # Check for collisions
    local collision_ids=()
    for i in "${!short_ids[@]}"; do
        for j in "${!short_ids[@]}"; do
            if [ $i -ne $j ] && [ "${short_ids[$i]}" = "${short_ids[$j]}" ]; then
                if ! [[ " ${collision_ids[@]} " =~ " ${full_ids[$i]} " ]]; then
                    collision_ids+=("${full_ids[$i]}")
                fi
                if ! [[ " ${collision_ids[@]} " =~ " ${full_ids[$j]} " ]]; then
                    collision_ids+=("${full_ids[$j]}")
                fi
            fi
        done
    done
    
    echo "${collision_ids[@]}"
}

# Function to get status display text
# 상태 표시 텍스트를 가져오는 함수
get_status_display() {
    local status="$1"

    case "$status" in
        "running")
            echo -e "${GREEN}running${NC}"
            ;;
        "stopped")
            echo -e "${YELLOW}stopped${NC}"
            ;;
        "down")
            echo -e "${GRAY}down${NC}"
            ;;
        "none")
            echo -e "${BLUE}none${NC}"
            ;;
        "ready")
            echo -e "${CYAN}ready${NC}"
            ;;
        "error")
            echo -e "${RED}error${NC}"
            ;;
        *)
            echo -e "${PURPLE}???${NC}"
            ;;
    esac
}

# Function to get status text length (without color codes)
# 색상 코드를 제외한 상태 텍스트 길이를 가져오는 함수
get_status_text_length() {
    local status="$1"
    
    case "$status" in
        "running"|"stopped")
            echo 7  # "running" or "stopped" length
            ;;
        "ready"|"error")
            echo 5  # "ready" or "error" length
            ;;
        "down"|"none")
            echo 4  # "down" or "none" length
            ;;
        *)
            echo 3  # "???" length
            ;;
    esac
}

# Function to pad status display for proper alignment
# 상태 표시를 올바른 정렬을 위해 패딩하는 함수
format_status_display() {
    local status="$1"
    local status_display=$(get_status_display "$status")
    local text_length=$(get_status_text_length "$status")
    local target_width=8
    local padding=$((target_width - text_length))
    
    # Add padding spaces after the colored text
    printf "%s%*s" "$status_display" "$padding" ""
}

# Function to get project Docker information (image name, container name)
# 프로젝트의 Docker 정보 가져오기 (이미지명, 컨테이너명)
get_project_docker_info() {
    local project_path="$1"
    local -n image_ref=$2
    local -n container_ref=$3
    
    local env_file="$project_path/.dockit_project/.env"
    if [ ! -f "$env_file" ]; then
        return 1
    fi
    
    # .env 파일에서 IMAGE_NAME과 CONTAINER_NAME 추출
    image_ref=$(grep "^IMAGE_NAME=" "$env_file" | cut -d'=' -f2 | sed 's/^"\|"$//g')
    container_ref=$(grep "^CONTAINER_NAME=" "$env_file" | cut -d'=' -f2 | sed 's/^"\|"$//g')
    
    if [ -z "$image_ref" ] || [ -z "$container_ref" ]; then
        return 1
    fi
    
    return 0
}

# Function to get actual Docker state for a project
# 프로젝트의 실제 Docker 상태 확인
get_actual_docker_state() {
    local image_name="$1"
    local container_name="$2"
    
    # 이미지 존재 여부 확인
    local image_exists=false
    if docker image inspect "$image_name" >/dev/null 2>&1; then
        image_exists=true
    fi
    
    # 컨테이너 존재 여부 및 상태 확인
    local container_exists=false
    local container_running=false
    
    if docker container inspect "$container_name" >/dev/null 2>&1; then
        container_exists=true
        if [ "$(docker container inspect -f '{{.State.Running}}' "$container_name")" = "true" ]; then
            container_running=true
        fi
    fi
    
    # 상태 결정 로직
    if [ "$container_running" = true ]; then
        echo "running"
    elif [ "$container_exists" = true ]; then
        echo "stopped"
    elif [ "$image_exists" = true ]; then
        echo "ready"
    else
        echo "none"
    fi
}

# Function to sync registry state with actual Docker status
# 레지스트리 상태를 실제 Docker 상태와 동기화
sync_with_docker_status() {
    # Docker 사용 가능 여부 확인
    if ! command -v docker &> /dev/null; then
        return 0
    fi
    
    # 레지스트리 파일 확인
    if [ ! -f "$REGISTRY_FILE" ]; then
        return 0
    fi
    
    local registry_json=$(cat "$REGISTRY_FILE")
    local updated=false
    
    # 각 프로젝트의 실제 Docker 상태 확인 및 업데이트
    while IFS= read -r project_id; do
        local path=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
        local current_state=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].state')
        
        # 프로젝트 경로가 유효하지 않으면 건너뛰기
        if [ ! -d "$path" ] || [ ! -f "$path/.dockit_project/.env" ]; then
            continue
        fi
        
        # .env 파일에서 이미지명과 컨테이너명 로드
        local image_name container_name
        if ! get_project_docker_info "$path" image_name container_name; then
            continue
        fi
        
        # 실제 Docker 상태 확인
        local actual_state
        actual_state=$(get_actual_docker_state "$image_name" "$container_name")
        
        # 상태가 다르면 업데이트 (error 상태는 수동으로만 변경)
        if [ "$current_state" != "$actual_state" ] && [ "$current_state" != "error" ]; then
            update_project_status "$project_id" "$actual_state"
            updated=true
        fi
    done < <(echo "$registry_json" | jq -r 'keys[]')
    
    return 0
}

# Main function for listing registered projects
# 등록된 프로젝트 목록 표시를 위한 메인 함수
list_main() {
    # Load registry with cleanup (removes invalid entries)
    load_registry "with_cleanup" > /dev/null 2>&1
    
    # 현재 디렉토리에서 프로젝트 ID 동기화 시도
    # Try to synchronize project ID in current directory
    if [ -d ".dockit_project" ] && [ -f ".dockit_project/id" ]; then
        handle_project_id_sync "$(pwd)" > /dev/null 2>&1
    fi
    
    # 레지스트리 파일 직접 로드
    # Directly load registry file
    if [ ! -f "$REGISTRY_FILE" ]; then
        echo '{}' > "$REGISTRY_FILE"
    fi
    
    # 실시간 Docker 상태와 레지스트리 동기화
    # Sync registry with real-time Docker status
    sync_with_docker_status > /dev/null 2>&1
    
    local registry_json=$(cat "$REGISTRY_FILE")
    
    # Check if registry is empty
    local project_count=$(echo "$registry_json" | jq -r 'length')
    if [ -z "$project_count" ] || [ "$project_count" = "null" ]; then
        project_count=0
    fi
    
    if [ "$project_count" -eq 0 ]; then
        echo -e "$(get_message MSG_PROJECT_LIST_NO_PROJECTS)"
        echo ""
        echo "$(get_message MSG_PROJECT_LIST_HINT_INIT)"
        echo "  dockit init"
        return 0
    fi
    
    # Check for ID collisions
    local collision_ids=$(check_id_collision "$registry_json")
    
    # Format and display header
    echo -e "$(printf "$(get_message MSG_PROJECT_LIST_HEADER)" "$project_count")"
    echo ""
    
    # Format strings - STATUS 컬럼을 더 넓게 설정 (색상 코드 고려)
    local format="%-4s  %-12s  %-8s  %-11s  %s\n"
    
    # Print header
    printf "$format" \
        "NO" \
        "PID" \
        "STATUS" \
        "LAST SEEN" \
        "PATH"
    
    # Create temporary file for output
    local temp_file=$(mktemp)
    
    # Process each project entry
    local index=1
    while IFS= read -r id; do
        local path=$(echo "$registry_json" | jq -r --arg id "$id" '.[$id].path')
        local created=$(echo "$registry_json" | jq -r --arg id "$id" '.[$id].created')
        local state=$(echo "$registry_json" | jq -r --arg id "$id" '.[$id].state')
        local last_seen=$(echo "$registry_json" | jq -r --arg id "$id" 'if .[$id] | has("last_seen") then .[$id].last_seen else .[$id].created end')
        
        # 경로가 존재하면 ID 동기화 시도
        # Try ID synchronization if path exists
        if [ -d "$path" ] && [ -f "$path/.dockit_project/id" ]; then
            handle_project_id_sync "$path" > /dev/null 2>&1
        fi
        
        # Check if path exists
        local path_display
        if is_path_valid "$path"; then
            path_display=$(format_path "$path")
        else
            path_display="$(format_path "$path")   ${RED}$(get_message MSG_PROJECT_LIST_PATH_NOT_FOUND)${NC}"
        fi
        
        # Format ID (use full ID if in collision list)
        local id_display
        if [[ " $collision_ids " =~ " $id " ]]; then
            id_display="$id"
        else
            id_display=$(get_short_id "$id")
        fi
        
        # Format last seen time
        local last_seen_display=$(format_time_elapsed "$last_seen")
        
        # Get status display with proper formatting
        local status_display=$(format_status_display "$state")
        
        # Write to temporary file
        printf "$format" \
            "$index" \
            "$id_display" \
            "$status_display" \
            "$last_seen_display" \
            "$path_display" >> "$temp_file"
        
        ((index++))
    done < <(echo "$registry_json" | jq -r 'keys[]')
    
    # Print collected output with color support
    while IFS= read -r line; do
        echo -e "$line"
    done < "$temp_file"
    
    # Remove temporary file
    rm -f "$temp_file"
    
    # Print hints
    echo ""
    echo "$(get_message MSG_PROJECT_LIST_HINT_PS)"
    echo "$(get_message MSG_PROJECT_LIST_HINT_INIT)"
}

# Update project status information
# 프로젝트 상태 정보 업데이트
update_project_status() {
    local project_id="$1"
    local new_state="$2"
    local timestamp=$(date +%s)
    
    # Update state and last_seen
    if command -v jq &> /dev/null; then
        local temp_file=$(mktemp)
        jq --arg id "$project_id" \
           --arg state "$new_state" \
           --argjson last_seen "$timestamp" \
           'if has($id) then .[$id].state = $state | .[$id].last_seen = $last_seen else . end' \
           "$REGISTRY_FILE" > "$temp_file" && mv "$temp_file" "$REGISTRY_FILE"
    else
        # Fallback for systems without jq (simplified)
        log "WARNING" "$MSG_REGISTRY_JQ_NOT_FOUND"
    fi
}

# Function to handle project ID synchronization
# 프로젝트 ID 동기화 처리 함수
handle_project_id_sync() {
    local project_path="$1"

    if [ ! -f "$project_path/.dockit_project/id" ]; then
        return 1
    fi

    local project_id=$(cat "$project_path/.dockit_project/id")
    local registry_json=$(cat "$REGISTRY_FILE")

    local already_registered=$(echo "$registry_json" | jq -r --arg path "$project_path" 'to_entries[] | select(.value.path == $path) | .key')
    if [ -n "$already_registered" ]; then
        return 0
    fi

    local needs_new_id=0
    if ! echo "$registry_json" | jq -e --arg id "$project_id" 'has($id)' > /dev/null; then
        needs_new_id=1
    else
        local registered_path=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
        if [ "$registered_path" != "$project_path" ]; then
            needs_new_id=1
        fi
    fi

    if [ $needs_new_id -eq 1 ]; then
        local new_project_id=$(generate_and_save_project_id "$project_path/.dockit_project")
        local current_time=$(date +%s)
        add_project_to_registry "$new_project_id" "$project_path" "$current_time" "$PROJECT_STATE_DOWN"
        return 0
    fi

    return 1
}

# Run main function if this script is called directly
# 이 스크립트가 직접 호출될 경우 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    list_main "$@"
fi 