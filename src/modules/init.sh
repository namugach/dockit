#!/bin/bash

# Init module - Initial setup of Docker development environment
# init 모듈 - Docker 개발 환경 초기 설정

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" "init"

# Load defaults module
# 기본값 모듈 로드
CONFIG_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/config"
source "$CONFIG_DIR/defaults.sh"

source "$MODULES_DIR/build.sh"
source "$MODULES_DIR/up.sh"
source "$MODULES_DIR/connect.sh"

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

# common.sh와 변수 이름 통일 (CONFIG_ENV)
# Unify variable name with common.sh (CONFIG_ENV)
CONFIG_ENV="$CONFIG_FILE"

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
        echo -e "$MSG_PROJECT_ALREADY_INITIALIZED"
        echo -e "$MSG_WANT_REINITIALIZE"
        read -r answer
        
        if [[ ! $answer =~ ^[Yy]$ ]]; then
            echo -e "$MSG_INIT_CANCELLED"
            exit 0
        fi
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
    echo -e "$MSG_BASE_IMAGE: ${GREEN}${BASE_IMAGE:-${DEFAULT_IMAGES["$LANGUAGE"]}}${NC}"
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
    BASE_IMAGE=${BASE_IMAGE:-${DEFAULT_IMAGES["$LANGUAGE"]}}
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
    
    read -p "$MSG_BASE_IMAGE [${BASE_IMAGE:-${DEFAULT_IMAGES["$LANGUAGE"]}}]: " input
    BASE_IMAGE=${input:-${BASE_IMAGE:-${DEFAULT_IMAGES["$LANGUAGE"]}}}
    
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
    echo -e "$MSG_BASE_IMAGE: ${GREEN}$BASE_IMAGE${NC}"
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


# Configuration saving function
# 설정 파일 저장 함수
create_env() {
    # 버전 정보 로드
    # Load version information
    local version_file="$PROJECT_ROOT/bin/VERSION"
    
    DOCKIT_VERSION=$(cat "$version_file")
    
    log "INFO" "$(printf "$MSG_COMMON_LOADING_CONFIG" "$CONFIG_ENV")"
    
    # 템플릿 파일 경로
    # Template file path
    local template_env="${TEMPLATE_DIR}/env"
    
    # process_template 함수를 사용하여 설정 파일 생성
    # Use process_template function to generate config file
    process_template "$template_env" "$CONFIG_ENV"
    local result=$?
    
    # 처리 결과 확인
    # Check processing result
    if [ $result -eq 0 ]; then
        log "SUCCESS" "$MSG_CONFIG_SAVED"
    else
        log "ERROR" "$MSG_CONFIG_SAVE_FAILED"
    fi
}




