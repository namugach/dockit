#!/bin/bash

# Network module - Show dockit networks
# network 모듈 - dockit 네트워크 목록 표시

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$MODULES_DIR/registry.sh"

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
        "NO" \
        "NETWORK ID" \
        "NAME" \
        "DRIVER" \
        "SCOPE" \
        "PROJECT"
}

# Get all dockit networks
# 모든 dockit 네트워크 가져오기
get_dockit_networks() {
    docker network ls --filter "label=com.dockit=true" --format "{{.ID}}"
}

# Get network basic info
# 네트워크 기본 정보 가져오기
get_network_info() {
    local network_id="$1"
    
    # Single docker network inspect call to get all needed information
    # 필요한 모든 정보를 한 번의 docker network inspect 호출로 가져오기
    local inspect_output
    inspect_output=$(docker network inspect --format \
        "{{.Name}}|{{.Driver}}|{{.Scope}}|{{.Labels}}" \
        "$network_id" 2>/dev/null)
    
    if [ -z "$inspect_output" ]; then
        return 1
    fi
    
    # Parse the output using IFS
    IFS='|' read -r name driver scope labels <<< "$inspect_output"
    
    # Store results in global variables for the calling function
    NETWORK_NAME="$name"
    NETWORK_DRIVER="$driver"
    NETWORK_SCOPE="$scope"
    NETWORK_LABELS="$labels"
}

# Find project by network name using Docker labels
# 네트워크 이름으로 프로젝트 찾기 (Docker 레이블 사용)
find_project_by_network() {
    local network_name="$1"
    
    # Docker 레이블에서 프로젝트 이름 가져오기
    local project_name=$(docker network inspect "$network_name" --format '{{.Labels}}' 2>/dev/null | grep -o 'com.dockit.project:[^ ]*' | cut -d: -f2)
    
    if [ -n "$project_name" ] && [ "$project_name" != "null" ]; then
        # 레지스트리에서 해당 프로젝트 ID 찾기
        if [ -f "$REGISTRY_FILE" ]; then
            local registry_json=$(cat "$REGISTRY_FILE")
            local project_id=$(echo "$registry_json" | jq -r --arg name "$project_name" 'to_entries[] | select(.value.container_name == $name) | .key')
            
            if [ -n "$project_id" ] && [ "$project_id" != "null" ]; then
                echo "${project_id:0:12}"
                return 0
            fi
        fi
        
        # 레지스트리에서 찾지 못한 경우 컨테이너 이름의 마지막 부분만 표시
        local simple_name=$(echo "$project_name" | sed 's/^dockit-//' | rev | cut -d'-' -f1-2 | rev)
        echo "$simple_name"
        return 0
    fi
    
    echo "-"
    return 1
}

# Generate network name from project path
# 프로젝트 경로에서 네트워크 이름 생성
generate_network_name() {
    local project_path="$1"
    echo "dockit-$(echo "$project_path" | tr '/' '-' | tr '[:upper:]' '[:lower:]')"
}

# Format network info for display
# 네트워크 정보를 표시용으로 포맷팅
format_network_info() {
    local network_id="$1"
    local format="$2"
    local index="$3"
    
    # 네트워크 기본 정보 가져오기
    if ! get_network_info "$network_id"; then
        log "WARNING" "Failed to get network info for $network_id"
        return 1
    fi
    
    # 글로벌 변수에서 정보 가져오기
    local name="$NETWORK_NAME"
    local driver="$NETWORK_DRIVER"
    local scope="$NETWORK_SCOPE"
    
    # 프로젝트 정보 찾기
    local project=$(find_project_by_network "$name")
    
    # 긴 텍스트 필드 잘라내기
    local name_display=$(truncate_text "$name" 30)
    local project_display=$(truncate_text "$project" 12)
    
    # 포맷된 결과 반환
    printf "$format" \
        "$index" \
        "${network_id:0:12}" \
        "$name_display" \
        "$driver" \
        "$scope" \
        "$project_display"
}

# List dockit networks (same as main function without subcommand)
# dockit 네트워크 목록 표시 (서브커맨드 없이 메인 함수와 동일)
list_networks() {
    # 레지스트리 조용히 정리 실행 (메시지 없이)
    # Silently clean up registry (without messages)
    cleanup_registry > /dev/null 2>&1

    # 형식 문자열 정의
    local format="%-4s  %-13s  %-30s  %-10s  %-8s  %s\n"

    # 모든 dockit 네트워크 가져오기
    local network_ids=$(get_dockit_networks)
    
    # 네트워크가 없는 경우 처리
    if [ -z "$network_ids" ]; then
        print_header "$format"
        echo -e "${YELLOW}$(get_message MSG_NETWORK_NO_NETWORKS)${NC}"
        echo ""
        echo "$(get_message MSG_NETWORK_CREATE_HINT)"
        echo "ex) dockit init -> dockit up"
        echo ""
        return 0
    fi

    # 헤더 출력
    print_header "$format"
    
    # 각 네트워크 정보 출력
    local index=1
    for network_id in $network_ids; do
        format_network_info "$network_id" "$format" "$index"
        ((index++))
    done
    
    echo ""
    echo "💡 정리하려면: dockit network prune"
}

