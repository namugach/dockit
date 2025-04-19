#!/bin/bash

# Init module - Initial setup of Docker development environment
# init 모듈 - Docker 개발 환경 초기 설정

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" "init"

# 버전 정보 로드
# Load version information
VERSION_FILE="$PROJECT_ROOT/bin/VERSION"
if [ -f "$VERSION_FILE" ]; then
    VERSION=$(cat "$VERSION_FILE")
else
    VERSION="unknown"
fi

# Define additional variables
# 추가 변수 정의
DOCKIT_DIR="$(pwd)/.dockit_project"
DOCKERFILE="$DOCKIT_DIR/Dockerfile"
DOCKER_COMPOSE_FILE="$DOCKIT_DIR/docker-compose.yml"
CONFIG_FILE="$DOCKIT_DIR/.env"
LOG_FILE="$DOCKIT_DIR/dockit.log"


# Display version information
# 버전 정보 표시
display_version_info() {
    echo -e "\n${BLUE}$(printf "$MSG_INIT_VERSION_HEADER" "$VERSION")${NC}"
    echo -e "${BLUE}$MSG_INIT_VERSION_SEPARATOR${NC}\n"
}


# Main function
# 메인 함수
# Initialize .dockit_project directory and move legacy files
# .dockit_project 디렉토리 초기화 및 레거시 파일 이동
init_project() {
    # 초기화 작업
    # Initialization tasks
    
    # 도움말 표시 체크
    # Check if help should be displayed
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        echo "$(get_message MSG_INIT_HELP)"
        exit 0
    fi
    
    # 기존 설정 백업
    # Backup existing settings
    if [ -d ".dockit_project" ]; then
        echo "이미 초기화된 프로젝트입니다. 다시 초기화하시겠습니까? (y/N)"
        echo "Project is already initialized. Do you want to re-initialize? (y/N)"
        read -r answer
        
        if [[ ! $answer =~ ^[Yy]$ ]]; then
            echo "초기화가 취소되었습니다."
            echo "Initialization has been cancelled."
            exit 0
        fi
        
        # 백업 디렉토리 이름 생성 (현재 날짜시간 사용)
        # Create backup directory name (using current date and time)
        backup_dir=".dockit_backup_$(date +%Y%m%d_%H%M%S)"
        
        echo "기존 설정을 ${backup_dir}로 백업합니다."
        echo "Backing up existing settings to ${backup_dir}."
        
        mv ".dockit_project" "$backup_dir"
        
        # 새 .env 파일에 백업 정보 추가
        # Add backup information to new .env file
        backup_info="PREVIOUS_CONFIG=\"$backup_dir\""
    fi
}

####################################################################
#                         get_user_input                           #
####################################################################


# Display current configuration settings
# 현재 설정값 표시
display_current_settings() {
    echo -e "\n${YELLOW}$MSG_CURRENT_SETTINGS:${NC}"
    echo -e "$MSG_USERNAME: ${GREEN}${USERNAME:-$DEFAULT_USERNAME}${NC}"
    echo -e "$MSG_USER_UID: ${GREEN}${USER_UID:-$DEFAULT_UID}${NC}"
    echo -e "$MSG_USER_GID: ${GREEN}${USER_GID:-$DEFAULT_GID}${NC}"
    echo -e "$MSG_PASSWORD: ${GREEN}${USER_PASSWORD:-$DEFAULT_PASSWORD}${NC}"
    echo -e "$MSG_WORKDIR: ${GREEN}${WORKDIR:-$DEFAULT_WORKDIR}${NC}"
    echo -e "$MSG_IMAGE_NAME: ${GREEN}${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}${NC}"
    echo -e "$MSG_CONTAINER_NAME: ${GREEN}${CONTAINER_NAME}${NC}"
}

# Display selection options
# 선택 옵션 표시
display_selection_options() {
    echo -e "\n${BLUE}$MSG_SELECT_OPTION:${NC}"
    echo -e "${GREEN}y${NC} - $MSG_USE_DEFAULT"
    echo -e "${YELLOW}n${NC} - $MSG_MODIFY_VALUES"
    echo -e "${RED}c${NC} - $MSG_CANCEL"
}

# Set default values for configuration
# 설정의 기본값 지정
set_default_values() {
    USERNAME=${USERNAME:-$DEFAULT_USERNAME}
    USER_UID=${USER_UID:-$DEFAULT_UID}
    USER_GID=${USER_GID:-$DEFAULT_GID}
    USER_PASSWORD=${USER_PASSWORD:-$DEFAULT_PASSWORD}
    WORKDIR=${WORKDIR:-$DEFAULT_WORKDIR}
    IMAGE_NAME=${IMAGE_NAME:-$DEFAULT_IMAGE_NAME}
    CONTAINER_NAME=${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}
}

# Get custom values from user input
# 사용자 입력으로부터 커스텀 값 받기
get_custom_values() {
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
}

