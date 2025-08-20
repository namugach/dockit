#!/bin/bash

# PS module - Show dockit containers
# ps 모듈 - dockit 컨테이너 목록 표시

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$UTILS_DIR/async_tasks.sh"
source "$MODULES_DIR/registry.sh"
source "$MODULES_DIR/cleanup.sh"

# Function to truncate text if it's longer than max_length
# 텍스트가 최대 길이보다 길면 잘라내는 함수
truncate_text() {
    local text="$1"
    local max_length="$2"
    
    if [ ${#text} -gt $max_length ]; then
        echo "${text:0:$((max_length-3))}..."
    else
        echo "$text"
    fi
}

# Check Docker availability
# Docker 사용 가능 여부 확인
check_docker_availability() {
    if ! command -v docker &> /dev/null; then
        log "ERROR" "$(get_message MSG_COMMON_DOCKER_NOT_FOUND)"
        return 1
    fi
    return 0
}

# Print table header
# 테이블 헤더 출력
print_header() {
    local format="$1"
    printf "$format" \
        "PNO" \
        "PID" \
        "CID" \
        "IMAGE" \
        "NAME" \
        "CREATED" \
        "STATUS" \
        "IP" \
        "PORTS"
}

# Get all dockit containers
# 모든 dockit 컨테이너 가져오기
get_dockit_containers() {
    docker ps -a --filter "label=com.dockit=true" --format "{{.ID}}"
}



# Get project number from registry
# 레지스트리에서 프로젝트 번호 가져오기
get_project_number() {
    local project_id="$1"
    
    if [ ! -f "$REGISTRY_FILE" ]; then
        echo ""
        return 1
    fi
    
    local registry_json=$(cat "$REGISTRY_FILE")
    local index=1
    
    while IFS= read -r id; do
        if [ "$id" = "$project_id" ]; then
            echo "$index"
            return 0
        fi
        ((index++))
    done < <(echo "$registry_json" | jq -r 'keys[]')
    
    echo ""
    return 1
}

# Get container basic info with optimized single docker inspect call
# 최적화된 단일 docker inspect 호출로 컨테이너 기본 정보 가져오기
get_container_info() {
    local container_id="$1"
    
    # Single docker inspect call to get all needed information
    # 필요한 모든 정보를 한 번의 docker inspect 호출로 가져오기
    local inspect_output
    inspect_output=$(docker inspect --format \
        "{{.Name}}|{{.Config.Image}}|{{.Created}}|{{.State.Status}}|{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}|{{.NetworkSettings.IPAddress}}" \
        "$container_id" 2>/dev/null)
    
    if [ -z "$inspect_output" ]; then
        return 1
    fi
    
    # Parse the output using IFS
    IFS='|' read -r full_name image created status network_ip default_ip <<< "$inspect_output"
    
    # Clean up the name (remove leading slash)
    full_name=$(echo "$full_name" | sed 's/^\///')
    
    # 컨테이너 이름에서 'dockit-' 접두사 제거
    local raw_name=$(echo "$full_name" | sed 's/^dockit-//')
    
    # 이름에서 마지막 부분만 추출 (경로의 마지막 디렉토리)
    # 예: 'home-hgs-dockit-test-temp-b' -> 'temp-b' 또는 'b'
    local simple_name
    if [[ "$raw_name" == *-*-* ]]; then
        # 경로 형태로 변환해서 마지막 부분 추출
        local path_form=$(echo "$raw_name" | tr '-' '/')
        # 마지막 두 디렉토리만 가져오기 (예: temp/b)
        simple_name=$(echo "$path_form" | rev | cut -d'/' -f1-2 | rev | tr '/' '-')
    else
        # 이름이 짧거나 '-'가 적으면 그대로 사용
        simple_name="$raw_name"
    fi
    
    # Format created date
    created=$(echo "$created" | cut -d'T' -f1,2 | sed 's/T/ /' | cut -d'.' -f1)
    
    # Determine IP address (prefer network_ip, fallback to default_ip)
    local ip_address="-"
    if [ "$status" = "running" ]; then
        if [ -n "$network_ip" ]; then
            ip_address="$network_ip"
        elif [ -n "$default_ip" ]; then
            ip_address="$default_ip"
        fi
    fi
    
    # Store results in global variables for the calling function
    CONTAINER_SIMPLE_NAME="$simple_name"
    CONTAINER_IMAGE="$image"
    CONTAINER_CREATED="$created"
    CONTAINER_STATUS="$status"
    CONTAINER_IP="$ip_address"
}

# Get container IP address
# get_container_ip() function removed - IP address is now included in get_container_info() for performance
# get_container_ip() 함수 제거됨 - 성능 향상을 위해 IP 주소가 get_container_info()에 포함됨

# Get container ports
# 컨테이너 포트 가져오기
get_container_ports() {
    local container_id="$1"
    local status="$2"
    
    if [ "$status" == "running" ]; then
        local ports=$(docker port "$container_id" 2>/dev/null | tr '\n' ', ' | sed 's/,$//g')
        if [ -z "$ports" ]; then
            echo "-"
        else
            echo "$ports"
        fi
    else
        echo "-"
    fi
}

# Get status display text with color
# 색상이 적용된 상태 표시 텍스트 가져오기
get_status_display() {
    local status="$1"
    
    case "$status" in
        "running")
            echo -e "${GREEN}running${NC}"
            ;;
        "exited")
            echo -e "${YELLOW}stopped${NC}"
            ;;
        *)
            echo $status
            ;;
    esac
}

