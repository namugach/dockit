#!/bin/bash

# Cleanup module - Manage orphaned Docker resources created by dockit
# cleanup 모듈 - dockit으로 생성된 고아 Docker 리소스 관리

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$MODULES_DIR/registry.sh"
source "$UTILS_DIR/async_tasks.sh"

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

# Show usage function
# 사용법 표시 함수
show_usage() {
    echo "$MSG_CLEANUP_MODULE_USAGE_TITLE"
    echo ""
    echo "$MSG_CLEANUP_MODULE_COMMANDS"
    echo "  $MSG_CLEANUP_MODULE_CONTAINERS"
    echo "  $MSG_CLEANUP_MODULE_IMAGES"
    echo "  $MSG_CLEANUP_MODULE_NETWORKS" 
    echo "  $MSG_CLEANUP_MODULE_ALL"
    echo ""
    echo "$MSG_CLEANUP_MODULE_EXAMPLES"
    echo "  $MSG_CLEANUP_MODULE_EXAMPLE_CONTAINERS"
    echo "  $MSG_CLEANUP_MODULE_EXAMPLE_IMAGES"
    echo "  $MSG_CLEANUP_MODULE_EXAMPLE_NETWORKS"
    echo "  $MSG_CLEANUP_MODULE_EXAMPLE_ALL"
    echo ""
}

