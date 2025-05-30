#!/bin/bash

# Registry management module
# 레지스트리 관리 모듈

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 레지스트리 관련 상수 정의 (이미 정의되지 않은 경우에만)
# Registry related constants (only if not already defined)
if [ -z "$REGISTRY_DIR" ]; then
    readonly REGISTRY_DIR="$HOME/.dockit"
fi
if [ -z "$REGISTRY_FILE" ]; then
    readonly REGISTRY_FILE="$REGISTRY_DIR/registry.json"
fi

# 프로젝트 상태 상수 정의 (이미 정의되지 않은 경우에만)
# Project state constants (only if not already defined)
if [ -z "$PROJECT_STATE_RUNNING" ]; then
    readonly PROJECT_STATE_RUNNING="running"    # up 또는 start 후 상태
fi
if [ -z "$PROJECT_STATE_STOPPED" ]; then
    readonly PROJECT_STATE_STOPPED="stopped"    # stop 후 상태
fi
if [ -z "$PROJECT_STATE_UNKNOWN" ]; then
    readonly PROJECT_STATE_UNKNOWN="???"        # 상태를 확인할 수 없는 경우
fi

# 프로젝트 ID 생성 함수
# Function to generate project ID
generate_project_id() {
    local uuid_timestamp
    uuid_timestamp="$(uuidgen)-$(date +%Y%m%dT%H%M%S.%6N)"
    echo "$uuid_timestamp" | sha256sum | cut -d ' ' -f 1
}

# 레지스트리 디렉토리 확인 및 생성
# Check and create registry directory
ensure_registry_dir() {
    if [ ! -d "$REGISTRY_DIR" ]; then
        log "INFO" "$MSG_REGISTRY_CREATING_DIR"
        mkdir -p "$REGISTRY_DIR"
        log "SUCCESS" "$MSG_REGISTRY_DIR_CREATED"
    fi
}

# 레지스트리 파일 초기화
# Initialize registry file
ensure_registry_file() {
    if [ ! -f "$REGISTRY_FILE" ]; then
        log "INFO" "$MSG_REGISTRY_INITIALIZING"
        echo '{}' > "$REGISTRY_FILE"
        log "SUCCESS" "$MSG_REGISTRY_INITIALIZED"
    fi
}

# 레지스트리 로드 함수
# Load registry function
load_registry() {
    local cleanup_flag="${1:-no_cleanup}"
    
    ensure_registry_dir
    ensure_registry_file
    
    # 필요한 경우 레지스트리 정리
    # Clean up registry if needed
    if [ "$cleanup_flag" = "with_cleanup" ]; then
        cleanup_registry
    fi
    
    # 레지스트리 내용 반환
    # Return registry contents
    cat "$REGISTRY_FILE"
}

# 프로젝트 경로 유효성 검사
# Validate project path
is_valid_project() {
    local project_path="$1"
    local project_id="$2"
    
    # 프로젝트 경로가 존재하는지 확인
    # Check if project path exists
    if [ ! -d "$project_path" ]; then
        return 1  # 경로가 존재하지 않음
    fi
    
    # .dockit_project/id 파일이 존재하는지 확인
    # Check if .dockit_project/id file exists
    if [ ! -f "$project_path/.dockit_project/id" ]; then
        return 1  # id 파일이 존재하지 않음 
    fi
    
    # 프로젝트 ID가 제공된 경우, ID 일치 여부 확인
    # If project ID is provided, check if it matches
    if [ -n "$project_id" ]; then
        local file_id
        file_id=$(cat "$project_path/.dockit_project/id")
        
        if [ "$file_id" != "$project_id" ]; then
            return 1  # ID가 일치하지 않음
        fi
    fi
    
    return 0  # 유효한 프로젝트
}