# Prune unused dockit networks
# 사용하지 않는 dockit 네트워크 정리
prune_networks() {
    local unused_networks=()
    
    # 모든 dockit 네트워크 가져오기
    local all_networks=$(get_dockit_networks)
    
    if [ -z "$all_networks" ]; then
        echo -e "${YELLOW}$(get_message MSG_NETWORK_NO_NETWORKS)${NC}"
        return 0
    fi

    echo "$(get_message MSG_NETWORK_PRUNE_CHECKING)"
    
    # 각 네트워크가 사용 중인지 확인
    for network_id in $all_networks; do
        local network_name=$(docker network inspect "$network_id" --format '{{.Name}}' 2>/dev/null)
        
        # 네트워크에 연결된 컨테이너 확인
        local connected_containers=$(docker network inspect "$network_id" --format '{{range $k, $v := .Containers}}{{$k}} {{end}}' 2>/dev/null)
        
        if [ -z "$connected_containers" ]; then
            unused_networks+=("$network_id|$network_name")
        fi
    done

    if [ ${#unused_networks[@]} -eq 0 ]; then
        echo -e "${GREEN}$(get_message MSG_NETWORK_PRUNE_NO_UNUSED)${NC}"
        return 0
    fi

    echo ""
    echo "$(get_message MSG_NETWORK_PRUNE_FOUND) ${#unused_networks[@]}"
    echo ""
    
    local format="%-4s  %-13s  %-30s\n"
    printf "$format" "NO" "NETWORK ID" "NAME"
    
    local index=1
    for network_info in "${unused_networks[@]}"; do
        IFS='|' read -r network_id network_name <<< "$network_info"
        local name_display=$(truncate_text "$network_name" 30)
        printf "$format" \
            "$index" \
            "${network_id:0:12}" \
            "$name_display"
        ((index++))
    done
    
    echo ""
    read -p "$(get_message MSG_NETWORK_PRUNE_CONFIRM) [Y/n]: " confirm
    
    # Y가 기본값이므로 빈 입력도 y로 처리
    if [ -z "$confirm" ]; then
        confirm="y"
    fi
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        local removed_count=0
        for network_info in "${unused_networks[@]}"; do
            IFS='|' read -r network_id network_name <<< "$network_info"
            if docker network rm "$network_id" >/dev/null 2>&1; then
                echo "$(get_message MSG_NETWORK_PRUNE_REMOVED): $network_name"
                ((removed_count++))
            else
                echo "$(get_message MSG_NETWORK_PRUNE_FAILED): $network_name"
            fi
        done
        echo ""
        echo -e "${GREEN}$(get_message MSG_NETWORK_PRUNE_COMPLETED): $removed_count${NC}"
    else
        echo "$(get_message MSG_NETWORK_PRUNE_CANCELLED)"
    fi
}

# Show network command usage
# 네트워크 명령어 사용법 표시
show_network_usage() {
    cat << EOF
$(get_message MSG_NETWORK_USAGE)

$(get_message MSG_NETWORK_SUBCOMMANDS):
  list | ls  - $(get_message MSG_NETWORK_HELP_LIST)
  prune      - $(get_message MSG_NETWORK_HELP_PRUNE)

$(get_message MSG_NETWORK_EXAMPLES):
  dockit network ls
  dockit network prune
EOF
}

# Main function for network command with subcommands
# 서브커맨드가 있는 네트워크 명령어 메인 함수
network_main() {
    local subcommand="$1"
    shift

    # Docker 사용 가능 여부 확인
    if ! check_docker_availability; then
        exit 1
    fi

    case "$subcommand" in
        "")
            show_network_usage
            ;;
        "list" | "ls")
            list_networks "$@"
            ;;
        "prune")
            prune_networks "$@"
            ;;
        "help" | "-h" | "--help")
            show_network_usage
            ;;
        *)
            echo -e "${RED}$(get_message MSG_NETWORK_UNKNOWN_COMMAND): $subcommand${NC}"
            echo ""
            show_network_usage
            exit 1
            ;;
    esac
}

# Run main function if this script is called directly
# 이 스크립트가 직접 호출될 경우 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    network_main "$@"
fi