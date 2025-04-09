#!/bin/bash

# Init module - Initial setup of Docker development environment
# init 모듈 - Docker 개발 환경 초기 설정

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Define additional variables
# 추가 변수 정의
DOCKIT_DIR="$PROJECT_ROOT/.dockit"
DOCKERFILE="$DOCKIT_DIR/Dockerfile"

# User input function
# 사용자 입력 함수
get_user_input() {
    log "INFO" "사용자 입력 받는 중..."
    
    # Load default values
    # 기본값 로드
    load_config
    
    echo -e "\n${GREEN}$MSG_WELCOME${NC}"
    echo -e "${BLUE}$MSG_INPUT_DEFAULT${NC}"
    
    # Display current settings
    # 현재 설정 표시
    echo -e "\n${YELLOW}$MSG_CURRENT_SETTINGS:${NC}"
    echo -e "$MSG_USERNAME: ${GREEN}${USERNAME:-$DEFAULT_USERNAME}${NC}"
    echo -e "$MSG_USER_UID: ${GREEN}${USER_UID:-$DEFAULT_UID}${NC}"
    echo -e "$MSG_USER_GID: ${GREEN}${USER_GID:-$DEFAULT_GID}${NC}"
    echo -e "$MSG_PASSWORD: ${GREEN}${USER_PASSWORD:-$DEFAULT_PASSWORD}${NC}"
    echo -e "$MSG_WORKDIR: ${GREEN}${WORKDIR:-$DEFAULT_WORKDIR}${NC}"
    echo -e "$MSG_IMAGE_NAME: ${GREEN}${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}${NC}"
    echo -e "$MSG_CONTAINER_NAME: ${GREEN}${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}${NC}"
    
    # Selection options
    # 선택 옵션
    echo -e "\n${BLUE}$MSG_SELECT_OPTION:${NC}"
    echo -e "${GREEN}y${NC} - $MSG_USE_DEFAULT"
    echo -e "${YELLOW}n${NC} - $MSG_MODIFY_VALUES"
    echo -e "${RED}c${NC} - $MSG_CANCEL"
    read -p "$MSG_SELECT_CHOICE [Y/n/c]: " choice
    choice=${choice:-y}
    
    case "$choice" in
        y|Y)
            # Use default values
            # 기본값 사용
            USERNAME=${USERNAME:-$DEFAULT_USERNAME}
            USER_UID=${USER_UID:-$DEFAULT_UID}
            USER_GID=${USER_GID:-$DEFAULT_GID}
            USER_PASSWORD=${USER_PASSWORD:-$DEFAULT_PASSWORD}
            WORKDIR=${WORKDIR:-$DEFAULT_WORKDIR}
            IMAGE_NAME=${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}
            CONTAINER_NAME=${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}
            ;;
        n|N)
            # Get user input for each value
            # 각 값에 대한 사용자 입력 받기
            read -p "$MSG_INPUT_USERNAME [${USERNAME:-$DEFAULT_USERNAME}]: " input
            USERNAME=${input:-${USERNAME:-$DEFAULT_USERNAME}}
            
            read -p "$MSG_INPUT_UID [${USER_UID:-$DEFAULT_UID}]: " input
            USER_UID=${input:-${USER_UID:-$DEFAULT_UID}}
            
            read -p "$MSG_INPUT_GID [${USER_GID:-$DEFAULT_GID}]: " input
            USER_GID=${input:-${USER_GID:-$DEFAULT_GID}}
            
            read -p "$MSG_INPUT_PASSWORD [${USER_PASSWORD:-$DEFAULT_PASSWORD}]: " input
            USER_PASSWORD=${input:-${USER_PASSWORD:-$DEFAULT_PASSWORD}}
            
            read -p "$MSG_INPUT_WORKDIR [${WORKDIR:-$DEFAULT_WORKDIR}]: " input
            WORKDIR=${input:-${WORKDIR:-$DEFAULT_WORKDIR}}
            
            read -p "$MSG_INPUT_IMAGE_NAME [${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}]: " input
            IMAGE_NAME=${input:-${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}}
            
            read -p "$MSG_INPUT_CONTAINER_NAME [${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}]: " input
            CONTAINER_NAME=${input:-${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}}
            ;;
        c|C)
            # Cancel
            # 취소
            log "INFO" "$MSG_INIT_CANCELLED"
            exit 0
            ;;
        *)
            # Invalid input
            # 잘못된 입력
            log "ERROR" "$MSG_INVALID_CHOICE"
            exit 1
            ;;
    esac
    
    # Confirm final settings
    # 최종 설정 정보 확인
    echo -e "\n${YELLOW}$MSG_FINAL_SETTINGS:${NC}"
    echo -e "$MSG_USERNAME: ${GREEN}$USERNAME${NC}"
    echo -e "$MSG_USER_UID: ${GREEN}$USER_UID${NC}"
    echo -e "$MSG_USER_GID: ${GREEN}$USER_GID${NC}"
    echo -e "$MSG_PASSWORD: ${GREEN}$USER_PASSWORD${NC}"
    echo -e "$MSG_WORKDIR: ${GREEN}$WORKDIR${NC}"
    echo -e "$MSG_IMAGE_NAME: ${GREEN}$IMAGE_NAME${NC}"
    echo -e "$MSG_CONTAINER_NAME: ${GREEN}$CONTAINER_NAME${NC}"
    
    # Save settings
    # 설정 저장
    save_config
}

