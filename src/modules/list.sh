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

# Performance optimization: Cache local Docker images and container states
# 성능 최적화: 로컬 Docker 이미지와 컨테이너 상태 캐시

# Advanced Performance: State-based intelligent management
# 고급 성능 최적화: 상태 기반 지능형 관리
readonly CACHE_DIR="$HOME/.dockit/cache"
readonly INIT_STATE_FILE="$CACHE_DIR/init_state"
readonly DOCKER_SNAPSHOT_FILE="$CACHE_DIR/docker_snapshot"

# Asynchronous Background Initialization System
# 비동기 백그라운드 초기화 시스템
readonly BACKGROUND_LOCK_FILE="$CACHE_DIR/background.lock"
readonly BACKGROUND_PID_FILE="$CACHE_DIR/background.pid"
readonly BACKGROUND_STATUS_FILE="$CACHE_DIR/background_status"
readonly BACKGROUND_COMPLETE_FILE="$CACHE_DIR/background_complete"

# Global cache variables
# 전역 캐시 변수
declare -a LOCAL_DOCKIT_IMAGES_CACHE=()
declare -A CONTAINER_STATES_CACHE=()
declare LOCAL_IMAGES_LOADED=0

# State management functions for advanced performance optimization
# 고급 성능 최적화를 위한 상태 관리 함수들

# Ensure cache directory exists
# 캐시 디렉토리 생성 확인
ensure_cache_directory() {
    [ ! -d "$CACHE_DIR" ] && mkdir -p "$CACHE_DIR"
}

# Check if list system is initialized
# 리스트 시스템 초기화 상태 확인
is_list_initialized() {
    [ -f "$INIT_STATE_FILE" ] && [ "$(cat "$INIT_STATE_FILE" 2>/dev/null)" = "true" ]
}

# Set list system as initialized
# 리스트 시스템 초기화 상태 설정
set_list_initialized() {
    ensure_cache_directory
    echo "true" > "$INIT_STATE_FILE"
}

# Check if Docker state has changed since last snapshot
# 마지막 스냅샷 이후 Docker 상태 변경 확인
has_docker_state_changed() {
    local current_docker_images=$(docker image ls -a --format "{{.Repository}}" 2>/dev/null | grep "^dockit-" | sort)
    local cached_docker_images=""
    
    if [ -f "$DOCKER_SNAPSHOT_FILE" ]; then
        cached_docker_images=$(cat "$DOCKER_SNAPSHOT_FILE" 2>/dev/null)
    fi
    
    if [ "$current_docker_images" != "$cached_docker_images" ]; then
        # Save new snapshot
        # 새로운 스냅샷 저장
        ensure_cache_directory
        echo "$current_docker_images" > "$DOCKER_SNAPSHOT_FILE"
        return 0  # Changed
    fi
    
    return 1  # Not changed
}

# Smart sync decision - enhanced version of should_sync_docker_status
# 스마트 동기화 결정 - should_sync_docker_status의 향상된 버전
should_perform_smart_sync() {
    # 초기화되지 않았다면 전체 동기화 필요
    if ! is_list_initialized; then
        return 0  # Full sync needed
    fi
    
    # Docker 상태가 변경되었다면 동기화 필요
    if has_docker_state_changed; then
        return 0  # Sync needed
    fi
    
    return 1  # No sync needed - use quick mode
}

# ========================================================================================
# Asynchronous Background Initialization System
# 비동기 백그라운드 초기화 시스템
# ========================================================================================

# Check if background initialization is currently running
# 백그라운드 초기화가 현재 실행 중인지 확인
is_background_init_running() {
    if [ -f "$BACKGROUND_LOCK_FILE" ] && [ -f "$BACKGROUND_PID_FILE" ]; then
        local bg_pid=$(cat "$BACKGROUND_PID_FILE" 2>/dev/null)
        if [ -n "$bg_pid" ] && kill -0 "$bg_pid" 2>/dev/null; then
            return 0  # Running
        else
            # Cleanup stale lock files
            rm -f "$BACKGROUND_LOCK_FILE" "$BACKGROUND_PID_FILE" 2>/dev/null
            return 1  # Not running
        fi
    fi
    return 1  # Not running
}

