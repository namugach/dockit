#!/bin/bash

# Common module for dockit
# dockit 공통 모듈

# Define common functions and variables used in all scripts
# 모든 스크립트에서 공통으로 사용하는 함수와 변수를 정의합니다.

# Set paths
# 경로 설정
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${CURRENT_DIR}/../.." && pwd)"
MODULES_DIR="${CURRENT_DIR}"
TEMPLATE_DIR="${PROJECT_ROOT}/src/templates"
CONFIG_DIR="$(pwd)/.dockit"
CONFIG_ENV="${CONFIG_DIR}/.env"
DOCKER_COMPOSE_FILE="${CONFIG_DIR}/docker-compose.yml"
DOCKER_COMPOSE_TEMPLATE="${TEMPLATE_DIR}/docker-compose.yml"
DOCKERFILE_TEMPLATE="${TEMPLATE_DIR}/Dockerfile"
CONTAINER_WORKDIR="/workspace"

# Configuration file paths
# 설정 파일 경로
LOG_FILE="$CONFIG_DIR/dockit.log"

# Load message system
# 메시지 시스템 로드
if [ -f "$PROJECT_ROOT/config/messages/load.sh" ]; then
    # Set default value if LANGUAGE environment variable is not set
    # LANGUAGE 환경 변수가 설정되어 있지 않으면 기본값 설정
    if [ -z "$LANGUAGE" ]; then
        export LANGUAGE="ko"
    fi
    
    source "$PROJECT_ROOT/config/messages/load.sh"
    load_messages
fi

# Check Docker Compose command
# Docker Compose 명령어 확인
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    DOCKER_COMPOSE_CMD="docker compose"
fi

# Default settings
# 기본 설정값
DEFAULT_IMAGE_NAME="my-ubuntu"
DEFAULT_CONTAINER_NAME="my-container"
DEFAULT_USERNAME="$(whoami)"
DEFAULT_UID="$(id -u)"
DEFAULT_GID="$(id -g)"
DEFAULT_PASSWORD="1234"
DEFAULT_WORKDIR="work/project"

# Color definitions
# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging function
# 로그 기록 함수
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Create .dockit directory if it doesn't exist
    # .dockit 디렉토리가 없으면 생성
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi
    
    # Create log file if it doesn't exist
    # 로그 파일이 없으면 생성
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi
    
    # Write all logs to file
    # 모든 로그는 파일에 기록
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Display only ERROR, WARNING, SUCCESS on screen
    # 화면에는 ERROR, WARNING, SUCCESS만 표시
    if [[ "$level" == "ERROR" ]]; then
        echo -e "${RED}[$level] $message${NC}" >&2
    elif [[ "$level" == "WARNING" ]]; then
        echo -e "${YELLOW}[$level] $message${NC}"
    elif [[ "$level" == "SUCCESS" ]]; then
        echo -e "${GREEN}[$level] $message${NC}"
    fi
}

# Configuration loading function
# 설정 파일 로드 함수
load_config() {
    # Check if configuration is already loaded
    # 이미 설정이 로드되었는지 확인
    if [ -n "$CONFIG_LOADED" ]; then
        return 0
    fi

    # Set default values
    # 기본값 설정
    export IMAGE_NAME="$DEFAULT_IMAGE_NAME"
    # Get relative path from project root and replace '/' with '-'
    local rel_path=$(realpath --relative-to="$PROJECT_ROOT" "$(pwd)" | tr '/' '-')
    export CONTAINER_NAME="dockit-${rel_path}"
    export USERNAME="$DEFAULT_USERNAME"
    export USER_UID="$DEFAULT_UID"
    export USER_GID="$DEFAULT_GID"
    export USER_PASSWORD="$DEFAULT_PASSWORD"
    export WORKDIR="$DEFAULT_WORKDIR"

    # Load configuration file if it exists
    # 설정 파일이 있으면 로드
    if [[ -f "$CONFIG_ENV" ]]; then
        log "INFO" "$(printf "$MSG_COMMON_LOADING_CONFIG" "$CONFIG_ENV")"
        source "$CONFIG_ENV"
    else
        log "WARNING" "$MSG_COMMON_CONFIG_NOT_FOUND"
    fi

    export CONFIG_LOADED=1
}

# Configuration saving function
# 설정 파일 저장 함수
save_config() {
    log "INFO" "$(printf "$MSG_COMMON_LOADING_CONFIG" "$CONFIG_ENV")"
    cat > "$CONFIG_ENV" << EOF
# Docker Tools Configuration File
# Docker Tools 설정 파일
# Auto-generated: $(date)
# 자동 생성됨: $(date)

# Container Settings
# 컨테이너 설정
IMAGE_NAME="$IMAGE_NAME"
CONTAINER_NAME="$CONTAINER_NAME"

# User Settings
# 사용자 설정
USERNAME="$USERNAME"
USER_UID="$USER_UID"
USER_GID="$USER_GID"
USER_PASSWORD="$USER_PASSWORD"
WORKDIR="$WORKDIR"
EOF
    
    log "SUCCESS" "$MSG_CONFIG_SAVED"
}

# Template processing function
# 템플릿 처리 함수
process_template() {
    local template_file=$1
    local output_file=$2
    
    # Load configuration
    # 설정 로드
    load_config
    
    # Create necessary directories
    # 필요한 디렉토리 생성
    mkdir -p "$(dirname "$output_file")"
    
    # Check if BASE_IMAGE is set
    # BASE_IMAGE가 설정되어 있는지 확인
    if [ -z "$BASE_IMAGE" ]; then
        log "WARNING" "$MSG_COMMON_BASE_IMAGE_NOT_SET"
        BASE_IMAGE="namugach/ubuntu-basic:24.04-kor-deno"
    fi
    
    log "INFO" "$(printf "$MSG_COMMON_USING_BASE_IMAGE" "$BASE_IMAGE")"
    
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
        "$template_file" > "$output_file"
        
    echo "Generated: $output_file"
}

# Container status check function
# 컨테이너 상태 확인 함수
check_container_status() {
    local container_name="$1"
    
    if [ -z "$container_name" ]; then
        container_name="$CONTAINER_NAME"
    fi
    
    if docker ps -q --filter "name=$container_name" | grep -q .; then
        log "INFO" "$(printf "$MSG_COMMON_CONTAINER_RUNNING" "$container_name")"
        return 0
    elif docker ps -aq --filter "name=$container_name" | grep -q .; then
        log "INFO" "$(printf "$MSG_COMMON_CONTAINER_STOPPED" "$container_name")"
        return 1
    else
        log "INFO" "$(printf "$MSG_COMMON_CONTAINER_NOT_FOUND" "$container_name")"
        return 2
    fi
}

# Check Docker Compose file existence
# Docker Compose 파일 존재 확인
check_docker_compose_file() {
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMMON_COMPOSE_NOT_FOUND"
        log "INFO" "$MSG_COMMON_RUN_INSTALL_FIRST"
        return 1
    fi
    return 0
}

# Help message for direct execution
# 직접 실행 시 헬프 메시지
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "$MSG_COMMON_DIRECT_EXECUTE_ERROR"
    exit 1
fi

# Initialize
# 초기화
load_config 