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
CONFIG_DIR="${CURRENT_DIR}/.dockit"

# 현재 실행 위치를 기준으로 .dockit 디렉토리 경로 설정 (절대 경로)
# Set .dockit directory path based on current execution location (absolute path)
EXEC_DIR="$(pwd)"
CONFIG_DIR="${EXEC_DIR}/.dockit"
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
load_language_setting() {
    # 0. 최우선: 환경 변수 LANGUAGE가 이미 설정된 경우 (명령줄에서 설정된 경우)
    if [ -n "$LANGUAGE" ]; then
        # 이미 설정된 환경 변수 사용
        return 0
    fi
    
    # Try to load language setting from project config
    # 프로젝트 설정에서 언어 설정을 로드
    local settings_file="${EXEC_DIR}/.dockit/config/settings.env"
    local global_settings="${PROJECT_ROOT}/config/settings.env"
    local installed_settings="/home/${USER}/.local/share/dockit/config/settings.env"
    
    # 1. 첫번째 시도: 현재 실행 디렉토리 설정 (dockit init 설정 후)
    if [ -f "$settings_file" ]; then
        lang_setting=$(grep "LANGUAGE=" "$settings_file" | cut -d'"' -f2)
        if [ -n "$lang_setting" ]; then
            export LANGUAGE="$lang_setting"
            return 0
        fi
    fi
    
    # 2. 두번째 시도: 글로벌 설정파일 (프로젝트 루트에 있는)
    if [ -f "$global_settings" ]; then
        lang_setting=$(grep "LANGUAGE=" "$global_settings" | cut -d'"' -f2)
        if [ -n "$lang_setting" ]; then
            export LANGUAGE="$lang_setting"
            return 0
        fi
    fi
    
    # 3. 세번째 시도: 설치된 설정파일 (dockit 설치 경로)
    if [ -f "$installed_settings" ]; then
        lang_setting=$(grep "LANGUAGE=" "$installed_settings" | cut -d'"' -f2)
        if [ -n "$lang_setting" ]; then
            export LANGUAGE="$lang_setting"
            return 0
        fi
    fi
    
    # 4. 시스템 로케일에서 언어 추출 시도
    local system_lang=$(locale | grep "LANG=" | cut -d= -f2 | cut -d_ -f1)
    if [ -n "$system_lang" ]; then
        export LANGUAGE="$system_lang"
        return 0
    fi
    
    # 5. 최종 기본값: 영어
    export LANGUAGE="en"
    return 0
}

# Before loading messages, ensure we have the correct language setting
# 메시지를 로드하기 전에 올바른 언어 설정을 확보
load_language_setting

if [ -f "$PROJECT_ROOT/config/messages/load.sh" ]; then
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
    
    # Only write to log file if .dockit directory exists
    # .dockit 디렉토리가 있을 때만 로그 파일에 기록
    if [ -d "$CONFIG_DIR" ]; then
        # Create log file if it doesn't exist
        # 로그 파일이 없으면 생성
        if [ ! -f "$LOG_FILE" ]; then
            touch "$LOG_FILE"
        fi
        
        # Write all logs to file
        # 모든 로그는 파일에 기록
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
    
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

# Container name generation function
# 컨테이너 이름 생성 함수
generate_container_name() {
    local path=$1
    # Get full path and remove leading slash
    local full_path=$(cd "$path" && pwd | sed 's|^/||' | tr '/' '-')
    echo "dockit-${full_path}"
}

# Test generate_container_name function
# generate_container_name 함수 테스트
test_generate_container_name() {
    echo "$(get_message MSG_COMMON_TESTING_FUNCTION)"
    echo "$(get_message MSG_COMMON_CURRENT_DIR): $(pwd)"
    echo "$(get_message MSG_COMMON_GENERATED_NAME): $(generate_container_name "$(pwd)")"
    echo "$(get_message MSG_COMMON_TESTING_EXPLICIT): $(generate_container_name "/home/hgs/work/dockit/test/c")"
}

# Configuration loading function
# 설정 파일 로드 함수
load_config() {
    # Check if configuration is already loaded
    # 이미 설정이 로드되었는지 확인
    if [ -n "$CONFIG_LOADED" ]; then
        return 0
    fi

    # init 명령어가 아닐 경우에만 유효성 검사 실행
    # Run validity check only if not init command
    if [[ "$1" != "init" ]]; then
        if ! check_dockit_validity "$1"; then
            return 1
        fi
    fi

    # Set default values
    # 기본값 설정
    export IMAGE_NAME="$DEFAULT_IMAGE_NAME"
    export CONTAINER_NAME=$(generate_container_name "$(pwd)")
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
    # 버전 정보 로드
    # Load version information
    local version_file="$PROJECT_ROOT/bin/VERSION"
    local dockit_version
    
    if [ -f "$version_file" ]; then
        dockit_version=$(cat "$version_file")
    else
        dockit_version="unknown"
    fi
    
    log "INFO" "$(printf "$MSG_COMMON_LOADING_CONFIG" "$CONFIG_ENV")"
    cat > "$CONFIG_ENV" << EOF
# Docker Tools Configuration File
# Docker Tools 설정 파일
# Auto-generated: $(date)
# 자동 생성됨: $(date)

# Dockit Version
# Dockit 버전
DOCKIT_VERSION="$dockit_version"

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
        
    echo "$(printf "$MSG_TEMPLATE_GENERATED" "$output_file")"
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
        log "INFO" "$MSG_COMMON_NOT_INITIALIZED"
        return 1
    fi
    return 0
}