# Display final configuration settings
# 최종 설정값 표시
display_final_settings() {
    echo -e "\n${YELLOW}$MSG_FINAL_SETTINGS:${NC}"
    echo -e "$MSG_USERNAME: ${GREEN}$USERNAME${NC}"
    echo -e "$MSG_USER_UID: ${GREEN}$USER_UID${NC}"
    echo -e "$MSG_USER_GID: ${GREEN}$USER_GID${NC}"
    echo -e "$MSG_PASSWORD: ${GREEN}$USER_PASSWORD${NC}"
    echo -e "$MSG_WORKDIR: ${GREEN}$WORKDIR${NC}"
    echo -e "$MSG_IMAGE_NAME: ${GREEN}$IMAGE_NAME${NC}"
    echo -e "$MSG_CONTAINER_NAME: ${GREEN}$CONTAINER_NAME${NC}"
}


# Main function
# 메인 함수


# Move legacy files from root to new location
# 레거시 파일들을 새 위치로 이동
move_legacy_files() {
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
}


# Initialize .dockit directory and move legacy files
# .dockit 디렉토리 초기화 및 레거시 파일 이동
init_dockit_dir() {
    # Create .dockit directory
    if [ ! -d "$DOCKIT_DIR" ]; then
        log "INFO" "$MSG_CREATING_DOCKIT_DIR"
        mkdir -p "$DOCKIT_DIR"
        log "SUCCESS" "$MSG_DOCKIT_DIR_CREATED"
    fi
    
    # Check and clean up old version files
    if [ -f "$PROJECT_ROOT/docker-tools.log" ]; then
        log "INFO" "$MSG_OLD_LOG_FOUND"
        rm -f "$PROJECT_ROOT/docker-tools.log"
        log "SUCCESS" "$MSG_OLD_LOG_REMOVED"
    fi
    
    # Move legacy files to new location
    move_legacy_files
}

# Main user input function
# 메인 사용자 입력 함수
get_user_input() {
    log "INFO" "$MSG_INIT_GETTING_USER_INPUT"
    
    # Load default values
    load_config "init"
    
    echo -e "\n${GREEN}$MSG_WELCOME${NC}"
    echo -e "${BLUE}$MSG_INPUT_DEFAULT${NC}"
    
    display_current_settings
    display_selection_options
    
    read -p "$MSG_SELECT_CHOICE [Y/n/c]: " choice
    choice=${choice:-y}
    
    case "$choice" in
        y|Y)
            init_dockit_dir
            set_default_values
            ;;
        n|N)
            init_dockit_dir
            get_custom_values
            ;;
        c|C)
            log "INFO" "$MSG_INIT_CANCELLED"
            exit 0
            ;;
        *)
            log "ERROR" "$MSG_INVALID_CHOICE"
            exit 1
            ;;
    esac
    
    display_final_settings
    save_config
}


####################################################################
#                     build_docker_image                           #
####################################################################

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



# Handle container connection prompt and execution
# 컨테이너 연결 프롬프트 및 실행 처리
handle_container_connection() {
    echo -e "\n${YELLOW}$MSG_CONNECT_CONTAINER_NOW?${NC}"
    read -p "$MSG_SELECT_CHOICE [Y/n]: " connect_container
    connect_container=${connect_container:-y}
    
    if [[ $connect_container == "y" || $connect_container == "Y" ]]; then
        log "INFO" "$MSG_CONNECTING_CONTAINER"
        docker exec -it "$CONTAINER_NAME" bash
    fi
}



# Start container and handle user interaction
# 컨테이너 시작 및 사용자 상호작용 처리
start_and_connect_container() {
    echo -e "\n${YELLOW}$MSG_START_CONTAINER_NOW?${NC}"
    read -p "$MSG_SELECT_CHOICE [Y/n]: " start_container
    start_container=${start_container:-y}
    
    if [[ $start_container == "y" || $start_container == "Y" ]]; then
        log "INFO" "$MSG_STARTING_CONTAINER"
        
        if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d; then
            log "SUCCESS" "$MSG_CONTAINER_STARTED"
            handle_container_connection
        else
            log "ERROR" "$MSG_CONTAINER_START_FAILED"
            return 1
        fi
    fi
}

# Check and set BASE_IMAGE if not already set
# BASE_IMAGE가 설정되지 않은 경우 확인 및 설정
check_base_image() {
    if [ -z "$BASE_IMAGE" ]; then
        log "WARNING" "$MSG_BASE_IMAGE_NOT_SET"
        BASE_IMAGE="namugach/ubuntu-basic:24.04-kor-deno"
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




####################################################################
#                     init_main                                    #
####################################################################

# Main initialization function
# 메인 초기화 함수
init_main() {
    log "INFO" "$MSG_INIT_START"
    display_version_info
    init_project
    get_user_input
    create_dockerfile
    build_docker_image
    create_docker_compose
    start_and_connect_container
    
    log "SUCCESS" "$MSG_INIT_COMPLETE"
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_main
fi 