# Template processing function
# 템플릿 처리 함수
process_template() {
    local template_file=$1
    local output_file=$2
    
    # Load configuration
    # 설정 로드
    load_env
    
    # Create necessary directories
    # 필요한 디렉토리 생성
    mkdir -p "$(dirname "$output_file")"
    
    # Check if BASE_IMAGE is set
    # BASE_IMAGE가 설정되어 있는지 확인
    if [ -z "$BASE_IMAGE" ]; then
        log "WARNING" "$MSG_COMMON_BASE_IMAGE_NOT_SET"
        # 현재 언어에 맞는 기본 이미지 사용
        BASE_IMAGE="${DEFAULT_IMAGES["$LANGUAGE"]}"
    fi
    
    # 템플릿 파일 존재 확인
    # Check if template file exists
    if [ ! -f "$template_file" ]; then
        log "ERROR" "$(get_message MSG_ERROR_TEMPLATE_NOT_FOUND)"
        return 1
    fi
    
    log "INFO" "$(printf "$MSG_COMMON_USING_BASE_IMAGE" "$BASE_IMAGE")"
    
    # 현재 날짜 변수 설정
    # Set current date variable
    local current_date="$(date)"
    
    # Process template file
    # 템플릿 파일 처리
    sed -e "s|\${USERNAME}|${USERNAME}|g" \
        -e "s|\${USER_UID}|${USER_UID}|g" \
        -e "s|\${USER_GID}|${USER_GID}|g" \
        -e "s|\${WORKDIR}|${WORKDIR}|g" \
        -e "s|\${USER_PASSWORD}|${USER_PASSWORD}|g" \
        -e "s|\${CONTAINER_NAME}|${CONTAINER_NAME}|g" \
        -e "s|\${PROJECT_ROOT}|${PROJECT_ROOT}|g" \
        -e "s|\${CONTAINER_WORKDIR}|${CONTAINER_WORKDIR}|g" \
        -e "s|\${BASE_IMAGE}|${BASE_IMAGE}|g" \
        -e "s|\${IMAGE_NAME}|${IMAGE_NAME}|g" \
        -e "s|\${DATE}|${current_date}|g" \
        -e "s|\${DOCKIT_VERSION}|${DOCKIT_VERSION:-unknown}|g" \
        -e "s|\${CONTAINER_USERNAME}|${CONTAINER_USERNAME:-}|g" \
        -e "s|\${CONTAINER_USER_UID}|${CONTAINER_USER_UID:-}|g" \
        -e "s|\${CONTAINER_USER_GID}|${CONTAINER_USER_GID:-}|g" \
        "$template_file" > "$output_file"
        
    echo "$(printf "$MSG_TEMPLATE_GENERATED" "$output_file")"
    return 0
}

# .dockit_project 디렉토리 정리 함수
# Function to clean up .dockit_project directory
cleanup_project_dir() {
    if [ -d ".dockit_project" ]; then
        rm -rf ".dockit_project"
        echo -e "${BLUE}$MSG_TEMP_DIR_REMOVED${NC}"
    fi
}

# Ctrl+C(SIGINT) 처리를 위한 정리 함수
# Cleanup function for Ctrl+C(SIGINT) handling
cleanup_user_input() {
    echo -e "\n${YELLOW}$MSG_INIT_CANCELLED_BY_USER${NC}"
    cleanup_project_dir
    exit 1
}

# Main user input function
# 메인 사용자 입력 함수
get_user_input() {
    log "INFO" "$MSG_INIT_GETTING_USER_INPUT"
    
    # 기존 트랩 설정 저장
    # Save existing trap
    local old_trap=$(trap -p INT)
    
    # 새 트랩 설정
    # Set new trap
    trap 'cleanup_user_input' INT
    
    # Load default values
    load_env "init"
    
    echo -e "\n${GREEN}$MSG_WELCOME${NC}"
    echo -e "${BLUE}$MSG_INPUT_DEFAULT${NC}"
    echo -e "${YELLOW}$MSG_INIT_CTRL_C_HINT${NC}"
    
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
            cleanup_project_dir
            
            # 트랩 복원
            # Restore trap
            eval "$old_trap"
            exit 0
            ;;
        *)
            log "ERROR" "$MSG_INVALID_CHOICE"
            cleanup_project_dir
            
            # 트랩 복원
            # Restore trap
            eval "$old_trap"
            exit 1
            ;;
    esac
    
    display_final_settings
    create_env
    
    # 이 단계부터는 .dockit_project를 삭제하지 않는 새로운 트랩 설정
    # From this point, set a new trap that does not delete .dockit_project
    trap 'echo -e "\n${YELLOW}$MSG_PROCESS_CANCELLED_BY_USER${NC}"; exit 1' INT
    
    echo -e "${YELLOW}$MSG_BUILD_CTRL_C_HINT${NC}"
    
    # 트랩 복원
    # Restore trap
    eval "$old_trap"
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
        # 현재 언어에 맞는 기본 이미지 사용
        BASE_IMAGE="${DEFAULT_IMAGES["$LANGUAGE"]}"
    fi
    log "INFO" "$MSG_USING_BASE_IMAGE: $BASE_IMAGE"
}