# Check dockit directory validity
# dockit 디렉토리 유효성 검사
check_dockit_validity() {
    # Skip check for init command
    # init 명령어일 때는 체크 건너뛰기
    if [[ "$1" == "init" ]]; then
        return 0
    fi

    local dockit_dir=".dockit"
    
    # Check if .dockit directory exists first
    # 먼저 .dockit 디렉토리가 있는지 확인
    if [ ! -d "$dockit_dir" ]; then
        log "ERROR" "$MSG_COMMON_NOT_INITIALIZED"
        log "INFO" "$MSG_COMMON_NOT_INITIALIZED"
        exit 1
    fi
    
    # Only check files if directory exists
    # 디렉토리가 있을 때만 파일 확인
    local required_files=("docker-compose.yml" "Dockerfile" ".env")
    for file in "${required_files[@]}"; do
        if [ ! -f "$dockit_dir/$file" ]; then
            log "ERROR" "$MSG_COMMON_NOT_INITIALIZED"
            log "INFO" "$MSG_COMMON_RUN_INIT_FIRST"
            exit 1
        fi
    done
    
    # Check version compatibility
    # 버전 호환성 검사
    check_version_compatibility
    
    return 0
}

# Compare version strings (semver)
# 버전 문자열 비교 (시맨틱 버전)
compare_versions() {
    if [[ $1 == $2 ]]; then
        echo 0
        return
    fi
    
    local IFS=.
    local i ver1=($1) ver2=($2)
    
    # Fill empty fields with zeros
    # 비어있는 필드는 0으로 채우기
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done
    
    # Compare version numbers
    # 버전 번호 비교
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ ${ver1[i]} -gt ${ver2[i]} ]]; then
            echo 1  # ver1 > ver2
            return
        fi
        if [[ ${ver1[i]} -lt ${ver2[i]} ]]; then
            echo -1  # ver1 < ver2
            return
        fi
    done
    
    echo 0  # ver1 == ver2
}

# Check version compatibility
# 버전 호환성 검사
check_version_compatibility() {
    # Skip if no .env file
    # .env 파일이 없으면 건너뛰기
    if [ ! -f ".dockit/.env" ]; then
        return 0
    fi
    
    # Get current version from VERSION file
    # VERSION 파일에서 현재 버전 가져오기
    local current_version
    local version_file="$PROJECT_ROOT/bin/VERSION"
    
    if [ -f "$version_file" ]; then
        current_version=$(cat "$version_file")
    else
        current_version="unknown"
        return 0
    fi
    
    # Get project version from .env file
    # .env 파일에서 프로젝트 버전 가져오기
    local project_version
    project_version=$(grep "^DOCKIT_VERSION=" ".dockit/.env" | cut -d'"' -f2)
    
    if [ -z "$project_version" ] || [ "$project_version" == "unknown" ]; then
        return 0
    fi
    
    # Check version compatibility
    # 버전 호환성 검사
    log "INFO" "$(get_message MSG_VERSION_CHECK_HEADER)"
    
    local comparison
    comparison=$(compare_versions "$project_version" "$current_version")
    
    if [ "$comparison" == "1" ]; then
        # Project version is higher than current version
        # 프로젝트 버전이 현재 버전보다 높음
        log "WARNING" "$(printf "$(get_message MSG_VERSION_PROJECT_HIGHER)" "$project_version" "$current_version")"
        log "WARNING" "$(get_message MSG_VERSION_DOWNLOAD_LATEST)"
        log "WARNING" "$(get_message MSG_VERSION_POSSIBLE_INCOMPATIBILITY)"
    elif [ "$comparison" == "-1" ]; then
        # Project version is lower than current version
        # 프로젝트 버전이 현재 버전보다 낮음
        log "WARNING" "$(printf "$(get_message MSG_VERSION_PROJECT_LOWER)" "$project_version" "$current_version")"
        log "WARNING" "$(get_message MSG_VERSION_POSSIBLE_INCOMPATIBILITY)"
    fi
    
    return 0
}

# Check minimum version requirement
# 최소 버전 요구사항 확인
check_min_version() {
    local required_version="$1"
    local current_version
    
    # Get current version
    # 현재 버전 가져오기
    local version_file="$PROJECT_ROOT/bin/VERSION"
    
    if [ -f "$version_file" ]; then
        current_version=$(cat "$version_file")
    else
        current_version="unknown"
        return 1
    fi
    
    # Compare versions
    # 버전 비교
    local comparison
    comparison=$(compare_versions "$current_version" "$required_version")
    
    if [ "$comparison" == "-1" ]; then
        # Current version is lower than required version
        # 현재 버전이 필요한 버전보다 낮음
        log "ERROR" "$(printf "$(get_message MSG_VERSION_MIN_REQUIRED)" "$required_version" "$current_version")"
        log "ERROR" "$(get_message MSG_VERSION_FEATURE_UNAVAILABLE)"
        return 1
    fi
    
    return 0
}

# Initialize with current command
# 현재 명령어로 초기화
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_generate_container_name
    exit 0
fi 