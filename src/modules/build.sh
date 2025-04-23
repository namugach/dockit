#!/bin/bash

# Build module - Build Docker image for development environment
# build 모듈 - Docker 개발 환경용 이미지 빌드

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Check and set BASE_IMAGE if not already set
# BASE_IMAGE가 설정되지 않은 경우 확인 및 설정
check_base_image() {
    if [ -z "$BASE_IMAGE" ]; then
        log "WARNING" "$MSG_BASE_IMAGE_NOT_SET"
        # 현재 언어에 맞는 기본 이미지 사용
        BASE_IMAGE="${DEFAULT_IMAGES["$LANGUAGE"]}"
    fi
    log "INFO" "$MSG_USING_BASE_IMAGE: $BASE_IMAGE"
}

# Process template using multilingual settings system
# 다국어 설정 시스템을 사용하여 템플릿 처리
process_multilang_template() {
    local temp_dockerfile="$1"
    log "INFO" "$MSG_MULTILANG_SETTINGS: BASE_IMAGE=$BASE_IMAGE"
    process_template_with_base_image "$DOCKERFILE_TEMPLATE" "$temp_dockerfile"
}

# Process template using traditional method
# 기존 방식으로 템플릿 처리
process_traditional_template() {
    local temp_dockerfile="$1"
    log "INFO" "$MSG_PROCESSING_TEMPLATE"
    
    # Read and process template content
    # 템플릿 내용 읽기 및 처리
    local template_content=$(<"$DOCKERFILE_TEMPLATE")
    echo "$template_content" | \
    sed "1s|^FROM .*|FROM $BASE_IMAGE|" | \
    sed -e "s|\${USERNAME}|${USERNAME}|g" \
        -e "s|\${USER_UID}|${USER_UID}|g" \
        -e "s|\${USER_GID}|${USER_GID}|g" \
        -e "s|\${WORKDIR}|${WORKDIR}|g" \
        -e "s|\${USER_PASSWORD}|${USER_PASSWORD}|g" \
    > "$temp_dockerfile"
}

# Create temporary Dockerfile with proper base image and substitutions
# 적절한 베이스 이미지와 치환으로 임시 Dockerfile 생성
create_temp_dockerfile() {
    local temp_dockerfile="$1"
    
    # Check and set BASE_IMAGE
    # BASE_IMAGE 확인 및 설정
    check_base_image
    
    # Process template based on available functions
    # 사용 가능한 함수에 따라 템플릿 처리
    if [ -f "$PROJECT_ROOT/config/system.sh" ] && type process_template_with_base_image &>/dev/null; then
        process_multilang_template "$temp_dockerfile"
    else
        process_traditional_template "$temp_dockerfile"
    fi
}

# Build Docker image from temporary Dockerfile
# 임시 Dockerfile로 Docker 이미지 빌드
build_image_from_temp() {
    local temp_dockerfile="$1"
    
    if docker build -t "$IMAGE_NAME" -f "$temp_dockerfile" .; then
        log "SUCCESS" "$MSG_IMAGE_BUILT: $IMAGE_NAME"
        rm -f "$temp_dockerfile"
        return 0
    else
        log "ERROR" "$MSG_IMAGE_BUILD_FAILED"
        rm -f "$temp_dockerfile"
        return 1
    fi
}

# Build Docker image
# Docker 이미지 빌드
build_docker_image() {
    log "INFO" "$MSG_BUILDING_IMAGE: $IMAGE_NAME"
    
    # Create and process temporary Dockerfile
    # 임시 Dockerfile 생성 및 처리
    local temp_dockerfile="$PROJECT_ROOT/.dockerfile.tmp"
    create_temp_dockerfile "$temp_dockerfile"
    
    # Build image using temporary Dockerfile
    # 임시 Dockerfile을 사용하여 이미지 빌드
    build_image_from_temp "$temp_dockerfile"
}

# Build Docker image if user confirms
# 사용자 확인 후 Docker 이미지 빌드
build_image_if_confirmed() {
    # Dockerfile이 있는지 확인
    if [ ! -f "$DOCKERFILE" ]; then
        log "ERROR" "$MSG_DOCKERFILE_NOT_FOUND"
        return 1
    fi
    
    # 이미지 빌드 여부 확인
    echo -e "\n${YELLOW}$MSG_BUILD_IMAGE_PROMPT${NC}"
    read -p "$MSG_SELECT_CHOICE [Y/n]: " build_image
    build_image=${build_image:-y}
    
    if [[ $build_image == "y" || $build_image == "Y" ]]; then
        build_docker_image
        return $?
    else
        log "INFO" "$MSG_EXIT_IMAGE_BUILD"
        return 1
    fi
}

# Main function for build module
# build 모듈의 메인 함수
build_main() {
    # Log start message
    log "INFO" "$MSG_BUILD_START"
    
    # Check if project is initialized
    if [ ! -d "$DOCKIT_PROJECT_DIR" ]; then
        log "ERROR" "$MSG_COMMON_NOT_INITIALIZED"
        return 1
    fi
    
    # Load environment variables
    load_env
    
    # Trap ctrl-c
    trap 'echo -e "\n${YELLOW}$MSG_PROCESS_CANCELLED_BY_USER${NC}"; exit 1' INT
    
    # Build image with confirmation
    if build_image_if_confirmed; then
        log "SUCCESS" "$MSG_BUILD_COMPLETE"
        return 0
    else
        if [ $? -eq 1 ]; then
            log "INFO" "$MSG_BUILD_CANCELLED"
        else
            log "ERROR" "$MSG_BUILD_FAILED"
        fi
        return 1
    fi
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    build_main "$@"
fi 