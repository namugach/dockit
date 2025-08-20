#!/bin/bash

# Build module - Build Docker image for development environment
# build 모듈 - Docker 개발 환경용 이미지 빌드

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$MODULES_DIR/container_base.sh"
source "$MODULES_DIR/registry.sh"
source "$UTILS_DIR/async_tasks.sh"

# Check and set BASE_IMAGE if not already set
# BASE_IMAGE가 설정되지 않은 경우 확인 및 설정
check_base_image() {
    if [ -z "$BASE_IMAGE" ]; then
        log "WARNING" "$MSG_BASE_IMAGE_NOT_SET"
        # 현재 언어에 맞는 기본 이미지 사용
        BASE_IMAGE="$DEFAULT_IMAGE"
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
        log "ERROR" "$MSG_BUILD_DOCKERFILE_NOT_FOUND $dockerfile"
        log "INFO" "$MSG_BUILD_RUN_INIT_FIRST"
        return 1
    fi
    
    # Build image using existing Dockerfile
    # 기존 Dockerfile을 사용하여 이미지 빌드
    local build_cmd="docker build -t $IMAGE_NAME -f $dockerfile"
    if [ "$cache_option" = "--no-cache" ]; then
        build_cmd="$build_cmd --no-cache"
        log "INFO" "$MSG_BUILD_NO_CACHE"
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
    # Docker 사용 가능 여부 확인
    if ! command -v docker &> /dev/null; then
        log "ERROR" "$MSG_COMMON_DOCKER_NOT_FOUND"
        return 1
    fi

    # 인자가 없는 경우 사용법 표시
    if [ $# -eq 0 ]; then
        show_usage
        return 0
    fi
    
    # 첫 번째 인자에 따른 처리
    case "$1" in
        "this")
            # this 인자 처리 - 캐시 옵션 확인
            shift
            local cache_option=""
            if [ "$1" = "--no-cache" ]; then
                cache_option="--no-cache"
            fi
            handle_this_argument "$cache_option"
            ;;
        "all")
            # all 인자 처리
            shift
            handle_all_argument "$@"
            ;;
        *)
            # 숫자 인자 처리 시도
            if handle_numeric_arguments "$@"; then
                return 0
            else
                # 잘못된 인자 처리
                log "ERROR" "$MSG_BUILD_INVALID_ARGUMENT"
                show_usage
            fi
            ;;
    esac
    
    return 0
}

# Show usage function
# 사용법 표시 함수
show_usage() {
    log "INFO" "$MSG_BUILD_USAGE_TITLE"
    echo -e "  $MSG_BUILD_USAGE_NUMBER"
    echo -e "  $MSG_BUILD_USAGE_THIS"
    echo -e "  $MSG_BUILD_USAGE_ALL"
    echo ""
}

# Handle "this" argument (build current project)
# "this" 인자 처리 (현재 프로젝트 빌드)
handle_this_argument() {
    local cache_option="$1"
    
    # Check if .dockit_project directory exists
    if [[ ! -d .dockit_project ]]; then
        log "WARNING" "$MSG_BUILD_NOT_DOCKIT_PROJECT"
        return 1
    fi

    log "INFO" "$MSG_BUILD_STARTING_CURRENT"
    
    # Check if project is initialized
    if [ ! -d "$DOCKIT_PROJECT_DIR" ]; then
        log "ERROR" "$MSG_COMMON_NOT_INITIALIZED"
        return 1
    fi
    
    # Load environment variables
    load_env
    
    # Check for base image changes and handle accordingly
    # 베이스 이미지 변경 확인은 up.sh에서 이미 처리되므로 build.sh에서는 생략
    # Base image change check is already handled in up.sh, so skip it in build.sh
    
    # Stop and remove existing container if running
    if [ -n "$CONTAINER_NAME" ] && docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
            log "INFO" "$MSG_BUILD_STOPPING_CONTAINER $CONTAINER_NAME"
            docker stop "$CONTAINER_NAME" >/dev/null 2>&1
        fi
        log "INFO" "$MSG_BUILD_REMOVING_CONTAINER $CONTAINER_NAME"
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1
    fi
    
    # Build image
    if build_docker_image "$cache_option"; then
        # Update project state to ready
        local project_id
        if project_id=$(get_current_project_id); then
            update_project_state "$project_id" "$PROJECT_STATE_READY"
            log "INFO" "$MSG_BUILD_STATE_UPDATED_READY"
            
            # Update base image info in registry after successful build
            # 빌드 성공 후 레지스트리에 베이스 이미지 정보 업데이트
            update_base_image_in_registry "$project_id" "$BASE_IMAGE" "$IMAGE_NAME"
        fi
        return 0
    else
        # Update project state to error on build failure
        local project_id
        if project_id=$(get_current_project_id); then
            update_project_state "$project_id" "$PROJECT_STATE_ERROR"
            log "ERROR" "$MSG_BUILD_STATE_UPDATED_ERROR"
        fi
        return 1
    fi
}

