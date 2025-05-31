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
    echo "  remove <image>      - Remove specific image (coming soon)"
    echo "  clean               - Remove unused images (coming soon)"
    echo "  prune               - Remove dangling images (coming soon)"
    echo ""
    echo "Examples:"
    echo "  dockit image list"
    echo "  dockit image remove dockit-home-user-project"
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

# Remove specific image (placeholder)
# 특정 이미지 제거 (플레이스홀더)
remove_image() {
    local image_name="$1"
    log "INFO" "Image removal feature coming soon..."
    echo "Will remove image: $image_name"
    # TODO: Implement image removal logic
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
                echo "Usage: dockit image remove <image_name>"
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