#!/bin/bash

# Common module for dockit
# dockit 공통 모듈

# Define common functions and variables used in all scripts
# 모든 스크립트에서 공통으로 사용하는 함수와 변수를 정의합니다.

# Get script directory
# 스크립트 디렉토리 가져오기
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "$(dirname "$SCRIPT_DIR")")" && pwd)"
CONFIG_DIR="$PROJECT_ROOT/config"

# Load defaults.sh
# defaults.sh 로드
source "$CONFIG_DIR/defaults.sh"


# Set paths
# 경로 설정
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${CURRENT_DIR}"
TEMPLATE_DIR="${PROJECT_ROOT}/src/templates"
UTILS_DIR="${PROJECT_ROOT}/src/utils"

# 실행 디렉토리 설정 (절대 경로)
# Set execution directory (absolute path)
EXEC_DIR="$(pwd)"

# .dockit_project 디렉토리 및 파일 경로 설정
# Set .dockit_project directory and file paths
DOCKIT_PROJECT_DIR="${EXEC_DIR}/.dockit_project"
CONFIG_ENV="${DOCKIT_PROJECT_DIR}/.env"
DOCKER_COMPOSE_FILE="${DOCKIT_PROJECT_DIR}/docker-compose.yml"
DOCKERFILE="${DOCKIT_PROJECT_DIR}/Dockerfile"
DOCKER_COMPOSE_TEMPLATE="${TEMPLATE_DIR}/docker-compose.yml"
DOCKERFILE_TEMPLATE="${TEMPLATE_DIR}/Dockerfile"
CONTAINER_WORKDIR="/workspace"

# 로그 파일 경로 설정
# Set log file path
LOG_FILE="${DOCKIT_PROJECT_DIR}/dockit.log"


# 프로젝트 상태 상수 정의
PROJECT_STATE_NONE="none"
PROJECT_STATE_READY="ready"
PROJECT_STATE_DOWN="down"
PROJECT_STATE_RUNNING="running"
PROJECT_STATE_STOPPED="stopped"
PROJECT_STATE_ERROR="error"

# 유틸리티 모듈 로드
# Load utility modules
source "${UTILS_DIR}/utils.sh"


# 로그 파일 설정
[ -n "$LOG_FILE" ] && set_log_file "$LOG_FILE"

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
    local settings_file="${EXEC_DIR}/.dockit_project/config/settings.env"
    local global_settings="${PROJECT_ROOT}/config/settings.env"
    local installed_settings="/home/${USER}/.dockit/config/settings.env"
    
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

# Load settings from settings.env
# settings.env에서 설정 로드
load_settings() {
    local settings_file="${EXEC_DIR}/.dockit_project/config/settings.env"
    local global_settings="${PROJECT_ROOT}/config/settings.env"
    local installed_settings="/home/${USER}/.dockit/config/settings.env"
    
    # 설정 파일 우선순위에 따라 로드
    if [ -f "$settings_file" ]; then
        source "$settings_file"
    elif [ -f "$global_settings" ]; then
        source "$global_settings"
    elif [ -f "$installed_settings" ]; then
        source "$installed_settings"
    fi
}

# Load settings before setting defaults
# 기본값 설정 전에 설정 로드
load_settings

# Default settings
# 기본 설정값
DEFAULT_BASE_IMAGE="ubuntu:24.04"
DEFAULT_USERNAME="$(whoami)"
DEFAULT_UID="$(id -u)"
DEFAULT_GID="$(id -g)"
# 하위 호환성을 위해 PASSWORD -> DEFAULT_PASSWORD -> 기본값 순으로 fallback
DEFAULT_PASSWORD="${PASSWORD:-${DEFAULT_PASSWORD:-1234}}"
# 하위 호환성을 위해 WORKDIR -> DEFAULT_WORKDIR -> 기본값 순으로 fallback  
DEFAULT_WORKDIR="${WORKDIR:-${DEFAULT_WORKDIR:-work/project}}"

