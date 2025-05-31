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
    echo "  clean               - Remove unused images (coming soon)"
    echo "  prune               - Remove dangling images (coming soon)"
    echo ""
    echo "Examples:"
    echo "  dockit image list"
    echo "  dockit image remove 1                        # Remove by number"
    echo "  dockit image remove dockit-home-user-project # Remove by name"
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
    log "INFO" "Image cleanup feature coming soon..."
    # TODO: Implement cleanup logic
}

# Prune dangling images (placeholder)
# dangling 이미지 정리 (플레이스홀더)
prune_images() {
    log "INFO" "Image pruning feature coming soon..."
    # TODO: Implement prune logic
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