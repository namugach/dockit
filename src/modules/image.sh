#!/bin/bash

# Image module - Manage Docker images created by dockit
# image 모듈 - dockit으로 생성된 Docker 이미지 관리

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Show usage function
# 사용법 표시 함수
show_usage() {
    echo "Usage: dockit image <command> [options]"
    echo ""
    echo "Commands:"
    echo "  list                - List all dockit images"
    echo "  remove <image>      - Remove specific image by name or number"
    echo "  prune               - Remove unused dockit images (not used by containers)"
    echo "  clean               - Remove ALL dockit images (including containers)"
    echo ""
    echo "Examples:"
    echo "  dockit image list"
    echo "  dockit image remove 1                        # Remove by number"
    echo "  dockit image remove dockit-home-user-project # Remove by name"
    echo "  dockit image prune                           # Remove unused images"
    echo "  dockit image clean                           # Remove ALL images (DANGER!)"
    echo ""
}

# Get dockit images from docker
# Docker에서 dockit 이미지들 가져오기
get_dockit_images() {
    # Get all images that start with 'dockit-'
    # 'dockit-'로 시작하는 모든 이미지 가져오기
    docker image ls --format "{{.Repository}}\t{{.ID}}\t{{.CreatedSince}}\t{{.Size}}" \
        --filter "reference=dockit-*"
}

# List dockit images
# dockit 이미지 목록 표시
list_images() {
    log "INFO" "Listing dockit images..."
    
    # Check if Docker is available
    # Docker 사용 가능 여부 확인
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker is not installed or not in PATH"
        return 1
    fi
    
    # Get dockit images
    # dockit 이미지들 가져오기
    local images_output
    images_output=$(get_dockit_images)
    
    if [ -z "$images_output" ]; then
        echo "No dockit images found."
        echo ""
        echo "To create images, run:"
        echo "  dockit init      # Create new project"
        echo "  dockit build     # Build project image"
        return 0
    fi
    
    # Fixed format string - NAME column unlimited like list module
    # 고정 포맷 문자열 - list 모듈처럼 NAME 컬럼 무제한
    local format="%-4s  %-12s  %-13s  %-6s  %s\n"
    
    # Display header
    # 헤더 표시
    printf "$format" \
        "NO" \
        "IMAGE ID" \
        "CREATED" \
        "SIZE" \
        "NAME"
    
    # Display each image
    # 각 이미지 표시
    local index=1
    while IFS=$'\t' read -r repository image_id created_since size; do
        # Skip empty lines
        # 빈 줄 건너뛰기
        if [ -z "$repository" ]; then
            continue
        fi
        
        # Truncate image ID to 12 characters
        # 이미지 ID를 12자로 자르기
        local image_id_short="${image_id:0:12}"
        
        printf "$format" \
            "$index" \
            "$image_id_short" \
            "$created_since" \
            "$size" \
            "$repository"
        
        ((index++))
    done <<< "$images_output"
    
    echo ""
    echo "Use 'dockit image remove <name>' to remove specific images"
}

# Get image name by number from list
# 번호로 이미지명 가져오기
get_image_name_by_number() {
    local number="$1"
    local images_output
    images_output=$(get_dockit_images)
    
    if [ -z "$images_output" ]; then
        return 1
    fi
    
    local index=1
    while IFS=$'\t' read -r repository image_id created_since size; do
        if [ -z "$repository" ]; then
            continue
        fi
        
        if [ "$index" -eq "$number" ]; then
            echo "$repository"
            return 0
        fi
        
        ((index++))
    done <<< "$images_output"
    
    return 1
}