# Project-specific build action function
# 프로젝트별 빌드 액션 함수
project_build_action() {
    local project_path="$1"
    local project_id="$2"
    local cache_option="$3"
    
    # Change to project directory
    cd "$project_path" || return 1
    
    # Load configuration
    if [ -f ".dockit_project/.env" ]; then
        source ".dockit_project/.env"
    else
        return 1
    fi
    
    # Check Dockerfile exists
    local dockerfile=".dockit_project/Dockerfile"
    if [ ! -f "$dockerfile" ]; then
        return 1
    fi
    
    # Stop and remove existing container if running
    if [ -n "$CONTAINER_NAME" ] && docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
            docker stop "$CONTAINER_NAME" >/dev/null 2>&1
        fi
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1
    fi
    
    # Build image
    local build_cmd="docker build -t $IMAGE_NAME -f $dockerfile"
    if [ "$cache_option" = "--no-cache" ]; then
        build_cmd="$build_cmd --no-cache"
    fi
    build_cmd="$build_cmd ."
    
    if eval "$build_cmd" >/dev/null 2>&1; then
        # Success - update state to ready
        update_project_state "$project_id" "$PROJECT_STATE_READY"
        return 0
    else
        # Failure - update state to error
        update_project_state "$project_id" "$PROJECT_STATE_ERROR"
        return 1
    fi
}

# Handle numeric arguments (build container by number)
# 숫자 인자 처리 (번호로 컨테이너 빌드)
handle_numeric_arguments() {
    local cache_option=""
    local -a indices=()
    
    # Parse arguments to separate cache options and indices
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-cache)
                cache_option="--no-cache"
                shift
                ;;
            *)
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    indices+=("$1")
                else
                    log "ERROR" "$MSG_BUILD_INVALID_ARG_VALUE $1"
                    return 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if any indices provided
    if [ ${#indices[@]} -eq 0 ]; then
        log "ERROR" "$MSG_BUILD_SPECIFY_PROJECT_NUMBER"
        return 1
    fi

    # Get registry
    local registry_file="$HOME/.dockit/registry.json"
    if [ ! -f "$registry_file" ]; then
        log "ERROR" "$MSG_BUILD_REGISTRY_NOT_FOUND"
        return 1
    fi
    
    local registry_json=$(cat "$registry_file")
    local project_ids=()
    
    # Create project ID array
    while IFS= read -r project_id; do
        project_ids+=("$project_id")
    done < <(echo "$registry_json" | jq -r 'keys[]')

    # Process each index
    for idx in "${indices[@]}"; do
        local array_idx=$((idx-1))
        local project_id=${project_ids[$array_idx]:-}

        if [[ -z "$project_id" ]]; then
            log "ERROR" "$MSG_BUILD_INVALID_PROJECT_NUMBER $idx"
            continue
        fi

        # Get project path
        local project_path=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
        local project_name=$(basename "$project_path")
        
        # Validate project path
        if [ ! -d "$project_path" ] || [ ! -f "$project_path/.dockit_project/Dockerfile" ]; then
            log "ERROR" "$(printf "$MSG_BUILD_PROJECT_NOT_FOUND" "$idx" "$project_name")"
            continue
        fi
        
        local spinner="$(printf "%s %s (%s) %s" "project" "$idx" "$project_name" "$MSG_BUILD_SPINNER_BUILDING")"
        
        # Add build task to background execution
        add_task "$spinner" \
            "project_build_action '$project_path' '$project_id' '$cache_option' >/dev/null 2>&1"
    done

    async_tasks_no_exit "$MSG_BUILD_TASK_COMPLETE"
}

# Handle "all" argument (build all projects)
# "all" 인자 처리 (모든 프로젝트 빌드)
handle_all_argument() {
    local cache_option=""
    
    # Parse cache option
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-cache)
                cache_option="--no-cache"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    log "INFO" "$MSG_BUILD_STARTING_ALL"
    
    # Get registry
    local registry_file="$HOME/.dockit/registry.json"
    if [ ! -f "$registry_file" ]; then
        log "ERROR" "$MSG_BUILD_REGISTRY_NOT_FOUND"
        return 1
    fi
    
    local registry_json=$(cat "$registry_file")
    local project_ids=()
    
    # Create project ID array
    while IFS= read -r project_id; do
        project_ids+=("$project_id")
    done < <(echo "$registry_json" | jq -r 'keys[]')

    if [[ ${#project_ids[@]} -eq 0 ]]; then
        log "INFO" "$MSG_BUILD_NO_PROJECTS"
        return 0
    fi

    # Process each project
    for project_id in "${project_ids[@]}"; do
        # Get project path
        local project_path=$(echo "$registry_json" | jq -r --arg id "$project_id" '.[$id].path')
        local project_name=$(basename "$project_path")
        
        # Validate project path
        if [ ! -d "$project_path" ] || [ ! -f "$project_path/.dockit_project/Dockerfile" ]; then
            log "WARNING" "$(printf "$MSG_BUILD_PROJECT_NOT_VALID" "$project_name")"
            continue
        fi
        
        local spinner="$(printf "%s %s %s" "project" "$project_name" "$MSG_BUILD_SPINNER_BUILDING")"
        
        # Add build task to background execution
        add_task "$spinner" \
            "project_build_action '$project_path' '$project_id' '$cache_option' >/dev/null 2>&1"
    done

    async_tasks_no_exit "$MSG_BUILD_TASK_COMPLETE"
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    build_main "$@"
fi 