# 좀비 컨테이너 감지 함수
# Detect zombie containers
detect_zombie_containers() {
    
    # 모든 dockit 컨테이너 가져오기
    # Get all dockit containers
    local all_containers
    all_containers=$(docker ps -a --filter "label=com.dockit=true" --format "{{.Names}}|{{.Image}}|{{.Status}}")
    
    local zombie_containers=()
    
    while IFS='|' read -r container_name image_name status; do
        [ -z "$container_name" ] && continue
        
        # 레지스트리에서 이 컨테이너에 해당하는 프로젝트가 있는지 확인
        # Check if there's a project for this container in registry
        local is_registered=0
        
        if [ -f "$REGISTRY_FILE" ] && command -v jq &> /dev/null; then
            local project_info
            project_info=$(jq -r --arg image_name "$image_name" '
                to_entries[] | 
                select(.value.image_name == $image_name) | 
                .key + ":" + .value.path
            ' "$REGISTRY_FILE" 2>/dev/null | head -1)
            
            if [ -n "$project_info" ]; then
                local project_path="${project_info#*:}"
                # 프로젝트 디렉토리가 존재하는지 확인
                # Check if project directory exists
                if [ -d "$project_path" ] && [ -f "$project_path/.dockit_project/id" ]; then
                    is_registered=1
                fi
            fi
        fi
        
        # 등록되지 않은 컨테이너는 좀비로 간주
        # Consider unregistered containers as zombies
        if [ $is_registered -eq 0 ]; then
            zombie_containers+=("$container_name|$image_name|$status")
        fi
        
    done <<< "$all_containers"
    
    # 결과 반환
    # Return results
    for zombie in "${zombie_containers[@]}"; do
        echo "$zombie"
    done
}

# 좀비 이미지 감지 함수  
# Detect zombie images
detect_zombie_images() {
    
    # 모든 dockit 이미지 가져오기
    # Get all dockit images
    local all_images
    all_images=$(docker image ls --filter "reference=dockit-*" --format "{{.Repository}}|{{.ID}}|{{.CreatedSince}}|{{.Size}}")
    
    local zombie_images=()
    
    while IFS='|' read -r image_name image_id created_since size; do
        [ -z "$image_name" ] && continue
        
        # 이미지를 사용하는 컨테이너가 있는지 확인
        # Check if any containers use this image
        local containers_using_image
        containers_using_image=$(docker ps -a --filter "ancestor=$image_name" --format "{{.Names}}" | tr '\n' ' ')
        
        # 레지스트리에서 활성 프로젝트인지 확인
        # Check if it's an active project in registry
        local is_active=0
        if is_project_active_by_image "$image_name"; then
            is_active=1
        fi
        
        # 컨테이너에서 사용되지 않고 활성 프로젝트가 아니면 좀비
        # If not used by containers and not an active project, it's a zombie
        if [ -z "$containers_using_image" ] && [ $is_active -eq 0 ]; then
            zombie_images+=("$image_name|$image_id|$created_since|$size")
        fi
        
    done <<< "$all_images"
    
    # 결과 반환
    # Return results  
    for zombie in "${zombie_images[@]}"; do
        echo "$zombie"
    done
}

# 좀비 네트워크 감지 함수
# Detect zombie networks
detect_zombie_networks() {
    
    # 모든 dockit 네트워크 가져오기
    # Get all dockit networks
    local all_networks
    all_networks=$(docker network ls --filter "name=dockit-" --format "{{.Name}}|{{.ID}}")
    
    local zombie_networks=()
    
    while IFS='|' read -r network_name network_id; do
        [ -z "$network_name" ] && continue
        
        # 네트워크를 사용하는 컨테이너가 있는지 확인
        # Check if any containers use this network
        local containers_in_network
        containers_in_network=$(docker network inspect "$network_name" --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null)
        
        # 컨테이너가 없으면 좀비 네트워크
        # If no containers, it's a zombie network
        if [ -z "$containers_in_network" ] || [ "$containers_in_network" = " " ]; then
            zombie_networks+=("$network_name|$network_id")
        fi
        
    done <<< "$all_networks"
    
    # 결과 반환
    # Return results
    for zombie in "${zombie_networks[@]}"; do
        echo "$zombie"
    done
}

# 좀비 컨테이너 정리 함수
# Clean zombie containers
cleanup_containers() {
    local zombie_containers=()
    while IFS= read -r line; do
        [ -n "$line" ] && zombie_containers+=("$line")
    done < <(detect_zombie_containers)
    
    if [ ${#zombie_containers[@]} -eq 0 ]; then
        echo "$MSG_CLEANUP_NO_ZOMBIE_CONTAINERS"
        return 0
    fi
    
    echo "$(printf "$MSG_CLEANUP_FOUND_ZOMBIE_CONTAINERS" "${#zombie_containers[@]}")"
    echo ""
    
    # 좀비 컨테이너 목록 표시
    # Display zombie containers list
    printf "%-4s  %-25s  %-25s  %s\n" \
        "$MSG_CLEANUP_HEADER_NO" \
        "$MSG_CLEANUP_HEADER_CONTAINER" \
        "$MSG_CLEANUP_HEADER_IMAGE" \
        "$MSG_CLEANUP_HEADER_STATUS"
    
    local index=1
    for zombie in "${zombie_containers[@]}"; do
        IFS='|' read -r container_name image_name status <<< "$zombie"
        printf "%-4s  %-25s  %-25s  %s\n" \
            "$index" \
            "$(truncate_text "$container_name" 25)" \
            "$(truncate_text "$image_name" 25)" \
            "$status"
        ((index++))
    done
    
    echo ""
    echo -n "$MSG_CLEANUP_CONFIRM_CONTAINERS"
    read -r confirm
    
    # Y가 기본값이므로 빈 입력도 y로 처리
    if [ -z "$confirm" ]; then
        confirm="y"
    fi
    
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "yes" ]; then
        log "INFO" "$MSG_CLEANUP_CANCELLED"
        return 0
    fi
    
    # 컨테이너 정리 실행 (스피너 사용)
    # Execute container cleanup (with spinner)
    local removed_count=0
    local failed_count=0
    
    # 작업을 async_tasks로 추가
    tasks=()
    for zombie in "${zombie_containers[@]}"; do
        IFS='|' read -r container_name image_name status <<< "$zombie"
        add_task "$(printf "$MSG_CLEANUP_REMOVING_CONTAINER" "$container_name")" \
                 "docker stop \"$container_name\" &>/dev/null && docker rm \"$container_name\" &>/dev/null"
    done
    
    # 스피너 실행
    async_tasks_no_exit "$(get_message MSG_CLEANUP_REMOVING_COMPLETED)"
    
    # 결과 확인
    for zombie in "${zombie_containers[@]}"; do
        IFS='|' read -r container_name image_name status <<< "$zombie"
        if ! docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$"; then
            ((removed_count++))
        else
            ((failed_count++))
        fi
    done
    
    echo ""
    
    if [ $removed_count -gt 0 ]; then
        log "SUCCESS" "$(printf "$MSG_CLEANUP_REMOVED_CONTAINERS" "$removed_count")"
    fi
    
    if [ $failed_count -gt 0 ]; then
        log "WARNING" "$(printf "$MSG_CLEANUP_FAILED_CONTAINERS" "$failed_count")"
    fi
}

# 좀비 이미지 정리 함수
# Clean zombie images  
cleanup_images() {
    local zombie_images=()
    while IFS= read -r line; do
        [ -n "$line" ] && zombie_images+=("$line")
    done < <(detect_zombie_images)
    
    if [ ${#zombie_images[@]} -eq 0 ]; then
        echo "$MSG_CLEANUP_NO_ZOMBIE_IMAGES"
        return 0
    fi
    
    echo "$(printf "$MSG_CLEANUP_FOUND_ZOMBIE_IMAGES" "${#zombie_images[@]}")"
    echo ""
    
    # 좀비 이미지 목록 표시
    # Display zombie images list
    printf "%-4s  %-12s  %-13s  %-6s  %s\n" \
        "$MSG_CLEANUP_HEADER_NO" \
        "$MSG_CLEANUP_HEADER_ID" \
        "$MSG_CLEANUP_HEADER_CREATED" \
        "$MSG_CLEANUP_HEADER_SIZE" \
        "$MSG_CLEANUP_HEADER_NAME"
    
    local index=1
    for zombie in "${zombie_images[@]}"; do
        IFS='|' read -r image_name image_id created_since size <<< "$zombie"
        local image_id_short="${image_id:0:12}"
        printf "%-4s  %-12s  %-13s  %-6s  %s\n" \
            "$index" \
            "$image_id_short" \
            "$created_since" \
            "$size" \
            "$image_name"
        ((index++))
    done
    
    echo ""
    echo -n "$MSG_CLEANUP_CONFIRM_IMAGES"
    read -r confirm
    
    # Y가 기본값이므로 빈 입력도 y로 처리
    if [ -z "$confirm" ]; then
        confirm="y"
    fi
    
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "yes" ]; then
        log "INFO" "$MSG_CLEANUP_CANCELLED"
        return 0
    fi
    
    # 이미지 정리 실행
    # Execute image cleanup
    local removed_count=0
    local failed_count=0
    
    for zombie in "${zombie_images[@]}"; do
        IFS='|' read -r image_name image_id created_since size <<< "$zombie"
        
        echo -n "$(printf "$MSG_CLEANUP_REMOVING_IMAGE" "$image_name")"
        
        if docker rmi "$image_name" &>/dev/null; then
            echo "✓"
            ((removed_count++))
        else
            echo "✗"
            ((failed_count++))
        fi
    done
    
    echo ""
    
    if [ $removed_count -gt 0 ]; then
        log "SUCCESS" "$(printf "$MSG_CLEANUP_REMOVED_IMAGES" "$removed_count")"
    fi
    
    if [ $failed_count -gt 0 ]; then
        log "WARNING" "$(printf "$MSG_CLEANUP_FAILED_IMAGES" "$failed_count")"
    fi
}

# 좀비 네트워크 정리 함수
# Clean zombie networks
cleanup_networks() {
    local zombie_networks=()
    while IFS= read -r line; do
        [ -n "$line" ] && zombie_networks+=("$line")
    done < <(detect_zombie_networks)
    
    if [ ${#zombie_networks[@]} -eq 0 ]; then
        echo "$MSG_CLEANUP_NO_ZOMBIE_NETWORKS"
        return 0
    fi
    
    echo "$(printf "$MSG_CLEANUP_FOUND_ZOMBIE_NETWORKS" "${#zombie_networks[@]}")"
    echo ""
    
    # 좀비 네트워크 목록 표시
    # Display zombie networks list
    printf "%-4s  %-12s  %s\n" \
        "$MSG_CLEANUP_HEADER_NO" \
        "$MSG_CLEANUP_HEADER_ID" \
        "$MSG_CLEANUP_HEADER_NAME"
    
    local index=1
    for zombie in "${zombie_networks[@]}"; do
        IFS='|' read -r network_name network_id <<< "$zombie"
        local network_id_short="${network_id:0:12}"
        printf "%-4s  %-12s  %s\n" \
            "$index" \
            "$network_id_short" \
            "$network_name"
        ((index++))
    done
    
    echo ""
    echo -n "$MSG_CLEANUP_CONFIRM_NETWORKS"
    read -r confirm
    
    # Y가 기본값이므로 빈 입력도 y로 처리
    if [ -z "$confirm" ]; then
        confirm="y"
    fi
    
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "yes" ]; then
        log "INFO" "$MSG_CLEANUP_CANCELLED"
        return 0
    fi
    
    # 네트워크 정리 실행
    # Execute network cleanup
    local removed_count=0
    local failed_count=0
    
    for zombie in "${zombie_networks[@]}"; do
        IFS='|' read -r network_name network_id <<< "$zombie"
        
        echo -n "$(printf "$MSG_CLEANUP_REMOVING_NETWORK" "$network_name")"
        
        if docker network rm "$network_name" &>/dev/null; then
            echo "✓"
            ((removed_count++))
        else
            echo "✗"
            ((failed_count++))
        fi
    done
    
    echo ""
    
    if [ $removed_count -gt 0 ]; then
        log "SUCCESS" "$(printf "$MSG_CLEANUP_REMOVED_NETWORKS" "$removed_count")"
    fi
    
    if [ $failed_count -gt 0 ]; then
        log "WARNING" "$(printf "$MSG_CLEANUP_FAILED_NETWORKS" "$failed_count")"
    fi
}

# 모든 좀비 리소스 정리 함수
# Clean all zombie resources
cleanup_all() {
    echo "$MSG_CLEANUP_ALL_START"
    echo ""
    
    # 각 리소스별 감지
    # Detect each resource type
    local zombie_containers=()
    while IFS= read -r line; do
        [ -n "$line" ] && zombie_containers+=("$line")
    done < <(detect_zombie_containers)
    
    local zombie_images=()
    while IFS= read -r line; do
        [ -n "$line" ] && zombie_images+=("$line")
    done < <(detect_zombie_images)
    
    local zombie_networks=()
    while IFS= read -r line; do
        [ -n "$line" ] && zombie_networks+=("$line")
    done < <(detect_zombie_networks)
    
    # 요약 정보 표시
    # Display summary
    echo "$MSG_CLEANUP_ALL_SUMMARY"
    echo "  $(printf "$MSG_CLEANUP_SUMMARY_CONTAINERS" "${#zombie_containers[@]}")"
    echo "  $(printf "$MSG_CLEANUP_SUMMARY_IMAGES" "${#zombie_images[@]}")"
    echo "  $(printf "$MSG_CLEANUP_SUMMARY_NETWORKS" "${#zombie_networks[@]}")"
    echo ""
    
    local total_count=$((${#zombie_containers[@]} + ${#zombie_images[@]} + ${#zombie_networks[@]}))
    
    if [ $total_count -eq 0 ]; then
        echo "$MSG_CLEANUP_ALL_NO_ZOMBIES"
        return 0
    fi
    
    echo -n "$MSG_CLEANUP_CONFIRM_ALL"
    read -r confirm
    
    # Y가 기본값이므로 빈 입력도 y로 처리
    if [ -z "$confirm" ]; then
        confirm="y"
    fi
    
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "yes" ]; then
        log "INFO" "$MSG_CLEANUP_CANCELLED"
        return 0
    fi
    
    # 순차적으로 정리 (컨테이너 → 네트워크 → 이미지)
    # Clean up sequentially (containers → networks → images)
    # 네트워크를 먼저 정리해야 컨테이너와의 연결 문제가 없음
    echo ""
    log "INFO" "$MSG_CLEANUP_ALL_EXECUTING"
    echo ""
    
    if [ ${#zombie_containers[@]} -gt 0 ]; then
        echo "$MSG_CLEANUP_ALL_STEP_CONTAINERS"
        cleanup_containers
        echo ""
    fi
    
    if [ ${#zombie_networks[@]} -gt 0 ]; then
        echo "$MSG_CLEANUP_ALL_STEP_NETWORKS"
        cleanup_networks
        echo ""
    fi
    
    if [ ${#zombie_images[@]} -gt 0 ]; then
        echo "$MSG_CLEANUP_ALL_STEP_IMAGES"
        cleanup_images  
        echo ""
    fi
    
    log "SUCCESS" "$MSG_CLEANUP_ALL_COMPLETED"
}

# 상태 요약 표시 함수 
# Show status summary
show_status() {
    echo "$MSG_CLEANUP_STATUS_TITLE"
    echo ""
    
    # 각 리소스별 감지
    # Detect each resource type
    local zombie_containers=()
    while IFS= read -r line; do
        [ -n "$line" ] && zombie_containers+=("$line")
    done < <(detect_zombie_containers)
    
    local zombie_images=()
    while IFS= read -r line; do
        [ -n "$line" ] && zombie_images+=("$line")
    done < <(detect_zombie_images)
    
    local zombie_networks=()
    while IFS= read -r line; do
        [ -n "$line" ] && zombie_networks+=("$line")
    done < <(detect_zombie_networks)
    
    # 레지스트리 프로젝트 수 확인
    # Check registry project count
    local project_count=0
    local running_count=0
    local stopped_count=0
    
    if [ -f "$REGISTRY_FILE" ] && command -v jq &> /dev/null; then
        project_count=$(jq 'length' "$REGISTRY_FILE" 2>/dev/null || echo "0")
        running_count=$(jq '[.[] | select(.state == "running")] | length' "$REGISTRY_FILE" 2>/dev/null || echo "0")
        stopped_count=$((project_count - running_count))
    fi
    
    # 상태 정보 표시
    # Display status information
    echo "📊 $MSG_CLEANUP_STATUS_PROJECTS"
    echo "   $(printf "$MSG_CLEANUP_STATUS_PROJECT_DETAIL" "$project_count" "$running_count" "$stopped_count")"
    echo ""
    
    if [ ${#zombie_containers[@]} -gt 0 ]; then
        echo "⚠️  $(printf "$MSG_CLEANUP_STATUS_ZOMBIE_CONTAINERS" "${#zombie_containers[@]}")"
    fi
    
    if [ ${#zombie_images[@]} -gt 0 ]; then
        echo "⚠️  $(printf "$MSG_CLEANUP_STATUS_ZOMBIE_IMAGES" "${#zombie_images[@]}")"
    fi
    
    if [ ${#zombie_networks[@]} -gt 0 ]; then
        echo "⚠️  $(printf "$MSG_CLEANUP_STATUS_ZOMBIE_NETWORKS" "${#zombie_networks[@]}")"
    fi
    
    local total_zombies=$((${#zombie_containers[@]} + ${#zombie_images[@]} + ${#zombie_networks[@]}))
    
    if [ $total_zombies -eq 0 ]; then
        echo "✅ $MSG_CLEANUP_STATUS_NO_ZOMBIES"
    else
        echo ""
        echo "💡 $MSG_CLEANUP_STATUS_CLEANUP_HINT"
        echo "   dockit cleanup all"
    fi
    
    echo ""
}

# Main function for cleanup module
# cleanup 모듈의 메인 함수
cleanup_main() {
    # Check if arguments are provided
    # 인자가 제공되었는지 확인
    if [ $# -eq 0 ]; then
        show_status
        return 0
    fi
    
    # Process commands
    # 명령어 처리
    case "$1" in
        "containers")
            cleanup_containers
            ;;
        "images")
            cleanup_images
            ;;
        "networks")
            cleanup_networks
            ;;
        "all")
            cleanup_all
            ;;
        "status")
            show_status
            ;;
        *)
            log "ERROR" "$(printf "$MSG_CLEANUP_MAIN_UNKNOWN_COMMAND" "$1")"
            show_usage
            return 1
            ;;
    esac
}

# Run main function if this script is called directly
# 이 스크립트가 직접 호출될 경우 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cleanup_main "$@"
fi