# Remove specific image (placeholder)
# 특정 이미지 제거 (플레이스홀더)
remove_image() {
    local input="$1"
    local image_name=""
    
    # Validate input
    # 입력값 검증
    if [ -z "$input" ]; then
        log "ERROR" "Image name or number is required"
        echo "Usage: dockit image remove <image_name_or_number>"
        return 1
    fi
    
    # Check if input is a number
    # 입력값이 숫자인지 확인
    if [[ "$input" =~ ^[0-9]+$ ]]; then
        # Handle numeric input
        # 숫자 입력 처리
        image_name=$(get_image_name_by_number "$input")
        
        if [ -z "$image_name" ]; then
            log "ERROR" "Invalid image number: $input"
            echo "Use 'dockit image list' to see available images"
            return 1
        fi
        
        log "INFO" "Selected image #$input: $image_name"
    else
        # Handle string input
        # 문자열 입력 처리
        image_name="$input"
        
        # Check if it's a dockit image
        # dockit 이미지인지 확인
        if [[ ! "$image_name" =~ ^dockit- ]]; then
            log "ERROR" "Only dockit images (starting with 'dockit-') can be removed"
            echo "Image name must start with 'dockit-'"
            return 1
        fi
    fi
    
    # Check if image exists
    # 이미지 존재 여부 확인
    if ! docker image inspect "$image_name" &> /dev/null; then
        log "ERROR" "Image '$image_name' not found"
        echo "Use 'dockit image list' to see available images"
        return 1
    fi
    
    # Check if image is being used by any containers
    # 이미지를 사용하는 컨테이너가 있는지 확인
    local containers_using_image
    containers_using_image=$(docker ps -a --filter "ancestor=$image_name" --format "{{.Names}}" | tr '\n' ' ')
    
    if [ -n "$containers_using_image" ]; then
        log "WARNING" "The following containers are using this image: $containers_using_image"
        echo "Stop and remove these containers first, or use --force to remove anyway"
        echo ""
        echo "To stop containers: dockit stop <container_name>"
        echo "To remove containers: dockit down <container_name>"
        return 1
    fi
    
    # Show image information
    # 이미지 정보 표시
    echo "Image to be removed:"
    docker image ls --filter "reference=$image_name" --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.CreatedSince}}\t{{.Size}}"
    echo ""
    
    # Confirmation prompt
    # 확인 프롬프트
    echo -n "Do you want to remove this image? [y/N]: "
    read -r confirm
    
    # Convert to lowercase for comparison
    # 소문자로 변환해서 비교
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    
    # Check confirmation
    # 확인 검사
    if [ "$confirm" != "y" ] && [ "$confirm" != "yes" ]; then
        log "INFO" "Image removal cancelled"
        return 0
    fi
    
    # Remove the image
    # 이미지 제거
    log "INFO" "Removing image '$image_name'..."
    
    if docker rmi "$image_name" 2>/dev/null; then
        log "SUCCESS" "Image '$image_name' has been successfully removed"
    else
        log "ERROR" "Failed to remove image '$image_name'"
        echo "This might happen if:"
        echo "  - Image is still being used by containers"
        echo "  - Image has dependent child images"
        echo "  - Insufficient permissions"
        echo ""
        echo "Use 'docker rmi --force $image_name' to force removal (not recommended)"
        return 1
    fi
}

