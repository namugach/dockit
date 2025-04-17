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
            set_default_values
            ;;
        n|N)
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
# Initialize .dockit_project directory and move legacy files
# .dockit_project 디렉토리 초기화 및 레거시 파일 이동
init_project() {
    # 초기화 작업
    # Initialization tasks
    
    # 도움말 표시 체크
    # Check if help should be displayed
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        show_init_help
        return 0
    fi
    
    # 프로젝트 디렉토리 확인
    # Check project directory
    check_project_directory
    
    # 기존 설정 백업
    # Backup existing settings
    if [ -d ".dockit_project" ]; then
        echo "이미 초기화된 프로젝트입니다. 다시 초기화하시겠습니까? (y/N)"
        echo "Project is already initialized. Do you want to re-initialize? (y/N)"
        read -r answer
        
        if [[ ! $answer =~ ^[Yy]$ ]]; then
            echo "초기화가 취소되었습니다."
            echo "Initialization has been cancelled."
            return 1
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
    
    # Dockit 디렉토리 생성
    # Create Dockit directory
    log_info "$(get_message MSG_CREATING_DOCKIT_DIR)"
    mkdir -p "$DOCKIT_DIR"
    
    if [ -d "$DOCKIT_DIR" ]; then
        log_info "$(get_message MSG_DOCKIT_DIR_CREATED)"
    else
        log_error "$(get_message MSG_ERROR_CREATING_DOCKIT_DIR)"
        return 1
    fi
    
    # 파일 생성 작업
    # File creation tasks
    create_env_file "$@"
    create_docker_compose_file
    copy_dockerfile
    
    # 추가적인 작업
    # Additional tasks
    
    # 초기화 완료 메시지
    # Initialization complete message
    show_initialization_message
    
    return 0
}

# Docker Compose 파일 생성
# Create Docker Compose file
create_docker_compose_file() {
    # 템플릿 파일 확인
    # Check template file
    local template="${TEMPLATE_DIR}/${DOCKER_COMPOSE_FILE}"
    local target="${DOCKIT_DIR}/${DOCKER_COMPOSE_FILE}"
    
    if [ ! -f "$template" ]; then
        log_error "$(get_message MSG_ERROR_TEMPLATE_NOT_FOUND)"
        return 1
    fi
    
    # Docker Compose 파일 생성
    # Create Docker Compose file
    cp "$template" "$target"
    
    # .env 파일에서 필요한 값 가져오기
    # Get necessary values from .env file
    local container_name
    container_name=$(grep "^CONTAINER_NAME=" "${DOCKIT_DIR}/${DOTENV_FILE}" | cut -d'"' -f2)
    
    # Docker Compose 파일 내용 수정
    # Modify Docker Compose file content
    if [ -n "$container_name" ]; then
        sed -i "s/\${CONTAINER_NAME}/$container_name/g" "$target"
    else
        local default_name
        default_name=$(basename "$(pwd)")
        sed -i "s/\${CONTAINER_NAME}/$default_name/g" "$target"
    fi
    
    log_info "$(get_message MSG_DOCKER_COMPOSE_CREATED)"
    return 0
}

# Dockerfile 복사
# Copy Dockerfile
copy_dockerfile() {
    # 기본 경로 확인
    # Check default path
    local template="${TEMPLATE_DIR}/${DOCKERFILE}"
    local target="${DOCKIT_DIR}/${DOCKERFILE}"
    
    # 복사
    # Copy
    if [ -f "$template" ]; then
        cp "$template" "$target"
        log_info "$(get_message MSG_DOCKERFILE_COPIED)"
    else
        log_warn "$(get_message MSG_DOCKERFILE_NOT_FOUND)"
    fi
    
    return 0
}