# 레지스트리 정리 함수
# Clean up registry function
cleanup_registry() {
    log "INFO" "$MSG_REGISTRY_CLEANING"
    
    # 레지스트리 파일 존재 확인
    # Check if registry file exists
    if [ ! -f "$REGISTRY_FILE" ]; then
        log "INFO" "$MSG_REGISTRY_INITIALIZING"
        echo '{}' > "$REGISTRY_FILE"
        log "SUCCESS" "$MSG_REGISTRY_INITIALIZED"
        return 0
    fi
    
    # 임시 파일 생성
    # Create temporary file
    local temp_file
    temp_file="$(mktemp)"
    
    # jq를 사용하여 유효하지 않은 항목 필터링
    # Filter invalid entries using jq
    if command -v jq &> /dev/null; then
        local removed_count=0
        local total_count=0
        
        # jq 스크립트를 통해 유효한 항목만 새 객체로 구성
        # Create new object with only valid entries through jq script
        jq -r 'to_entries | .[] | .key + ":" + .value.path' "$REGISTRY_FILE" | while read -r line; do
            total_count=$((total_count + 1))
            
            local id="${line%%:*}"
            local path="${line#*:}"
            
            if is_valid_project "$path" "$id"; then
                # 유효한 프로젝트는 유지
                # Keep valid projects
                :
            else
                # 유효하지 않은 프로젝트는 제거
                # Remove invalid projects
                removed_count=$((removed_count + 1))
                log "INFO" "$(printf "$MSG_REGISTRY_REMOVING_INVALID" "$path")"
                
                # jq를 사용하여 해당 항목 제거
                # Remove the entry using jq
                jq "del(.[\"$id\"])" "$REGISTRY_FILE" > "$temp_file" && mv "$temp_file" "$REGISTRY_FILE"
            fi
        done
        
        log "SUCCESS" "$(printf "$MSG_REGISTRY_CLEANUP_COMPLETE" "$removed_count" "$total_count")"
    else
        # jq 없이 처리 (기본 구현, jq가 있는 경우보다 덜 효율적)
        # Handle without jq (basic implementation, less efficient than with jq)
        log "WARNING" "$MSG_REGISTRY_JQ_NOT_FOUND"
        log "INFO" "$MSG_REGISTRY_MANUAL_CLEANUP"
        
        # grep, sed 등을 사용한 대체 구현 가능
        # Alternative implementation using grep, sed, etc. is possible
        # 여기서는 단순화를 위해 생략
        # Omitted here for simplicity
    fi
}

# 프로젝트 ID 생성 및 저장
# Generate and save project ID
generate_and_save_project_id() {
    local project_dir="${1:-.dockit_project}"
    local project_id=$(generate_project_id)
    
    # 프로젝트 디렉토리 확인
    # Check project directory
    if [ ! -d "$project_dir" ]; then
        mkdir -p "$project_dir"
    fi
    
    echo "$project_id" > "$project_dir/id"
    log "INFO" "$(printf "$MSG_REGISTRY_ID_GENERATED" "${project_id:0:12}...")" >&2
    echo "$project_id"  # Return only project ID
}

# jq를 사용하여 레지스트리에 프로젝트 추가
# Add project to registry using jq
add_project_with_jq() {
    local project_id="$1"
    local project_path="$2"
    local created_time="$3"
    local state="${4:-$PROJECT_STATE_DOWN}"
    
    local temp_file=$(mktemp)
    
    jq --arg id "$project_id" \
       --arg path "$project_path" \
       --argjson created "$created_time" \
       --arg state "$state" \
       --argjson last_seen "$created_time" \
       '.[$id] = {"path": $path, "created": $created, "state": $state, "last_seen": $last_seen}' \
       "$REGISTRY_FILE" > "$temp_file" && mv "$temp_file" "$REGISTRY_FILE"
}

# jq 없이 레지스트리에 프로젝트 추가
# Add project to registry without jq
add_project_without_jq() {
    local project_id="$1"
    local project_path="$2"
    local created_time="$3"
    local state="${4:-$PROJECT_STATE_DOWN}"
    
    local registry_content=$(cat "$REGISTRY_FILE")
    
    # 기존 JSON이 비어있지 않은 경우 콤마 추가
    # Add comma if existing JSON is not empty
    if [ "$registry_content" != "{}" ]; then
        registry_content="${registry_content%?},"
    else
        registry_content="{"
    fi
    
    # 새 항목 추가
    # Add new entry
    registry_content+="\n  \"$project_id\": {\n    \"path\": \"$project_path\",\n    \"created\": $created_time,\n    \"state\": \"$state\",\n    \"last_seen\": $created_time\n  }\n}"
    
    # 업데이트된 내용 저장
    # Save updated content
    echo "$registry_content" > "$REGISTRY_FILE"
}