# Check if background initialization has completed successfully
# 백그라운드 초기화가 성공적으로 완료되었는지 확인
is_background_init_complete() {
    [ -f "$BACKGROUND_COMPLETE_FILE" ] && [ "$(cat "$BACKGROUND_COMPLETE_FILE" 2>/dev/null)" = "true" ]
}

# Show light mode list with immediate response
# 즉시 응답하는 가벼운 모드 리스트 표시
show_light_mode_list() {
    echo "등록된 프로젝트 (조회 중...)"
    echo ""
    
    # Try to show cached registry info if available
    # 캐시된 레지스트리 정보가 있으면 표시
    local registry_file="$DOCKIT_CONFIG_DIR/registry.json"
    local temp_list_file="/tmp/dockit_light_list.$$"
    
    if [ -f "$registry_file" ]; then
        # Show basic project info from cached registry
        # 캐시된 레지스트리에서 기본 프로젝트 정보 표시
        echo "NO    PID           STATUS         LAST SEEN    PATH"
        local count=0
        while IFS= read -r line; do
            if [ -n "$line" ] && [ "$line" != "null" ]; then
                count=$((count + 1))
                local path=$(echo "$line" | jq -r '.path // empty')
                local container_name=$(echo "$line" | jq -r '.container_name // empty')
                
                if [ -n "$path" ] && [ -n "$container_name" ]; then
                    local short_id=${container_name:0:12}
                    local formatted_path=$(format_path "$path")
                    printf "%-5s %-13s %s%-10s%s %s%-8s%s   %s\n" \
                        "$count" "$short_id" "${CYAN}" "updating..." "${NC}" \
                        "${GRAY}" "..." "${NC}" "$formatted_path"
                fi
            fi
        done < <(jq -c '.[]?' "$registry_file" 2>/dev/null)
        
        if [ $count -eq 0 ]; then
            echo "등록된 프로젝트가 없습니다."
        else
            echo ""
            echo "📋 기본 정보 표시 중... 백그라운드에서 최신 상태를 확인하고 있습니다."
        fi
    else
        echo "등록된 프로젝트가 없습니다."
        echo ""
        echo "🔄 처음 실행입니다. 백그라운드에서 프로젝트를 검색하고 있습니다..."
    fi
    
    echo ""
    echo "📌 컨테이너 상태를 확인하려면:  dockit ps"
    echo "📌 새 프로젝트를 만들려면:     dockit init"
}