# .env 파일 생성
# Create .env file
create_env_file() {
    # 프로젝트 이름 설정 (현재 디렉토리 이름 기본값)
    # Set project name (current directory name as default)
    local project_name
    project_name=$(basename "$(pwd)")
    
    # 기본 환경 변수 설정
    # Set default environment variables
    local env_content="# Dockit 환경 설정 파일
# Dockit Environment Configuration File
# 생성일: $(date "+%Y-%m-%d %H:%M:%S")
# Created on: $(date "+%Y-%m-%d %H:%M:%S")

# 버전 정보 (수정하지 마세요)
# Version info (do not modify)
DOCKIT_VERSION=\"${DOCKIT_VERSION}\"

# 프로젝트 설정
# Project settings
PROJECT_NAME=\"${project_name}\"
CONTAINER_NAME=\"${project_name}\"
DOCKER_IMAGE=\"ubuntu:latest\"
WORKSPACE_DIR=\"/workspace\"

# Docker 설정
# Docker settings
PORT_MAPPING=\"8080:80\"
VOLUME_MAPPING=\".:/workspace\"

# 사용자 정의 설정
# User-defined settings
"

    # backup 정보 추가
    # Add backup info
    if [ -n "$backup_info" ]; then
        env_content+="
# 백업 정보
# Backup info
$backup_info"
    fi
    
    # 명령줄 인수 처리
    # Process command line arguments
    while (( "$#" )); do
        case "$1" in
            --name=*)
                env_content=$(echo "$env_content" | sed "s/CONTAINER_NAME=\"${project_name}\"/CONTAINER_NAME=\"${1#*=}\"/")
                ;;
            --image=*)
                env_content=$(echo "$env_content" | sed "s/DOCKER_IMAGE=\"ubuntu:latest\"/DOCKER_IMAGE=\"${1#*=}\"/")
                ;;
            --port=*)
                env_content=$(echo "$env_content" | sed "s/PORT_MAPPING=\"8080:80\"/PORT_MAPPING=\"${1#*=}\"/")
                ;;
            --volumes=*)
                env_content=$(echo "$env_content" | sed "s/VOLUME_MAPPING=\".:\\/workspace\"/VOLUME_MAPPING=\"${1#*=}\"/")
                ;;
        esac
        shift
    done
    
    # .env 파일에 저장
    # Save to .env file
    echo "$env_content" > "${DOCKIT_DIR}/${DOTENV_FILE}"
    
    log_info "$(get_message MSG_ENV_FILE_CREATED)"
    return 0
}

# 도움말 표시
# Show help
show_init_help() {
    echo "$(get_message MSG_INIT_HELP)"
    return 0
}

# 초기화 완료 메시지 표시
# Show initialization complete message
show_initialization_message() {
    # 설정한 환경 변수들 표시
    # Display configured environment variables
    local container_name
    local image_name
    container_name=$(grep "^CONTAINER_NAME=" "${DOCKIT_DIR}/${DOTENV_FILE}" | cut -d'"' -f2)
    image_name=$(grep "^DOCKER_IMAGE=" "${DOCKIT_DIR}/${DOTENV_FILE}" | cut -d'"' -f2)
    
    echo "$(get_message MSG_INIT_COMPLETE)"
    echo ""
    echo "- $(get_message MSG_INIT_CONTAINER_NAME): $container_name"
    echo "- $(get_message MSG_INIT_IMAGE_NAME): $image_name"
    echo ""
    echo "$(get_message MSG_INIT_NEXT_STEPS)"
    echo "  dockit info     - $(get_message MSG_INIT_SHOW_INFO)"
    echo "  dockit up       - $(get_message MSG_INIT_START_CONTAINER)"
    echo "  dockit config   - $(get_message MSG_INIT_EDIT_CONFIG)"
    echo ""
    
    return 0
}

# Initialize .dockit_project directory and move legacy files
# .dockit_project 디렉토리 초기화 및 레거시 파일 이동
initialize_dockit_directory() {
    # Create .dockit_project directory
    mkdir -p "${DOCKIT_DIR}"
    mkdir -p "${DOCKIT_DIR}/config"
    mkdir -p "${DOCKIT_DIR}/logs"
    
    # Move legacy files if they exist
    # 기존 파일이 있으면 이동
    if [ -f "./.env" ]; then
        mv "./.env" "${DOCKIT_DIR}/"
        log_info "$(get_message MSG_LEGACY_ENV_MOVED)"
    fi
    
    if [ -f "./docker-compose.yml" ]; then
        mv "./docker-compose.yml" "${DOCKIT_DIR}/"
        log_info "$(get_message MSG_LEGACY_COMPOSE_MOVED)"
    fi
    
    log_info "$(get_message MSG_DOCKIT_DIR_CREATED)"
    
    return 0
}

# Check project directory
# 프로젝트 디렉토리 확인
check_project_directory() {
    # 현재 디렉토리가 git 저장소인지 확인
    # Check if current directory is a git repository
    if [ -d ".git" ]; then
        echo "$(get_message MSG_GIT_REPO_DETECTED)"
        
        # .gitignore 파일에 .dockit_project 추가 확인
        # Check if .dockit_project is added to .gitignore
        if [ -f ".gitignore" ]; then
            if ! grep -q "^\.dockit_project" ".gitignore"; then
                echo "$(get_message MSG_ADDING_TO_GITIGNORE)"
                echo ".dockit_project/" >> ".gitignore"
            fi
        else
            echo "$(get_message MSG_CREATING_GITIGNORE)"
            echo ".dockit_project/" > ".gitignore"
        fi
    fi
    
    return 0
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

# Display version information
# 버전 정보 표시
display_version_info() {
    echo -e "\n${BLUE}$(printf "$MSG_INIT_VERSION_HEADER" "$VERSION")${NC}"
    echo -e "${BLUE}$MSG_INIT_VERSION_SEPARATOR${NC}\n"
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