# Format container info for display
# 컨테이너 정보를 표시용으로 포맷팅
format_container_info() {
    local container_id="$1"
    local format="$2"
    
    # 프로젝트 정보 가져오기
    local project_id=$(find_project_info_by_container "$container_id")
    local project_number=""
    local project_id_display="-"
    
    if [ -n "$project_id" ]; then
        project_number=$(get_project_number "$project_id")
        project_id_display="${project_id:0:12}"
    fi
    
    if [ -z "$project_number" ]; then
        project_number="-"
    fi
    
    # 컨테이너 기본 정보 가져오기 (최적화된 단일 호출)
    if ! get_container_info "$container_id"; then
        log "WARNING" "Failed to get container info for $container_id"
        return 1
    fi
    
    # 글로벌 변수에서 정보 가져오기 (docker inspect 호출 없음)
    local name="$CONTAINER_SIMPLE_NAME"
    local image="$CONTAINER_IMAGE"
    local created="$CONTAINER_CREATED"
    local status="$CONTAINER_STATUS"
    local ip_address="$CONTAINER_IP"
    local ports=$(get_container_ports "$container_id" "$status")
    
    # 긴 텍스트 필드 잘라내기
    local image_display=$(truncate_text "$image" 20)
    local name_display=$(truncate_text "$name" 20)
    local ports_display=$(truncate_text "$ports" 20)
    
    # 상태 텍스트 가져오기
    local status_display=$(get_status_display "$status")
    
    # 포맷된 결과 반환
    printf "$format" \
        "$project_number" \
        "$project_id_display" \
        "${container_id:0:12}" \
        "$image_display" \
        "$name_display" \
        "$created" \
        "$status_display" \
        "$ip_address" \
        "$ports_display"
}

# 로딩 메시지 표시 - 같은 줄에 출력하고 나중에 지울 수 있게
# Display loading message - print on the same line for later removal
show_loading() {
    local message="$1"
    
    # 같은 줄에 로딩 메시지 출력 (줄바꿈 없이)
    echo -en "* ${message} *"
}

# 로딩 메시지 지우기
# Clear loading message
clear_loading() {
    # 커서를 줄 시작으로 이동시키고 현재 줄을 지움
    echo -en "\r\033[K"
}

# 모든 dockit 컨테이너 가져오기 및 없는 경우 처리하는 함수
get_and_check_containers() {
    local format="$1"
    local container_ids=$(get_dockit_containers)
    
    # 컨테이너가 없는 경우 처리
    if [ -z "$container_ids" ]; then
        print_header "$format"
        echo -e "${YELLOW}$(get_message MSG_LIST_NO_CONTAINERS)${NC}"
        echo ""
        echo "$(get_message MSG_LIST_RUN_INIT_HINT)"
        echo "ex A)  "
        echo "dockit ls -> dockit up index"
        echo "ex B)"
        echo "mkdir project_name -> cd project_name -> dockit run"
        echo ""
        return 1
    fi
    
    # 불필요한 출력을 제거함
    return 0
}