# Clean unused images (placeholder)
# 사용하지 않는 이미지 정리 (플레이스홀더)
clean_images() {
    log "INFO" "Preparing to clean ALL dockit images..."
    
    # Check if Docker is available
    # Docker 사용 가능 여부 확인
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker is not installed or not in PATH"
        return 1
    fi
    
    # Get all dockit images
    # 모든 dockit 이미지 가져오기
    local all_dockit_images
    all_dockit_images=$(docker image ls --filter "reference=dockit-*" --format "{{.Repository}}")
    
    if [ -z "$all_dockit_images" ]; then
        echo "No dockit images found."
        return 0
    fi
    
    # Collect image information and container usage
    # 이미지 정보와 컨테이너 사용 현황 수집
    local total_images=0
    local images_in_use=0
    local images_unused=0
    local containers_info=""
    
    echo "⚠️  WARNING: This will remove ALL dockit images!"
    echo ""
    echo "📋 Analysis of dockit images to be removed:"
    echo ""
    
    # Use same format as list command
    # list 명령어와 같은 포맷 사용
    local format="%-4s  %-12s  %-13s  %-6s  %-8s  %s\n"
    
    printf "$format" \
        "NO" \
        "IMAGE ID" \
        "CREATED" \
        "SIZE" \
        "STATUS" \
        "NAME"
    
    local index=1
    local all_image_names=()
    
    while IFS= read -r image_name; do
        [ -z "$image_name" ] && continue
        
        all_image_names+=("$image_name")
        
        # Get image details
        # 이미지 상세 정보 가져오기
        local image_info
        image_info=$(docker image ls --filter "reference=$image_name" --format "{{.ID}}\t{{.CreatedSince}}\t{{.Size}}")
        
        if [ -n "$image_info" ]; then
            IFS=$'\t' read -r image_id created_since size <<< "$image_info"
            
            # Check if image is used by any containers
            # 이미지가 컨테이너에서 사용되는지 확인
            local containers_using_image
            containers_using_image=$(docker ps -a --filter "ancestor=$image_name" --format "{{.Names}}" | tr '\n' ' ')
            
            local status
            if [ -n "$containers_using_image" ]; then
                status="IN USE"
                containers_info+="  🔗 $image_name → containers: $containers_using_image"$'\n'
                ((images_in_use++))
            else
                status="UNUSED"
                ((images_unused++))
            fi
            
            # Truncate image ID to 12 characters
            # 이미지 ID를 12자로 자르기
            local image_id_short="${image_id:0:12}"
            
            printf "$format" \
                "$index" \
                "$image_id_short" \
                "$created_since" \
                "$size" \
                "$status" \
                "$image_name"
        fi
        
        ((index++))
        ((total_images++))
    done <<< "$all_dockit_images"
    
    echo ""
    
    # Show container usage information
    # 컨테이너 사용 정보 표시
    if [ $images_in_use -gt 0 ]; then
        echo "🔗 Container dependencies:"
        echo "$containers_info"
    fi
    
    # Calculate total size
    # 총 크기 계산
    local total_size_info
    total_size_info=$(docker image ls --filter "reference=dockit-*" --format "{{.Size}}" | \
        awk '
        BEGIN { total = 0 }
        {
            # Parse size (e.g., "123MB", "1.2GB")
            size = $1
            if (match(size, /([0-9.]+)([A-Z]+)/, m)) {
                value = m[1]
                unit_type = m[2]
                
                # Convert to MB for calculation
                if (unit_type == "GB") value *= 1024
                else if (unit_type == "KB") value /= 1024
                else if (unit_type == "B") value /= (1024*1024)
                
                total += value
            }
        }
        END { 
            if (total >= 1024) {
                printf "%.1fGB", total/1024
            } else {
                printf "%.0fMB", total
            }
        }')
    
    # Summary
    # 요약 정보
    echo "📊 Summary:"
    echo "  • Total images: $total_images"
    echo "  • Images in use: $images_in_use"
    echo "  • Unused images: $images_unused"
    echo "  • Total space to be freed: $total_size_info"
    echo ""
    
    if [ $images_in_use -gt 0 ]; then
        echo "⚠️  WARNING: $images_in_use image(s) are currently being used by containers!"
        echo "   These containers will be STOPPED and REMOVED automatically."
        echo ""
    fi
    
    echo "🚨 DANGER ZONE: This action cannot be undone!"
    echo ""
    
    # First confirmation
    # 1차 확인
    echo -n "Do you really want to remove ALL $total_images dockit images? [y/N]: "
    read -r confirm1
    
    # Convert to lowercase for comparison
    # 소문자로 변환해서 비교
    confirm1=$(echo "$confirm1" | tr '[:upper:]' '[:lower:]')
    
    # Check first confirmation
    # 1차 확인 검사
    if [ "$confirm1" != "y" ] && [ "$confirm1" != "yes" ]; then
        log "INFO" "Image cleanup cancelled"
        return 0
    fi
    
    # Second confirmation with typing challenge
    # 2차 확인 (타이핑 챌린지)
    echo ""
    echo "⚠️  FINAL WARNING: This will permanently delete all dockit images!"
    echo "   Type 'DELETE' (in uppercase) to confirm:"
    echo -n "Confirmation: "
    read -r confirm2
    
    # Check second confirmation
    # 2차 확인 검사
    if [ "$confirm2" != "DELETE" ]; then
        log "INFO" "Image cleanup cancelled - confirmation failed"
        return 0
    fi
    
    # Start cleanup process
    # 정리 프로세스 시작
    echo ""
    log "INFO" "Starting cleanup of ALL dockit images..."
    echo ""
    
    local removed_images=0
    local failed_images=0
    local removed_containers=0
    
    # Remove images (with container cleanup if needed)
    # 이미지 제거 (필요시 컨테이너 정리 포함)
    for image_name in "${all_image_names[@]}"; do
        echo "Processing $image_name..."
        
        # Check for containers using this image
        # 이 이미지를 사용하는 컨테이너 확인
        local containers
        containers=$(docker ps -a --filter "ancestor=$image_name" --format "{{.Names}}" | tr '\n' ' ')
        
        if [ -n "$containers" ]; then
            echo "  📦 Removing containers: $containers"
            
            # Stop and remove containers
            # 컨테이너 중지 및 제거
            for container in $containers; do
                echo -n "    Stopping $container... "
                if docker stop "$container" &>/dev/null; then
                    echo "✓"
                else
                    echo "⚠️"
                fi
                
                echo -n "    Removing $container... "
                if docker rm "$container" &>/dev/null; then
                    echo "✓"
                    ((removed_containers++))
                else
                    echo "✗"
                fi
            done
        fi
        
        # Remove the image
        # 이미지 제거
        echo -n "  🗑️  Removing image... "
        if docker rmi "$image_name" &>/dev/null; then
            echo "✓"
            ((removed_images++))
        else
            echo "✗"
            ((failed_images++))
        fi
        
        echo ""
    done
    
    # Final results
    # 최종 결과
    echo "🏁 Cleanup completed!"
    echo ""
    
    if [ $removed_containers -gt 0 ]; then
        log "INFO" "Removed $removed_containers container(s)"
    fi
    
    if [ $removed_images -gt 0 ]; then
        log "SUCCESS" "Successfully removed $removed_images image(s)"
    fi
    
    if [ $failed_images -gt 0 ]; then
        log "WARNING" "Failed to remove $failed_images image(s)"
        echo "Some images might have complex dependencies"
    fi
    
    if [ $removed_images -eq 0 ] && [ $failed_images -eq 0 ]; then
        log "INFO" "No images were removed"
    fi
    
    echo ""
    echo "💾 Space freed: $total_size_info"
}

# Prune dangling images (placeholder)
# dangling 이미지 정리 (플레이스홀더)
prune_images() {
    log "INFO" "Finding unused dockit images..."
    
    # Check if Docker is available
    # Docker 사용 가능 여부 확인
    if ! command -v docker &> /dev/null; then
        log "ERROR" "Docker is not installed or not in PATH"
        return 1
    fi
    
    # Get all dockit images
    # 모든 dockit 이미지 가져오기
    local all_dockit_images
    all_dockit_images=$(docker image ls --filter "reference=dockit-*" --format "{{.Repository}}")
    
    if [ -z "$all_dockit_images" ]; then
        echo "No dockit images found."
        return 0
    fi
    
    # Find unused images (not used by any containers)
    # 사용하지 않는 이미지 찾기 (어떤 컨테이너에서도 사용하지 않는 것)
    local unused_images=()
    
    while IFS= read -r image_name; do
        [ -z "$image_name" ] && continue
        
        # Check if image is used by any containers (running or stopped)
        # 이미지가 컨테이너에서 사용되는지 확인 (실행 중이거나 중지된 것)
        local containers_using_image
        containers_using_image=$(docker ps -a --filter "ancestor=$image_name" --quiet)
        
        # If no containers use this image, it's unused
        # 이 이미지를 사용하는 컨테이너가 없으면 사용하지 않는 것
        if [ -z "$containers_using_image" ]; then
            unused_images+=("$image_name")
        fi
    done <<< "$all_dockit_images"
    
    # Check if there are any unused images
    # 사용하지 않는 이미지가 있는지 확인
    if [ ${#unused_images[@]} -eq 0 ]; then
        echo "No unused dockit images found."
        echo "All dockit images are currently being used by containers."
        return 0
    fi
    
    # Display unused images
    # 사용하지 않는 이미지들 표시
    echo "Found ${#unused_images[@]} unused dockit image(s):"
    echo ""
    
    # Use same format as list command
    # list 명령어와 같은 포맷 사용
    local format="%-4s  %-12s  %-13s  %-6s  %s\n"
    
    printf "$format" \
        "NO" \
        "IMAGE ID" \
        "CREATED" \
        "SIZE" \
        "NAME"
    
    local index=1
    for image_name in "${unused_images[@]}"; do
        # Get image details
        # 이미지 상세 정보 가져오기
        local image_info
        image_info=$(docker image ls --filter "reference=$image_name" --format "{{.ID}}\t{{.CreatedSince}}\t{{.Size}}")
        
        if [ -n "$image_info" ]; then
            IFS=$'\t' read -r image_id created_since size <<< "$image_info"
            
            # Truncate image ID to 12 characters
            # 이미지 ID를 12자로 자르기
            local image_id_short="${image_id:0:12}"
            
            printf "$format" \
                "$index" \
                "$image_id_short" \
                "$created_since" \
                "$size" \
                "$image_name"
        fi
        
        ((index++))
    done
    
    echo ""
    
    # Calculate total size for display
    # 총 크기 계산해서 표시
    local total_size_info
    total_size_info=$(docker image ls --filter "reference=dockit-*" --format "{{.Repository}} {{.Size}}" | \
        awk -v images="$(printf '%s\n' "${unused_images[@]}")" '
        BEGIN { total = 0; unit = "B" }
        {
            # Check if current image is in unused list
            for (i = 1; i <= split(images, arr, "\n"); i++) {
                if ($1 == arr[i]) {
                    # Parse size (e.g., "123MB", "1.2GB")
                    size = $2
                    if (match(size, /([0-9.]+)([A-Z]+)/, m)) {
                        value = m[1]
                        unit_type = m[2]
                        
                        # Convert to MB for calculation
                        if (unit_type == "GB") value *= 1024
                        else if (unit_type == "KB") value /= 1024
                        else if (unit_type == "B") value /= (1024*1024)
                        
                        total += value
                    }
                    break
                }
            }
        }
        END { 
            if (total >= 1024) {
                printf "%.1fGB", total/1024
            } else {
                printf "%.0fMB", total
            }
        }')
    
    echo "Total space to be freed: $total_size_info"
    echo ""
    
    # Confirmation prompt
    # 확인 프롬프트
    echo -n "Do you want to remove these unused images? [y/N]: "
    read -r confirm
    
    # Convert to lowercase for comparison
    # 소문자로 변환해서 비교
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    
    # Check confirmation
    # 확인 검사
    if [ "$confirm" != "y" ] && [ "$confirm" != "yes" ]; then
        log "INFO" "Image pruning cancelled"
        return 0
    fi
    
    # Remove unused images
    # 사용하지 않는 이미지들 제거
    echo ""
    log "INFO" "Removing unused dockit images..."
    
    local removed_count=0
    local failed_count=0
    
    for image_name in "${unused_images[@]}"; do
        echo -n "Removing $image_name... "
        
        if docker rmi "$image_name" &>/dev/null; then
            echo "✓"
            ((removed_count++))
        else
            echo "✗"
            ((failed_count++))
        fi
    done
    
    echo ""
    
    # Show results
    # 결과 표시
    if [ $removed_count -gt 0 ]; then
        log "SUCCESS" "Successfully removed $removed_count unused image(s)"
    fi
    
    if [ $failed_count -gt 0 ]; then
        log "WARNING" "Failed to remove $failed_count image(s)"
        echo "Some images might have dependencies or be referenced by other images"
    fi
    
    if [ $removed_count -eq 0 ] && [ $failed_count -eq 0 ]; then
        log "INFO" "No images were removed"
    fi
}

# Main function for image module
# image 모듈의 메인 함수
image_main() {
    # Check if arguments are provided
    # 인자가 제공되었는지 확인
    if [ $# -eq 0 ]; then
        show_usage
        return 0
    fi
    
    # Process commands
    # 명령어 처리
    case "$1" in
        "list")
            list_images
            ;;
        "remove")
            if [ -n "$2" ]; then
                remove_image "$2"
            else
                log "ERROR" "Image name required for remove command"
                echo "Usage: dockit image remove <image_name_or_number>"
                return 1
            fi
            ;;
        "clean")
            clean_images
            ;;
        "prune")
            prune_images
            ;;
        *)
            log "ERROR" "Unknown command: $1"
            show_usage
            return 1
            ;;
    esac
}

# Run main function if this script is called directly
# 이 스크립트가 직접 호출될 경우 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    image_main "$@"
fi 