# 레지스트리에 프로젝트 추가
# Add project to registry
add_project_to_registry() {
    local project_id="$1"
    local project_path="$2"
    local created_time="$3"
    local state="${4:-$PROJECT_STATE_DOWN}"
    
    log "INFO" "$MSG_REGISTRY_ADDING_PROJECT"
    
    if command -v jq &> /dev/null; then
        add_project_with_jq "$project_id" "$project_path" "$created_time" "$state"
    else
        add_project_without_jq "$project_id" "$project_path" "$created_time" "$state"
    fi
    
    log "SUCCESS" "$MSG_REGISTRY_PROJECT_ADDED"
}

# 프로젝트 상태 업데이트
# Update project state
update_project_state() {
    local project_id="$1"
    local new_state="$2"
    
    if [ ! -f "$REGISTRY_FILE" ]; then
        log "ERROR" "$MSG_REGISTRY_FILE_NOT_FOUND"
        return 1
    fi
    
    # 임시 파일 생성
    # Create temporary file
    local temp_file
    temp_file="$(mktemp)"
    
    # jq를 사용하여 상태 업데이트
    # Update state using jq
    if command -v jq &> /dev/null; then
        jq --arg id "$project_id" \
           --arg state "$new_state" \
           --argjson last_seen "$(date +%s)" \
           'if has($id) then .[$id].state = $state | .[$id].last_seen = $last_seen else . end' \
           "$REGISTRY_FILE" > "$temp_file" && mv "$temp_file" "$REGISTRY_FILE"
    else
        # jq 없이 처리 (기본 구현)
        # Handle without jq (basic implementation)
        log "WARNING" "$MSG_REGISTRY_JQ_NOT_FOUND"
        log "INFO" "$MSG_REGISTRY_MANUAL_UPDATE"
        
        # grep, sed 등을 사용한 대체 구현 가능
        # Alternative implementation using grep, sed, etc. is possible
        # 여기서는 단순화를 위해 생략
        # Omitted here for simplicity
    fi
}

# Function to handle project ID synchronization
# 프로젝트 ID 동기화 처리 함수
handle_project_id_sync() {
    local project_path="$1"
    
    # Check if .dockit_project/id exists
    if [ ! -f "$project_path/.dockit_project/id" ]; then
        return 1
    fi
    
    # Read existing project ID
    local project_id=$(cat "$project_path/.dockit_project/id")
    
    # Load registry
    local registry_json=$(cat "$REGISTRY_FILE")
    
    # Check conditions for issuing new ID
    local needs_new_id=0
    
    # Check if ID exists in registry
    if ! echo "$registry_json" | jq -e --arg id "$project_id" 'has($id)' > /dev/null; then
        # ID not in registry - project was copied or restored
        needs_new_id=1
    else
        # ID exists in registry - check if path matches
        local registered_path=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
        if [ "$registered_path" != "$project_path" ]; then
            # Path mismatch - project was copied
            needs_new_id=1
        fi
    fi
    
    # Generate new ID if needed
    if [ $needs_new_id -eq 1 ]; then
        # Generate and save new project ID
        local new_project_id=$(generate_and_save_project_id "$project_path/.dockit_project")
        
        # Add project to registry with new ID
        local current_time=$(date +%s)
        add_project_to_registry "$new_project_id" "$project_path" "$current_time" "$PROJECT_STATE_DOWN"
        
        return 0
    fi
    
    return 1
}

# 레지스트리 초기화 함수
# Registry initialization function
init_registry() {
    # 레지스트리 디렉토리 및 파일 확인
    # Ensure registry directory and file exist
    ensure_registry_dir
    ensure_registry_file
    
    # 프로젝트 ID 생성 및 저장
    # Generate and save project ID
    local project_id=$(generate_and_save_project_id)
    
    # 현재 프로젝트 경로
    # Current project path
    local project_path="$(pwd)"
    
    # 현재 시간 (Unix timestamp)
    # Current time (Unix timestamp)
    local created_time=$(date +%s)
    
    # 레지스트리에 프로젝트 추가
    # Add project to registry
    add_project_to_registry "$project_id" "$project_path" "$created_time" "$PROJECT_STATE_NONE"
}

# 레지스트리 메인 함수
# Registry main function
registry_main() {
    local action="$1"
    shift
    
    case "$action" in
        init)
            init_registry "$@"
            ;;
        cleanup)
            cleanup_registry "$@"
            ;;
        update)
            update_project_state "$@"
            ;;
        sync)
            handle_project_id_sync "$@"
            ;;
        *)
            log "ERROR" "$(printf "$MSG_ACTION_NOT_SUPPORTED" "$action")"
            return 1
            ;;
    esac
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    registry_main "$@"
fi