# Initialize all heavy operations in background asynchronously
# 모든 무거운 작업을 백그라운드에서 비동기로 초기화
initialize_background_async() {
    # Prevent multiple background processes
    # 다중 백그라운드 프로세스 방지
    if is_background_init_running; then
        return 0
    fi
    
    # Start background initialization
    # 백그라운드 초기화 시작
    (
        # Create lock file with current PID
        ensure_cache_directory
        echo $$ > "$BACKGROUND_PID_FILE"
        touch "$BACKGROUND_LOCK_FILE"
        echo "initializing" > "$BACKGROUND_STATUS_FILE"
        
        # Remove completion marker to indicate work in progress
        rm -f "$BACKGROUND_COMPLETE_FILE" 2>/dev/null
        
        # Redirect all output to avoid interfering with main process
        # 메인 프로세스 방해를 피하기 위해 모든 출력을 리디렉션
        exec >/dev/null 2>&1
        
        # Set trap to cleanup on exit
        trap 'rm -f "$BACKGROUND_LOCK_FILE" "$BACKGROUND_PID_FILE" "$BACKGROUND_STATUS_FILE" 2>/dev/null' EXIT
        
        # Perform all heavy operations sequentially
        # 모든 무거운 작업을 순차적으로 수행
        echo "docker_images" > "$BACKGROUND_STATUS_FILE"
        get_local_dockit_images >/dev/null
        
        echo "container_states" > "$BACKGROUND_STATUS_FILE"  
        get_batch_container_states >/dev/null
        
        echo "registry_sync" > "$BACKGROUND_STATUS_FILE"
        load_registry "with_cleanup" >/dev/null
        
        echo "docker_sync" > "$BACKGROUND_STATUS_FILE"
        sync_with_docker_status >/dev/null
        
        echo "project_discovery" > "$BACKGROUND_STATUS_FILE"
        discover_and_register_projects >/dev/null
        
        # Mark system as fully initialized
        echo "finalizing" > "$BACKGROUND_STATUS_FILE"
        set_list_initialized "true"
        echo "true" > "$BACKGROUND_COMPLETE_FILE"
        
        # Cleanup background files
        rm -f "$BACKGROUND_LOCK_FILE" "$BACKGROUND_PID_FILE" "$BACKGROUND_STATUS_FILE" 2>/dev/null
        
    ) &
    
    # Return immediately after starting background process
    # 백그라운드 프로세스 시작 후 즉시 반환
    return 0
}

# Function to get all local dockit images at once
# 로컬 dockit 이미지를 한 번에 모두 가져오는 함수
get_local_dockit_images() {
    # Return cached result if already loaded
    # 이미 로드된 경우 캐시된 결과 반환
    if [ $LOCAL_IMAGES_LOADED -eq 1 ]; then
        printf '%s\n' "${LOCAL_DOCKIT_IMAGES_CACHE[@]}"
        return 0
    fi
    
    # Load images from Docker
    # Docker에서 이미지 로드
    if command -v docker &> /dev/null; then
        local images
        images=$(docker image ls -a --format "{{.Repository}}" 2>/dev/null | grep "^dockit-" || echo "")
        
        # Store in cache
        # 캐시에 저장
        LOCAL_DOCKIT_IMAGES_CACHE=()
        while IFS= read -r image; do
            [ -n "$image" ] && LOCAL_DOCKIT_IMAGES_CACHE+=("$image")
        done <<< "$images"
        
        LOCAL_IMAGES_LOADED=1
        printf '%s\n' "${LOCAL_DOCKIT_IMAGES_CACHE[@]}"
    fi
}

# Function to check if image exists in cache
# 캐시에서 이미지 존재 여부 확인하는 함수
image_exists_in_cache() {
    local image_name="$1"
    
    # Ensure cache is loaded
    # 캐시가 로드되었는지 확인
    if [ $LOCAL_IMAGES_LOADED -eq 0 ]; then
        get_local_dockit_images > /dev/null
    fi
    
    # Check if image exists in cache
    # 캐시에서 이미지 존재 확인
    local i
    for i in "${LOCAL_DOCKIT_IMAGES_CACHE[@]}"; do
        if [ "$i" = "$image_name" ]; then
            return 0
        fi
    done
    return 1
}

# Function to get all container states at once
# 모든 컨테이너 상태를 한 번에 가져오는 함수
get_batch_container_states() {
    # Clear existing cache
    # 기존 캐시 클리어
    CONTAINER_STATES_CACHE=()
    
    if command -v docker &> /dev/null; then
        # Get all dockit containers with their states
        # 모든 dockit 컨테이너와 상태 가져오기
        local container_info
        container_info=$(docker container ls -a --filter "name=dockit-" --format "{{.Names}}:{{.State}}" 2>/dev/null || echo "")
        
        # Parse and store in associative array
        # 연관 배열에 파싱하여 저장
        while IFS=':' read -r name state; do
            if [ -n "$name" ] && [ -n "$state" ]; then
                if [ "$state" = "running" ]; then
                    CONTAINER_STATES_CACHE["$name"]="running"
                else
                    CONTAINER_STATES_CACHE["$name"]="stopped"
                fi
            fi
        done <<< "$container_info"
    fi
}