# Build Docker image if user confirms
# 사용자 확인 후 Docker 이미지 빌드
build_image() {
  # 이미지 빌드 여부 확인
  echo -e "\n${YELLOW}$MSG_BUILD_IMAGE_PROMPT${NC}"
  read -p "$MSG_SELECT_CHOICE [Y/n]: " user_choice
  user_choice=${user_choice:-y}
  
  if [[ $user_choice == "y" || $user_choice == "Y" ]]; then
    build_main "$@"
    # build_docker_image
  else
    log "INFO" "$MSG_EXIT_IMAGE_BUILD"
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
handle_container() {
    echo -e "\n${YELLOW}$MSG_CONNECT_CONTAINER_NOW?${NC}"
    read -p "$MSG_SELECT_CHOICE [Y/n]: " connect_container
    connect_container=${connect_container:-y}
    
    if [[ $connect_container == "y" || $connect_container == "Y" ]]; then
      # log "INFO" "$MSG_CONNECTING_CONTAINER"
      # docker exec -it "$CONTAINER_NAME" bash
      connect_main "$@"
    else
        log "INFO" "$MSG_SKIP_CONTAINER_CONNECTION"
    fi
}



# Start container and handle user interaction
# 컨테이너 시작 및 사용자 상호작용 처리
start_container() {
    echo -e "\n${YELLOW}$MSG_START_CONTAINER_NOW${NC}"
    read -p "$MSG_SELECT_CHOICE [Y/n]: " start_container
    start_container=${start_container:-y}
    
    if [[ $start_container == "y" || $start_container == "Y" ]]; then
        log "INFO" "$MSG_STARTING_CONTAINER"

        # 직접 Docker Compose 실행
        # Docker Compose 파일이 있는지 확인
        if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
            log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
            exit 1
        fi
        
        # 컨테이너를 백그라운드에서 시작
        log "INFO" "$MSG_STARTING_IN_BACKGROUND"
        if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d; then
            log "SUCCESS" "$MSG_CONTAINER_STARTED"
            log "INFO" "$MSG_CONTAINER_RUNNING_BACKGROUND"
            
            # 컨테이너 사용자 정보 업데이트 - up.sh에서 가져와서 직접 호출
            source "$MODULES_DIR/up.sh"
            update_container_user_info
            
            # 컨테이너 상태 출력
            log "INFO" "$MSG_CONTAINER_INFO: $CONTAINER_NAME"
            docker ps --filter "name=$CONTAINER_NAME" --format "table {{.ID}}\t{{.Status}}\t{{.Ports}}"
        else
            log "ERROR" "$MSG_CONTAINER_START_FAILED"
            log "INFO" "$MSG_CHECK_DOCKER"
            log "INFO" "$MSG_CHECK_PORTS"
            log "INFO" "$MSG_CHECK_IMAGE"
            exit 1
        fi
    else
        log "INFO" "$MSG_START_LATER"
        echo -e "\n${BLUE}$MSG_START_LATER${NC} dockit up"
        exit 0
    fi
}










####################################################################
#                     init_main                                    #
####################################################################

# Main initialization function
# 메인 초기화 함수
init_main() {
    # Ctrl+C 기본 동작 설정 (트랩 해제)
    # Set default Ctrl+C behavior (no trap)
    trap - INT
    
    log "INFO" "$MSG_INIT_START"
    display_version_info
    init_project
    get_user_input
    create_dockerfile
    create_docker_compose
    
    # 이 단계부터는 .dockit_project를 삭제하지 않는 새로운 트랩 설정
    # From this point, set a new trap that does not delete .dockit_project
    trap 'echo -e "\n${YELLOW}$MSG_PROCESS_CANCELLED_BY_USER${NC}"; exit 1' INT
    
    echo -e "${YELLOW}$MSG_BUILD_CTRL_C_HINT${NC}"
    
    # build_image
    build_main "$@"
    start_container
    
    log "SUCCESS" "$MSG_INIT_COMPLETE"

    handle_container
    
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_main
fi 