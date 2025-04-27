#!/bin/bash

# List module - Show dockit containers
# list 모듈 - dockit 컨테이너 목록 표시

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"


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
        "$(get_message MSG_LIST_ID)" \
        "$(get_message MSG_LIST_IMAGE)" \
        "$(get_message MSG_LIST_NAME)" \
        "$(get_message MSG_LIST_CREATED)" \
        "$(get_message MSG_LIST_STATUS)" \
        "$(get_message MSG_LIST_IP)" \
        "$(get_message MSG_LIST_PORTS)"
}

# Get all dockit containers
# 모든 dockit 컨테이너 가져오기
get_dockit_containers() {
    docker ps -a --filter "label=com.dockit=true" --format "{{.ID}}"
}

# Get container basic info
# 컨테이너 기본 정보 가져오기
get_container_info() {
    local container_id="$1"
    local full_name=$(docker inspect --format "{{.Name}}" "$container_id" | sed 's/^\///')
    
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
    
    local image=$(docker inspect --format "{{.Config.Image}}" "$container_id")
    local created=$(docker inspect --format "{{.Created}}" "$container_id" | cut -d'T' -f1,2 | sed 's/T/ /' | cut -d'.' -f1)
    local status=$(docker inspect --format "{{.State.Status}}" "$container_id")
    
    echo "$simple_name|$image|$created|$status"
}

# Get container IP address
# 컨테이너 IP 주소 가져오기
get_container_ip() {
    local container_id="$1"
    local status="$2"
    
    if [ "$status" == "running" ]; then
        local ip_address=$(docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")
        # IP가 비어있으면 NetworkSettings에서 직접 가져오기
        if [ -z "$ip_address" ]; then
            ip_address=$(docker inspect --format '{{.NetworkSettings.IPAddress}}' "$container_id")
        fi
        echo "$ip_address"
    else
        echo "-"
    fi
}

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
            echo $(get_message MSG_STATUS_RUNNING)
            ;;
        "exited")
            echo $(get_message MSG_STATUS_STOPPED)
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
    
    # 컨테이너 기본 정보 가져오기
    local container_info=$(get_container_info "$container_id")
    local name=$(echo "$container_info" | cut -d'|' -f1)
    local image=$(echo "$container_info" | cut -d'|' -f2)
    local created=$(echo "$container_info" | cut -d'|' -f3)
    local status=$(echo "$container_info" | cut -d'|' -f4)
    
    # 추가 정보 가져오기
    local ip_address=$(get_container_ip "$container_id" "$status")
    local ports=$(get_container_ports "$container_id" "$status")
    
    # 긴 텍스트 필드 잘라내기
    local image_display=$(truncate_text "$image" 20)
    local name_display=$(truncate_text "$name" 20)
    local ports_display=$(truncate_text "$ports" 20)
    
    # 상태 텍스트 가져오기
    local status_display=$(get_status_display "$status")
    
    # 포맷된 결과 반환
    printf "$format" \
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
        echo "  dockit init"
        echo ""
        return 1
    fi
    
    echo "$container_ids"
    return 0
}

# 컨테이너 정보를 수집하고 파일에 저장하는 함수
collect_container_data() {
    local container_ids="$1"
    local format="$2"
    local output_file="$3"
    
    for container_id in $container_ids; do
        # 컨테이너 기본 정보 가져오기
        local container_info=$(get_container_info "$container_id")
        local name=$(echo "$container_info" | cut -d'|' -f1)
        local image=$(echo "$container_info" | cut -d'|' -f2)
        local created=$(echo "$container_info" | cut -d'|' -f3)
        local status=$(echo "$container_info" | cut -d'|' -f4)
        
        # 추가 정보 가져오기
        local ip_address=$(get_container_ip "$container_id" "$status")
        local ports=$(get_container_ports "$container_id" "$status")
        
        # 긴 텍스트 필드 잘라내기
        local image_display=$(truncate_text "$image" 20)
        local name_display=$(truncate_text "$name" 20)
        local ports_display=$(truncate_text "$ports" 20)
        
        # 상태 텍스트 가져오기
        local status_display=$(get_status_display "$status")
        
        # 로우 데이터를 파일에 저장
        printf "$format" \
            "${container_id:0:12}" \
            "$image_display" \
            "$name_display" \
            "$created" \
            "$status_display" \
            "$ip_address" \
            "$ports_display" >> "$output_file"
    done
}

# Main function for listing dockit containers
# dockit 컨테이너 목록 표시를 위한 메인 함수
list_main() {
    # Docker 사용 가능 여부 확인
    if ! check_docker_availability; then
        exit 1
    fi

    # 형식 문자열 정의
    local format="%-13s  %-20s  %-25s  %-25s  %-10s  %-17s  %s\n"

    # 컨테이너 데이터를 파일에 저장
    local temp_file=$(mktemp)

    
    # 컨테이너 가져오기 및 확인
    local container_ids=$(get_and_check_containers "$format")
    if [ $? -ne 0 ]; then
        return 0
    fi

    # 로딩 메시지 표시
    loading_msg="$(get_message MSG_LIST_LOADING_DATA)"
    show_loading "$loading_msg"

    # 모든 컨테이너 정보를 임시 파일에 수집
    collect_container_data "$container_ids" "$format" "$temp_file"

    # 로딩 메시지 지우기
    clear_loading
    
    # 헤더와 함께 모든 정보를 한 번에 출력
    print_header "$format"
    cat "$temp_file"
    
    # 임시 파일 삭제
    rm -f "$temp_file"
}

# Run main function if this script is called directly
# 이 스크립트가 직접 호출될 경우 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    list_main "$@"
fi 