# 컨테이너 정보를 수집하고 파일에 저장하는 함수
collect_container_data() {
    local container_ids="$1"
    local format="$2"
    local output_file="$3"
    
    # 레지스트리에서 모든 프로젝트 가져오기
    if [ ! -f "$REGISTRY_FILE" ]; then
        return 0
    fi
    
    local registry_json=$(cat "$REGISTRY_FILE")
    local project_number=1  # list의 NO와 동일한 번호 사용
    
    # 레지스트리의 모든 프로젝트를 순서대로 처리
    while IFS= read -r project_id; do
        local project_id_display="${project_id:0:12}"
        
        # 해당 프로젝트의 컨테이너 찾기
        local container_id=""
        local container_info=""
        local name="-"
        local image="-"
        local created="-"
        local status="down"
        local ip_address="-"
        local ports="-"
        
        # 프로젝트 경로 가져오기
        local project_path=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
        
        # 레지스트리에서 프로젝트 상태 가져오기
        local registry_state=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].state')
        
        # 경로에서 컨테이너 이름 생성
        local container_name=$(generate_dockit_name "$project_path")
        
        # 컨테이너 ID 찾기 (정확한 이름 매칭)
        container_id=$(docker ps -aq --filter "name=^${container_name}$" --filter "label=com.dockit=true" | head -1)
        
        if [ -n "$container_id" ]; then
            # 컨테이너가 존재하는 경우만 처리 (최적화된 단일 호출)
            if get_container_info "$container_id"; then
                # 글로벌 변수에서 정보 가져오기 (docker inspect 호출 없음)
                name="$CONTAINER_SIMPLE_NAME"
                image="$CONTAINER_IMAGE"
                created="$CONTAINER_CREATED"
                status="$CONTAINER_STATUS"
                ip_address="$CONTAINER_IP"
            ports=$(get_container_ports "$container_id" "$status")
            
            # 컨테이너 ID 표시용
            local cid_display="${container_id:0:12}"
            
            # 긴 텍스트 필드 잘라내기
            local image_display=$(truncate_text "$image" 20)
            local name_display=$(truncate_text "$name" 20)
            local ports_display=$(truncate_text "$ports" 20)
            
            # 상태 텍스트 가져오기
            local status_display=$(get_status_display "$status")
            
            # 로우 데이터를 파일에 저장 (실제 컨테이너가 있는 경우만)
            # PNO는 list의 NO와 동일하게 매칭
            printf "$format" \
                "$project_number" \
                "$project_id_display" \
                "$cid_display" \
                "$image_display" \
                "$name_display" \
                "$created" \
                "$status_display" \
                "$ip_address" \
                "$ports_display" >> "$output_file"
          fi
      fi
      # 컨테이너가 없는 경우는 ps 출력에서 제외하지만 project_number는 증가
      ((project_number++))
    done < <(echo "$registry_json" | jq -r 'keys[]')
}

# Main function for listing dockit containers
# dockit 컨테이너 목록 표시를 위한 메인 함수
list_main() {
    local show_all=false
    
    # 인자 처리
    # Handle arguments
    if [ "$1" = "-a" ] || [ "$1" = "--all" ]; then
        show_all=true
        shift
    fi
    
    # Docker 사용 가능 여부 확인
    if ! check_docker_availability; then
        exit 1
    fi
    
    # 레지스트리 조용히 정리 실행 (메시지 없이)
    # Silently clean up registry (without messages)
    cleanup_registry > /dev/null 2>&1

    # 형식 문자열 정의 (PNO, PID, CID 칼럼 추가)
    local format="%-4s  %-13s  %-13s  %-20s  %-25s  %-25s  %-10s  %-17s  %s\n"

    # 컨테이너 데이터를 파일에 저장
    local temp_file=$(mktemp)
    
    # 컨테이너 가져오기 및 확인
    if ! get_and_check_containers "$format"; then
        return 0
    fi
    
    # 컨테이너 ID 직접 가져오기
    local container_ids=$(get_dockit_containers)

    # 로딩 메시지 표시
    loading_msg="$(get_message MSG_LIST_LOADING_DATA)"
    show_loading "$loading_msg"

    # 모든 컨테이너 정보를 임시 파일에 수집
    add_task "$loading_msg" 'collect_container_data "$container_ids" "$format" "$temp_file"'
    # collect_container_data "$container_ids" "$format" "$temp_file"
    ( async_tasks_hide_finish_message )
    # 로딩 메시지 지우기
    # clear_loading

    
    # 헤더와 함께 모든 정보를 한 번에 출력
    print_header "$format"
    cat "$temp_file"
    
    # -a 옵션이 지정된 경우 끊어진 컨테이너도 표시
    # Show broken containers if -a option is specified
    if [ "$show_all" = true ]; then
        local broken_containers=()
        while IFS= read -r line; do
            [ -n "$line" ] && broken_containers+=("$line")
        done < <(detect_broken_containers)
        if [ ${#broken_containers[@]} -gt 0 ]; then
            echo ""
            echo "⚠️  끊어진 컨테이너 (${#broken_containers[@]})"
            
            local broken_format="%-4s  %-25s  %-25s  %s\n"
            printf "$broken_format" "NO" "컨테이너" "이미지" "상태"
            
            local index=1
            for broken in "${broken_containers[@]}"; do
                IFS='|' read -r container_name image_name status <<< "$broken"
                printf "$broken_format" \
                    "$index" \
                    "$(truncate_text "$container_name" 25)" \
                    "$(truncate_text "$image_name" 25)" \
                    "$status"
                ((index++))
            done
            echo ""
            echo "💡 정리하려면: dockit cleanup containers"
        fi
    fi
    
    # 임시 파일 삭제
    rm -f "$temp_file"
}

# Run main function if this script is called directly
# 이 스크립트가 직접 호출될 경우 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    list_main "$@"
fi 