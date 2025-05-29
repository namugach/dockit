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

# Build Docker image
# Docker 이미지 빌드
build_docker_image() {
    local cache_option="$1"
    log "INFO" "$MSG_BUILDING_IMAGE: $IMAGE_NAME"
    
    # Use existing Dockerfile from .dockit_project
    # .dockit_project의 기존 Dockerfile 사용
    local dockerfile="$DOCKIT_PROJECT_DIR/Dockerfile"
    
    # Check if Dockerfile exists
    # Dockerfile 존재 확인
    if [ ! -f "$dockerfile" ]; then
        log "ERROR" "Dockerfile not found: $dockerfile"
        log "INFO" "Run 'dockit init' first to create Dockerfile"
        return 1
    fi
    
    # Build image using existing Dockerfile
    # 기존 Dockerfile을 사용하여 이미지 빌드
    local build_cmd="docker build -t $IMAGE_NAME -f $dockerfile"
    if [ "$cache_option" = "--no-cache" ]; then
        build_cmd="$build_cmd --no-cache"
        log "INFO" "캐시 없이 이미지를 빌드합니다..."
    fi
    build_cmd="$build_cmd ."
    
    if eval "$build_cmd"; then
        log "SUCCESS" "$MSG_IMAGE_BUILT: $IMAGE_NAME"
        return 0
    else
        log "ERROR" "$MSG_IMAGE_BUILD_FAILED"
        return 1
    fi
}

# Main function for build module
# build 모듈의 메인 함수
build_main() {
    local cache_option=""
    
    # Parse arguments for cache options
    # 캐시 옵션 인자 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-cache)
                cache_option="--no-cache"
                shift
                ;;
            *)
                log "WARNING" "알 수 없는 옵션: $1"
                shift
                ;;
        esac
    done
    
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
    build_docker_image "$cache_option"
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    build_main "$@"
fi 