# 이 변수들은 utils/log.sh에서 제공
# These variables are provided by utils/log.sh
# RED, GREEN, YELLOW, BLUE, PURPLE, NC

# log 함수는 utils/log.sh에서 제공
# log function is provided by utils/log.sh

# 공통 경로 변환 함수
# Common path conversion function
to_flat_path() {
    local path=$1
    
    # 경로가 존재하는지 확인
    if [ -d "$path" ]; then
        # 존재하는 경로는 절대 경로로 변환 후 처리
        cd "$path" && pwd | sed 's|^/||' | tr '/' '-'
    else
        # 존재하지 않는 경로는 그대로 처리 (절대 경로 형태로 가정)
        echo "$path" | sed 's|^/||' | tr '/' '-'
    fi
}

# dockit 이름 생성 함수
# dockit name generation function
generate_dockit_name() {
    local flat_path=$(to_flat_path "$1")
    echo "dockit-${flat_path}"
}

# 디렉토리 이름에 대문자가 포함되어 있는지 확인
# Check if directory name contains uppercase letters
has_uppercase_letters() {
    local dir_name="$1"
    [[ "$dir_name" =~ [A-Z] ]]
}

# 카멜케이스를 스네이크케이스로 변환
# Convert camelCase to snake_case
convert_to_snake_case() {
    local input="$1"
    # 대문자 앞에 언더스코어 추가 후 전체를 소문자로 변환
    echo "$input" | sed 's/\([A-Z]\)/_\1/g' | sed 's/^_//' | tr '[:upper:]' '[:lower:]'
}

# 디렉토리 이름 변경 제안 및 실행
# Suggest directory name change and execute
suggest_directory_rename() {
    local current_dir="$1"
    local instruction_message="$2"
    local current_name=$(basename "$current_dir")
    local suggested_name=$(convert_to_snake_case "$current_name")
    local parent_dir=$(dirname "$current_dir")
    local new_path="$parent_dir/$suggested_name"
    
    # 제안된 이름이 현재 이름과 같으면 변경 불필요
    if [ "$current_name" = "$suggested_name" ]; then
        return 0
    fi
    
    echo ""
    log "WARNING" "$MSG_DIR_NAME_UPPERCASE_WARNING"
    echo ""
    echo "$MSG_DIR_NAME_DOCKER_RULE"
    echo "$MSG_DIR_NAME_CHANGE_RECOMMENDED"
    echo ""
    printf "$MSG_DIR_NAME_CURRENT\n" "$current_dir"
    printf "$MSG_DIR_NAME_SUGGESTED\n" "$new_path"
    echo ""
    
    # 제안된 디렉토리가 이미 존재하는지 확인
    if [ -d "$new_path" ]; then
        log "ERROR" "$(printf "$MSG_DIR_NAME_ALREADY_EXISTS" "$new_path")"
        echo "$MSG_DIR_NAME_CLEANUP_HINT"
        return 1
    fi
    
    echo -n "$MSG_DIR_NAME_CHANGE_CONFIRM"
    read -r confirm
    
    # 소문자로 변환해서 비교 (기본값은 Y)
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    
    if [ "$confirm" = "n" ] || [ "$confirm" = "no" ]; then
        log "INFO" "$MSG_DIR_NAME_CHANGE_CANCELLED"
        echo ""
        echo "$MSG_DIR_NAME_CONTINUE_HINT"
        echo "$MSG_DIR_NAME_MANUAL_CHANGE"
        echo ""
        return 1
    else
        log "INFO" "$MSG_DIR_NAME_CHANGING"
        
        if mv "$current_dir" "$new_path"; then
            log "SUCCESS" "$MSG_DIR_NAME_CHANGE_SUCCESS"
            printf "$MSG_DIR_NAME_NEW_LOCATION\n" "$new_path"
            echo ""
            echo "$MSG_DIR_NAME_STARTING_SHELL"
            echo ""
            echo "$instruction_message"
            echo ""
            
            # 새 디렉토리로 이동
            cd "$new_path"
            
            # 사용자 쉘로 새로고침 (자동 실행 없이)
            local user_shell="${SHELL:-/bin/bash}"
            exec "$user_shell"
        else
            log "ERROR" "$MSG_DIR_NAME_CHANGE_FAILED"
            return 1
        fi
    fi
}

