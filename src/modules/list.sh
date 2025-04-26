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

# Print container row
# 컨테이너 행 출력
print_container_row() {
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
    
    # docker ps 스타일로 행 출력
    printf "$format" \
        "${container_id:0:12}" \
        "$image_display" \
        "$name_display" \
        "$created" \
        "$status_display" \
        "$ip_address" \
        "$ports_display"
}

# Main function for listing dockit containers
# dockit 컨테이너 목록 표시를 위한 메인 함수
list_main() {
    # Docker 사용 가능 여부 확인
    if ! check_docker_availability; then
        exit 1
    fi

    # 헤더 출력을 위한 형식 문자열 정의
    local format="%-13s  %-20s  %-25s  %-25s  %-10s  %-17s  %s\n"
    
    # 헤더 출력
    print_header "$format"
    
    # 모든 dockit 컨테이너 가져오기
    local container_ids=$(get_dockit_containers)
    
    # 컨테이너가 없는 경우 처리
    if [ -z "$container_ids" ]; then
        echo -e "${YELLOW}$(get_message MSG_LIST_NO_CONTAINERS)${NC}"
        echo ""
        echo "$(get_message MSG_LIST_RUN_INIT_HINT)"
        echo "  dockit init"
        echo ""
        return 0
    fi

    # 각 컨테이너 정보 출력
    for container_id in $container_ids; do
        print_container_row "$container_id" "$format"
    done
}

# Run main function if this script is called directly
# 이 스크립트가 직접 호출될 경우 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    list_main "$@"
fi 