# Function to get container state from cache
# 캐시에서 컨테이너 상태 가져오는 함수
get_container_state_from_cache() {
    local container_name="$1"
    echo "${CONTAINER_STATES_CACHE[$container_name]:-not_found}"
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

# Function to get actual Docker state for a project (optimized with cache)
# 프로젝트의 실제 Docker 상태 확인 (캐시로 최적화됨)
get_actual_docker_state() {
    local image_name="$1"
    local container_name="$2"
    
    # Direct real-time Docker state check - no cache dependency
    # 직접 실시간 Docker 상태 확인 - 캐시 의존성 없음
    
    # First check container state directly
    # 먼저 컨테이너 상태를 직접 확인
    local container_state=""
    if command -v docker &> /dev/null; then
        container_state=$(docker container inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null || echo "not_found")
    fi
    
    # Return container state if found and running
    # 컨테이너를 찾았고 실행 중이면 상태 반환
    if [ "$container_state" = "running" ]; then
        echo "running"
        return
    elif [ "$container_state" = "exited" ] || [ "$container_state" = "stopped" ]; then
        echo "stopped"
        return
    fi
    
    # If container not found, check if image exists directly
    # 컨테이너를 찾지 못하면 이미지 존재 여부를 직접 확인
    local image_exists=false
    if command -v docker &> /dev/null; then
        if docker image inspect "$image_name" &>/dev/null; then
            image_exists=true
        fi
    fi
    
    if [ "$image_exists" = true ]; then
        echo "ready"
    else
        echo "none"
    fi
}

# Function to check if Docker sync is needed by comparing image lists
# Docker 이미지 목록 비교로 동기화 필요성 판단하는 함수
should_sync_docker_status() {
    # Docker 사용 가능 여부 확인
    if ! command -v docker &> /dev/null; then
        return 1  # Docker 없으면 동기화 불필요
    fi
    
    # 레지스트리 파일 확인 - 없으면 빈 레지스트리로 처리
    if [ ! -f "$REGISTRY_FILE" ]; then
        # 레지스트리 파일이 없으면 Docker 이미지가 있는지만 확인
        local docker_images
        docker_images=$(docker image ls -a | grep -oE '^dockit-[^[:space:]]+' | sort)
        
        if [ $? -ne 0 ]; then
            return 1  # Docker 명령 실패하면 동기화 불필요
        fi
        
        if [ -n "$docker_images" ]; then
            return 0  # Docker 이미지가 있으면 동기화 필요
        else
            return 1  # Docker 이미지도 없으면 동기화 불필요
        fi
    fi
    
    # 실제 Docker 이미지 목록 추출 및 정렬
    local docker_images
    docker_images=$(docker image ls -a --format "{{.Repository}}" 2>/dev/null | grep "^dockit-" | sort)
    
    if [ $? -ne 0 ]; then
        return 1  # Docker 명령 실패하면 동기화 불필요
    fi
    
    # 레지스트리의 이미지 목록 추출 및 정렬
    local registry_images
    registry_images=$(cat "$REGISTRY_FILE" | jq -r 'to_entries[] | .value.image_name' 2>/dev/null | sort)
    
    # jq 실패하면 레지스트리를 비어있는 것으로 처리
    if [ $? -ne 0 ]; then
        registry_images=""
    fi
    
    # 핵심 로직 수정: 레지스트리와 Docker 이미지 상태 비교
    if [ -z "$registry_images" ] && [ -z "$docker_images" ]; then
        return 1  # 둘 다 비어있으면 동기화 불필요
    elif [ -z "$registry_images" ] && [ -n "$docker_images" ]; then
        return 0  # 레지스트리 비어있고 Docker 이미지 있으면 동기화 필요 ✅
    elif [ -n "$registry_images" ] && [ -z "$docker_images" ]; then
        return 0  # 레지스트리 있고 Docker 이미지 없으면 동기화 필요
    elif [ "$registry_images" = "$docker_images" ]; then
        return 1  # 동일하면 동기화 불필요
    else
        return 0  # 다르면 동기화 필요
    fi
}

# Function to sync registry state with actual Docker status (optimized)
# 레지스트리 상태를 실제 Docker 상태와 동기화 (최적화됨)
sync_with_docker_status() {
    # 성능 최적화: 이미지 목록 변경사항이 없으면 동기화 완전 스킵
    # Performance optimization: Skip sync completely if no image changes detected
    if ! should_sync_docker_status; then
        return 0  # 동기화 불필요 - Docker API 호출 없이 즉시 종료
    fi
    
    # Docker 사용 가능 여부 확인
    if ! command -v docker &> /dev/null; then
        return 0
    fi
    
    # 레지스트리 파일 확인
    if [ ! -f "$REGISTRY_FILE" ]; then
        return 0
    fi
    
    # Performance optimization: Load Docker images at once (container states already cached)
    # 성능 최적화: Docker 이미지 목록만 로드 (컨테이너 상태는 이미 캐시됨)
    get_local_dockit_images > /dev/null  # Initialize image cache
    
    local registry_json=$(cat "$REGISTRY_FILE")
    local updated=false
    
    # 각 프로젝트의 실제 Docker 상태 확인 및 업데이트 (캐시 사용)
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
        
        # 실제 Docker 상태 확인 (캐시 사용으로 빠름)
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

# Auto-discover unregistered dockit projects from Docker (optimized)
# Docker에서 미등록 dockit 프로젝트 자동 발견 (최적화됨)
discover_and_register_projects() {
    local discovered_count=0
    
    # Performance optimization: Use cached Docker information
    # 성능 최적화: 캐시된 Docker 정보 사용
    local docker_names=""
    
    if command -v docker &> /dev/null; then
        # Use cached image information if available, otherwise load it
        # 캐시된 이미지 정보가 있으면 사용, 없으면 로드
        local image_names
        image_names=$(get_local_dockit_images)
        
        # Get container names from cached container states
        # 캐시된 컨테이너 상태에서 컨테이너 이름 가져오기
        local container_names=""
        for container_name in "${!CONTAINER_STATES_CACHE[@]}"; do
            if [[ "$container_name" == dockit-* ]]; then
                container_names+="$container_name"$'\n'
            fi
        done
        
        # Combine image and container names
        # 이미지와 컨테이너 이름 결합
        docker_names=$(echo -e "$container_names\n$image_names" | grep -v "^$" | sort -u)
    fi
    
    if [ -z "$docker_names" ]; then
        return 0
    fi
    
    local registry_json=$(cat "$REGISTRY_FILE")
    
    # 2. 각 Docker 이름에 대해 처리
    while IFS= read -r docker_name; do
        [ -z "$docker_name" ] && continue
        
        # 이미 레지스트리에 등록된 프로젝트인지 확인
        local already_registered=$(echo "$registry_json" | jq -r --arg name "$docker_name" 'to_entries[] | select(.value.image_name == $name or (.value.image_name // "" | contains($name))) | .key' 2>/dev/null)
        if [ -n "$already_registered" ] && [ "$already_registered" != "null" ]; then
            continue
        fi
        
        # 3. Docker 이름을 경로로 변환 시도 (안전한 방법)
        local potential_paths=()
        
        # 방법 1: 표준 변환 (하이픈을 슬래시로)
        local name_without_prefix=$(echo "$docker_name" | sed 's/^dockit-//')
        local standard_path="/$(echo "$name_without_prefix" | tr '-' '/')"
        potential_paths+=("$standard_path")
        
        # 방법 2: 현재 작업 디렉토리 주변에서 검색
        local base_dir=$(pwd | sed 's|/[^/]*$||')  # 상위 디렉토리
        if [ -d "$base_dir" ]; then
            # 패턴 매칭으로 유사한 디렉토리 찾기
            local found_path=$(find "$base_dir" -maxdepth 3 -type d -name ".dockit_project" 2>/dev/null | while read -r dockit_dir; do
                local project_dir=$(dirname "$dockit_dir")
                local project_name=$(generate_dockit_name "$project_dir")
                if [ "$project_name" = "$docker_name" ]; then
                    echo "$project_dir"
                    break
                fi
            done | head -1)
            
            if [ -n "$found_path" ]; then
                potential_paths+=("$found_path")
            fi
        fi
        
        # 4. 각 경로에 대해 검증
        for path in "${potential_paths[@]}"; do
            [ -z "$path" ] && continue
            
            # 디렉토리와 .dockit_project 존재 확인
            if [ -d "$path" ] && [ -d "$path/.dockit_project" ] && [ -f "$path/.dockit_project/id" ]; then
                # 프로젝트 ID 확인
                local project_id=$(cat "$path/.dockit_project/id" 2>/dev/null)
                if [ -n "$project_id" ]; then
                    # 레지스트리에 등록
                    local current_time=$(date +%s)
                    if add_project_to_registry "$project_id" "$path" "$current_time" "ready" "" "$docker_name"; then
                        ((discovered_count++))
                        echo "🔍 발견된 프로젝트 등록: $(basename "$path")" >&2
                    fi
                fi
                break  # 성공하면 다음 docker_name으로
            fi
        done
        
    done <<< "$docker_names"
    
    if [ $discovered_count -gt 0 ]; then
        echo "✨ $discovered_count 개의 미등록 프로젝트가 자동으로 발견되어 등록되었습니다." >&2
    fi
    
    return 0
}

# Main function for listing registered projects
# 등록된 프로젝트 목록 표시를 위한 메인 함수
list_main() {
    # ========================================================================================
    # Clean Synchronous Architecture - Silent Performance Optimization
    # 깔끔한 동기 아키텍처 - 조용한 성능 최적화
    # ========================================================================================
    
    # Smart sync decision for performance optimization
    # 성능 최적화를 위한 스마트 동기화 결정
    local needs_full_sync=false
    local is_first_run=false
    local show_progress_message=false
    
    if should_perform_smart_sync; then
        needs_full_sync=true
        if ! is_list_initialized; then
            is_first_run=true
            show_progress_message=true
        fi
    fi
    
    # 레지스트리 파일 확인 및 초기화
    # Check and initialize registry file
    if [ ! -f "$REGISTRY_FILE" ]; then
        echo '{}' > "$REGISTRY_FILE"
    fi
    
    # Show progress message only on first run
    # 첫 실행 시에만 진행 메시지 표시
    if [ "$show_progress_message" = true ]; then
        echo "등록된 프로젝트 (조회 중...)"
        echo ""
    fi
    
    # Smart cleanup: Full cleanup only on first run or when changes detected
    # 스마트 정리: 첫 실행 또는 변경사항이 있을 때만 전체 cleanup 수행
    if [ "$needs_full_sync" = true ]; then
        load_registry "with_cleanup" > /dev/null 2>&1
    else
        load_registry "no_cleanup" > /dev/null 2>&1
    fi
    
    # 현재 디렉토리에서 프로젝트 ID 동기화 시도
    # Try to synchronize project ID in current directory
    if [ -d ".dockit_project" ] && [ -f ".dockit_project/id" ]; then
        handle_project_id_sync "$(pwd)" > /dev/null 2>&1
    fi
    
    # 성능 최적화: 컨테이너 상태 캐시는 항상 초기화 (이미지와 독립적)
    # Performance optimization: Always initialize container state cache (independent from images)
    get_batch_container_states
    
    # 컨테이너 상태는 이미지와 독립적이므로 항상 업데이트
    # Container states are independent from images, so always update them
    local registry_json=$(cat "$REGISTRY_FILE")
    
    # 각 프로젝트의 컨테이너 상태만 빠르게 업데이트 (캐시 사용)
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
        
        # 실제 Docker 상태 확인 (캐시 사용으로 빠름)
        local actual_state
        actual_state=$(get_actual_docker_state "$image_name" "$container_name")
        
        # 상태가 다르면 업데이트 (error 상태는 수동으로만 변경)
        if [ "$current_state" != "$actual_state" ] && [ "$current_state" != "error" ]; then
            update_project_status "$project_id" "$actual_state"
        fi
    done < <(echo "$registry_json" | jq -r 'keys[]')
    
    # 조건부 이미지 동기화 및 프로젝트 발견 (스마트 모드)
    # Conditional image sync and project discovery (smart mode)
    if [ "$needs_full_sync" = true ]; then
        # 실시간 Docker 상태와 레지스트리 동기화 (이미지 레벨)
        # Sync registry with real-time Docker status (image level)
        sync_with_docker_status > /dev/null 2>&1
        
        # 미등록 프로젝트 자동 발견 및 등록
        # Auto-discover and register unregistered projects
        discover_and_register_projects > /dev/null 2>&1
        
        # 초기화 상태 설정 (첫 실행 시)
        # Set initialization state (on first run)
        if [ "$is_first_run" = true ]; then
            set_list_initialized
        fi
    fi
    
    # 레지스트리 다시 로드 (상태 업데이트 반영)
    # Reload registry (to reflect status updates)
    registry_json=$(cat "$REGISTRY_FILE")
    
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
    local ids_to_remove=()

    # Process each project entry
    local index=1
    while IFS= read -r id; do
        local path=$(echo "$registry_json" | jq -r --arg id "$id" '.[$id].path')

        # If path is not valid, schedule for removal and skip display
        if ! is_path_valid "$path"; then
            ids_to_remove+=("$id")
            continue
        fi
        
        local created=$(echo "$registry_json" | jq -r --arg id "$id" '.[$id].created')
        local state=$(echo "$registry_json" | jq -r --arg id "$id" '.[$id].state')
        local last_seen=$(echo "$registry_json" | jq -r --arg id "$id" 'if .[$id] | has("last_seen") then .[$id].last_seen else .[$id].created end')
        
        # 경로가 존재하면 ID 동기화 시도
        # Try ID synchronization if path exists
        if [ -d "$path" ] && [ -f "$path/.dockit_project/id" ]; then
            handle_project_id_sync "$path" > /dev/null 2>&1
        fi
        
        local path_display=$(format_path "$path")
        
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

    # Remove invalid projects from registry after listing
    if [ ${#ids_to_remove[@]} -gt 0 ]; then
        echo "" # Newline for separation
        for id in "${ids_to_remove[@]}"; do
            remove_project_from_registry "$id"
        done
    fi
    
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

# 레지스트리에서 프로젝트 제거
# Remove project from registry
remove_project_from_registry() {
    local project_id="$1"
    
    if [ ! -f "$REGISTRY_FILE" ]; then
        log "ERROR" "Registry file not found"
        return 1
    fi
    
    # 임시 파일 생성
    # Create temporary file
    local temp_file
    temp_file="$(mktemp)"
    
    # jq를 사용하여 프로젝트 제거
    # Remove project using jq
    if command -v jq &> /dev/null; then
        jq --arg id "$project_id" 'del(.[$id])' "$REGISTRY_FILE" > "$temp_file" && mv "$temp_file" "$REGISTRY_FILE"
        log "INFO" "Removed project from registry: ${project_id:0:12}..."
    else
        log "WARNING" "jq not found, cannot remove project from registry"
        return 1
    fi
}