# 디렉토리 이름 검증 및 변경 제안
# Validate directory name and suggest changes
validate_and_suggest_directory_name() {
    local instruction_message="$1"
    local current_dir="$(pwd)"
    local dir_name=$(basename "$current_dir")
    
    # 대문자가 포함되어 있는지 확인
    if has_uppercase_letters "$dir_name"; then
        suggest_directory_rename "$current_dir" "$instruction_message"
        return $?
    fi
    
    return 0
}

# dockit 이름 생성 함수 테스트
# Test generate_dockit_name function
test_generate_dockit_name() {
    echo "$(get_message MSG_COMMON_TESTING_FUNCTION)"
    echo "$(get_message MSG_COMMON_CURRENT_DIR): $(pwd)"
    echo "$(get_message MSG_COMMON_GENERATED_NAME): $(generate_dockit_name "$(pwd)")"
    echo "$(get_message MSG_COMMON_TESTING_EXPLICIT): $(generate_dockit_name "/home/hgs/work/dockit/test/c")"
}


# Check version compatibility
# 버전 호환성 검사
check_version_compatibility() {
    # Skip if no .env file
    # .env 파일이 없으면 건너뛰기
    if [ ! -f ".dockit_project/.env" ]; then
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
    project_version=$(grep "^DOCKIT_VERSION=" ".dockit_project/.env" | cut -d'"' -f2)
    
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


# Check dockit directory validity
# dockit 디렉토리 유효성 검사
check_dockit_validity() {
    # Skip check for init command and list command
    # init 명령어와 list 명령어일 때는 체크 건너뛰기
    if [[ "$1" == "init" || "$1" == "list" ]]; then
        return 0
    fi

    local dockit_dir=".dockit_project"
    
    # Check if .dockit_project directory exists first
    # 먼저 .dockit_project 디렉토리가 있는지 확인
    if [ ! -d "$dockit_dir" ]; then
        # ERROR 레벨로만 메시지 출력
        log "ERROR" "$MSG_COMMON_NOT_INITIALIZED"
        echo "" # 빈 줄 추가
        exit 1
    fi
    
    # Only check files if directory exists
    # 디렉토리가 있을 때만 파일 확인
    local required_files=("docker-compose.yml" "Dockerfile" ".env")
    for file in "${required_files[@]}"; do
        if [ ! -f "$dockit_dir/$file" ]; then
            # ERROR 레벨로만 메시지 출력
            log "ERROR" "$MSG_COMMON_RUN_INIT_FIRST"
            exit 1
        fi
    done
    
    # Check version compatibility
    # 버전 호환성 검사
    check_version_compatibility
    
    return 0
}

# Configuration loading function
# 설정 파일 로드 함수
load_env() {
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
    export IMAGE_NAME=$(generate_dockit_name "$(pwd)")
    export CONTAINER_NAME=$(generate_dockit_name "$(pwd)")
    export USERNAME="$DEFAULT_USERNAME"
    export USER_UID="$DEFAULT_UID"
    export USER_GID="$DEFAULT_GID"
    # 새로운 변수명 우선 사용, 하위 호환성을 위해 DEFAULT_ 변수도 fallback으로 제공
    export USER_PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
    export WORKDIR="${WORKDIR:-$DEFAULT_WORKDIR}"

    # Load configuration file if it exists
    # 설정 파일이 있으면 로드
    if [[ -f "$CONFIG_ENV" ]]; then
        log "INFO" "$(printf "$MSG_COMMON_LOADING_CONFIG" "$CONFIG_ENV")"
        source "$CONFIG_ENV"
    else
        log "WARNING" "$MSG_COMMON_CONFIG_NOT_FOUND"
    fi

    # Detect actual user for volume mounting
    # 볼륨 마운트를 위한 실제 사용자 검출
    detect_actual_user

    export CONFIG_LOADED=1
}

# Detect actual user that will be used in container
# 컨테이너에서 사용될 실제 사용자 검출
detect_actual_user() {
    # Only detect if BASE_IMAGE is set
    # BASE_IMAGE가 설정된 경우에만 검출
    if [ -z "$BASE_IMAGE" ]; then
        export ACTUAL_USER="$USERNAME"
        return 0
    fi

    # Check if docker is available
    # Docker 사용 가능 여부 확인
    if ! command -v docker &> /dev/null; then
        export ACTUAL_USER="$USERNAME"
        return 0
    fi

    log "INFO" "Detecting actual user for volume mounting..."
    
    # Try to pull the base image if it doesn't exist
    # 베이스 이미지가 없으면 풀 시도
    if ! docker image inspect "$BASE_IMAGE" &>/dev/null; then
        log "INFO" "Base image not found locally, attempting to pull..."
        if ! docker pull "$BASE_IMAGE" &>/dev/null; then
            log "WARNING" "Failed to pull base image, using fallback user: $USERNAME"
            export ACTUAL_USER="$USERNAME"
            return 0
        fi
    fi
    
    # Check if user with UID exists in base image
    # 베이스 이미지에서 해당 UID의 사용자 존재 확인
    local existing_user
    existing_user=$(docker run --rm "$BASE_IMAGE" getent passwd "$USER_UID" 2>/dev/null | cut -d: -f1 || echo "")
    
    if [ -n "$existing_user" ]; then
        log "INFO" "Found existing user '$existing_user' with UID $USER_UID in base image"
        export ACTUAL_USER="$existing_user"
    else
        log "INFO" "No existing user with UID $USER_UID, will use '$USERNAME'"
        export ACTUAL_USER="$USERNAME"
    fi
    
    log "INFO" "Volume mount target user: $ACTUAL_USER"
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

# Get current project ID from .dockit_project/id file
# .dockit_project/id 파일에서 현재 프로젝트 ID 가져오기
get_current_project_id() {
    local project_dir="${1:-$(pwd)}"
    local id_file="$project_dir/.dockit_project/id"
    
    if [ -f "$id_file" ]; then
        cat "$id_file"
        return 0
    else
        log "WARNING" "Project ID file not found: $id_file"
        return 1
    fi
}

# Update project state in registry
# 레지스트리에서 프로젝트 상태 업데이트
update_project_state() {
    local project_id="$1"
    local new_state="$2"
    local registry_file="$HOME/.dockit/registry.json"
    
    if [ ! -f "$registry_file" ]; then
        log "WARNING" "Registry file not found: $registry_file"
        return 1
    fi
    
    # jq를 사용하여 상태 업데이트
    if command -v jq &> /dev/null; then
        local temp_file=$(mktemp)
        jq --arg id "$project_id" \
           --arg state "$new_state" \
           --argjson last_seen "$(date +%s)" \
           'if has($id) then .[$id].state = $state | .[$id].last_seen = $last_seen else . end' \
           "$registry_file" > "$temp_file" && mv "$temp_file" "$registry_file"
        return 0
    else
        log "WARNING" "jq not found, cannot update project state"
        return 1
    fi
}

# Get project path from container name
# 컨테이너 이름에서 프로젝트 경로 추출
get_project_path_from_container() {
    local container_id="$1"
    local full_name=$(docker inspect --format "{{.Name}}" "$container_id" | sed 's/^\///')
    
    # 컨테이너 이름에서 'dockit-' 접두사 제거
    local raw_name=$(echo "$full_name" | sed 's/^dockit-//')
    
    # 이름을 경로로 변환 (- 를 / 로 변경)
    local path_form=$(echo "$raw_name" | tr '-' '/')
    
    # 절대 경로로 변환
    echo "/$path_form"
}

# Find project info from registry by container
# 컨테이너로부터 레지스트리에서 프로젝트 정보 찾기
find_project_info_by_container() {
    local container_id="$1"
    local project_path=$(get_project_path_from_container "$container_id")
    
    # 레지스트리 로드
    local registry_file="$HOME/.dockit/registry.json"
    if [ ! -f "$registry_file" ]; then
        echo ""
        return 1
    fi
    
    local registry_json=$(cat "$registry_file")
    
    # 경로로 프로젝트 찾기
    if command -v jq &> /dev/null; then
        local project_id=$(echo "$registry_json" | jq -r --arg path "$project_path" 'to_entries[] | select(.value.path == $path) | .key')
        
        if [ -n "$project_id" ] && [ "$project_id" != "null" ]; then
            echo "$project_id"
            return 0
        fi
    fi
    
    echo ""
    return 1
}

# Get containers sorted by project number (same as ps command)
# ps 명령어와 동일한 순서로 프로젝트 번호별로 정렬된 컨테이너 가져오기
get_containers_by_project_order() {
    local container_ids=$(docker ps -a --filter "label=com.dockit=true" --format "{{.ID}}")
    
    if [ -z "$container_ids" ]; then
        return 1
    fi
    
    # 레지스트리 로드
    local registry_file="$HOME/.dockit/registry.json"
    if [ ! -f "$registry_file" ]; then
        # 레지스트리가 없으면 기본 Docker 순서 사용 (역순)
        echo "$container_ids" | tac
        return 0
    fi
    
    local registry_json=$(cat "$registry_file")
    local temp_file=$(mktemp)
    
    # 각 컨테이너에 대해 프로젝트 번호 찾기
    for container_id in $container_ids; do
        local project_id=""
        local project_number=""
        
        # 컨테이너 이름에서 프로젝트 경로 추출
        local full_name=$(docker inspect --format "{{.Name}}" "$container_id" 2>/dev/null | sed 's/^\///')
        if [ -n "$full_name" ]; then
            local raw_name=$(echo "$full_name" | sed 's/^dockit-//')
            local path_form=$(echo "$raw_name" | tr '-' '/')
            local project_path="/$path_form"
            
            # 레지스트리에서 프로젝트 찾기
            if command -v jq &> /dev/null; then
                project_id=$(echo "$registry_json" | jq -r --arg path "$project_path" 'to_entries[] | select(.value.path == $path) | .key' 2>/dev/null)
                
                if [ -n "$project_id" ] && [ "$project_id" != "null" ]; then
                    # 프로젝트 번호 찾기
                    local index=1
                    while IFS= read -r id; do
                        if [ "$id" = "$project_id" ]; then
                            project_number="$index"
                            break
                        fi
                        ((index++))
                    done < <(echo "$registry_json" | jq -r 'keys[]' 2>/dev/null)
                fi
            fi
        fi
        
        # 프로젝트 번호가 없으면 999999 사용 (맨 뒤로)
        if [ -z "$project_number" ]; then
            project_number="999999"
        fi
        
        # 임시 파일에 저장 (프로젝트 번호:컨테이너 ID)
        echo "${project_number}:${container_id}" >> "$temp_file"
    done
    
    # 프로젝트 번호로 정렬하고 컨테이너 ID만 출력
    sort -n "$temp_file" | cut -d':' -f2
    
    # 임시 파일 삭제
    rm -f "$temp_file"
}

# Initialize with current command
# 현재 명령어로 초기화
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_generate_dockit_name
    exit 0
fi 