# Create Dockerfile from template
# Docker Compose 템플릿 파일 생성
create_dockerfile() {
    log "INFO" "$MSG_CREATING_DOCKERFILE"
    
    # Create necessary directories
    # 필요한 디렉토리 생성
    mkdir -p "$(dirname "$DOCKERFILE")"
    
    # Generate Dockerfile
    # Dockerfile 생성
    process_template "$DOCKERFILE_TEMPLATE" "$DOCKERFILE"
    
    if [ $? -eq 0 ]; then
        log "SUCCESS" "$MSG_DOCKERFILE_CREATED"
    else
        log "ERROR" "$MSG_DOCKERFILE_FAILED"
        return 1
    fi
}

# Build Docker image
# Docker 이미지 빌드
build_docker_image() {
    log "INFO" "$MSG_BUILDING_IMAGE: $IMAGE_NAME"
    
    # Create temporary Dockerfile with substitutions
    # 치환된 Dockerfile 생성 (임시 파일)
    local temp_dockerfile="$PROJECT_ROOT/.dockerfile.tmp"
    
    # Check if BASE_IMAGE is set
    # BASE_IMAGE가 설정되어 있는지 확인
    if [ -z "$BASE_IMAGE" ]; then
        log "WARNING" "$MSG_BASE_IMAGE_NOT_SET"
        BASE_IMAGE="namugach/ubuntu-basic:24.04-kor-deno"
    fi
    
    log "INFO" "$MSG_USING_BASE_IMAGE: $BASE_IMAGE"
    
    # Check if config/system.sh exists and process_template_with_base_image function is available
    # config/system.sh가 있고 process_template_with_base_image 함수가 사용 가능한지 확인
    if [ -f "$PROJECT_ROOT/config/system.sh" ] && type process_template_with_base_image &>/dev/null; then
        log "INFO" "$MSG_MULTILANG_SETTINGS: BASE_IMAGE=$BASE_IMAGE"
        
        # Use template processing function from multilingual settings system
        # 다국어 설정 시스템의 템플릿 처리 함수 사용
        process_template_with_base_image "$DOCKERFILE_TEMPLATE" "$temp_dockerfile"
    else
        # Process template using traditional method
        # 기존 방식으로 템플릿 처리
        log "INFO" "$MSG_PROCESSING_TEMPLATE"
        
        # Read template file
        # 템플릿 파일 읽기
        local template_content=$(<"$DOCKERFILE_TEMPLATE")
        
        # Replace FROM image in first line with BASE_IMAGE and process other variables
        # 첫 줄의 FROM 이미지를 BASE_IMAGE로 교체하고 다른 변수 처리
        echo "$template_content" | \
        sed "1s|^FROM .*|FROM $BASE_IMAGE|" | \
        sed -e "s|\${USERNAME}|${USERNAME}|g" \
            -e "s|\${USER_UID}|${USER_UID}|g" \
            -e "s|\${USER_GID}|${USER_GID}|g" \
            -e "s|\${WORKDIR}|${WORKDIR}|g" \
            -e "s|\${USER_PASSWORD}|${USER_PASSWORD}|g" \
        > "$temp_dockerfile"
    fi
    
    # Build image
    # 이미지 빌드
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

# Create Docker Compose file
# Docker Compose 파일 생성
create_docker_compose() {
    log "INFO" "$MSG_CREATING_COMPOSE"
    
    # Create necessary directories
    # 필요한 디렉토리 생성
    mkdir -p "$(dirname "$DOCKER_COMPOSE_FILE")"
    
    # Generate Docker Compose file
    # Docker Compose 파일 생성
    process_template "$DOCKER_COMPOSE_TEMPLATE" "$DOCKER_COMPOSE_FILE"
    
    if [ $? -eq 0 ]; then
        log "SUCCESS" "$MSG_COMPOSE_CREATED"
    else
        log "ERROR" "$MSG_COMPOSE_FAILED"
        return 1
    fi
}

# Main function
# 메인 함수
init_main() {
    log "INFO" "$MSG_INIT_START"
    
    # Create .dockit directory
    # .dockit 디렉토리 생성
    if [ ! -d "$DOCKIT_DIR" ]; then
        log "INFO" "$MSG_CREATING_DOCKIT_DIR"
        mkdir -p "$DOCKIT_DIR"
        log "SUCCESS" "$MSG_DOCKIT_DIR_CREATED"
    fi
    
    # Check and clean up old version files
    # 이전 버전의 파일이 있는지 확인하고 정리
    if [ -f "$PROJECT_ROOT/docker-tools.log" ]; then
        log "INFO" "$MSG_OLD_LOG_FOUND"
        rm -f "$PROJECT_ROOT/docker-tools.log"
        log "SUCCESS" "$MSG_OLD_LOG_REMOVED"
    fi
    
    # Move files from root to new location
    # 이전에 루트에 있던 파일들을 새 위치로 이동
    if [ -f "$PROJECT_ROOT/.env" ]; then
        log "INFO" "$MSG_MOVING_ENV"
        mv "$PROJECT_ROOT/.env" "$CONFIG_FILE"
        log "SUCCESS" "$MSG_ENV_MOVED"
    fi
    
    if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        log "INFO" "$MSG_MOVING_COMPOSE"
        mv "$PROJECT_ROOT/docker-compose.yml" "$DOCKER_COMPOSE_FILE"
        log "SUCCESS" "$MSG_COMPOSE_MOVED"
    fi
    
    if [ -f "$PROJECT_ROOT/dockit.log" ]; then
        log "INFO" "$MSG_MOVING_LOG"
        mv "$PROJECT_ROOT/dockit.log" "$LOG_FILE"
        log "SUCCESS" "$MSG_LOG_MOVED"
    fi
    
    # Get user input
    # 사용자 입력 받기
    get_user_input
    
    # Create template files
    # 템플릿 파일 생성
    create_dockerfile
    
    # Build Docker image
    # Docker 이미지 빌드
    build_docker_image
    
    # Create Docker Compose file
    # Docker Compose 파일 생성
    create_docker_compose
    
    # Ask if container should be started
    # 컨테이너 시작 여부 확인
    echo -e "\n${YELLOW}$MSG_START_CONTAINER_NOW?${NC}"
    read -p "$MSG_SELECT_CHOICE [Y/n]: " start_container
    start_container=${start_container:-y}
    
    if [[ $start_container == "y" || $start_container == "Y" ]]; then
        log "INFO" "$MSG_STARTING_CONTAINER"
        
        if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d; then
            log "SUCCESS" "$MSG_CONTAINER_STARTED"
            
            # Ask if user wants to connect to container
            # 컨테이너 접속 여부 확인
            echo -e "\n${YELLOW}$MSG_CONNECT_CONTAINER_NOW?${NC}"
            read -p "$MSG_SELECT_CHOICE [Y/n]: " connect_container
            connect_container=${connect_container:-y}
            
            if [[ $connect_container == "y" || $connect_container == "Y" ]]; then
                log "INFO" "$MSG_CONNECTING_CONTAINER"
                docker exec -it "$CONTAINER_NAME" bash
            fi
        else
            log "ERROR" "$MSG_CONTAINER_START_FAILED"
            return 1
        fi
    fi
    
    log "SUCCESS" "$MSG_INIT_COMPLETE"
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_main
fi 