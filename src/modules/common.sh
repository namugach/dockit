#!/bin/bash

# dockit 공통 모듈
# 모든 스크립트에서 공통으로 사용하는 함수와 변수를 정의합니다.

# 경로 설정
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${CURRENT_DIR}/../.." && pwd)"
MODULES_DIR="${CURRENT_DIR}"
TEMPLATE_DIR="${PROJECT_ROOT}/src/templates"
CONFIG_DIR="${PROJECT_ROOT}/.dockit"
CONFIG_ENV="${CONFIG_DIR}/.env"
DOCKER_COMPOSE_FILE="${CONFIG_DIR}/docker-compose.yml"
DOCKER_COMPOSE_TEMPLATE="${TEMPLATE_DIR}/docker-compose.yml"
DOCKERFILE_TEMPLATE="${TEMPLATE_DIR}/Dockerfile"
CONTAINER_WORKDIR="/workspace"

# 설정 파일 경로
LOG_FILE="$CONFIG_DIR/dockit.log"

# Docker Compose 명령어 확인
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    DOCKER_COMPOSE_CMD="docker compose"
fi

# 기본 설정값
DEFAULT_IMAGE_NAME="my-ubuntu"
DEFAULT_CONTAINER_NAME="my-container"
DEFAULT_USERNAME="$(whoami)"
DEFAULT_UID="$(id -u)"
DEFAULT_GID="$(id -g)"
DEFAULT_PASSWORD="1234"
DEFAULT_WORKDIR="work/project"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 로그 기록 함수
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # .dockit 디렉토리가 없으면 생성
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi
    
    # 로그 파일이 없으면 생성
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # 화면에도 표시 (ERROR 레벨일 경우 빨간색으로)
    if [[ "$level" == "ERROR" ]]; then
        echo -e "${RED}[$level] $message${NC}" >&2
    elif [[ "$level" == "WARNING" ]]; then
        echo -e "${YELLOW}[$level] $message${NC}"
    elif [[ "$level" == "SUCCESS" ]]; then
        echo -e "${GREEN}[$level] $message${NC}"
    elif [[ "$level" == "INFO" ]]; then
        echo -e "${BLUE}[$level] $message${NC}"
    else
        echo "[$level] $message"
    fi
}

# 설정 파일 로드 함수
load_config() {
    if [[ -f "$CONFIG_ENV" ]]; then
        log "INFO" "설정 파일 로드 중: $CONFIG_ENV"
        source "$CONFIG_ENV"
    else
        log "WARNING" "설정 파일을 찾을 수 없습니다. 기본값을 사용합니다."
        # 기본값 사용
        IMAGE_NAME="$DEFAULT_IMAGE_NAME"
        CONTAINER_NAME="$DEFAULT_CONTAINER_NAME"
        USERNAME="$DEFAULT_USERNAME"
        USER_UID="$DEFAULT_UID"
        USER_GID="$DEFAULT_GID"
        USER_PASSWORD="$DEFAULT_PASSWORD"
        WORKDIR="$DEFAULT_WORKDIR"
    fi
}

# 설정 파일 저장 함수
save_config() {
    log "INFO" "설정 파일 저장 중: $CONFIG_ENV"
    cat > "$CONFIG_ENV" << EOF
# Docker Tools 설정 파일
# 자동 생성됨: $(date)

# 컨테이너 설정
IMAGE_NAME="$IMAGE_NAME"
CONTAINER_NAME="$CONTAINER_NAME"

# 사용자 설정
USERNAME="$USERNAME"
USER_UID="$USER_UID"
USER_GID="$USER_GID"
USER_PASSWORD="$USER_PASSWORD"
WORKDIR="$WORKDIR"
EOF
    
    log "SUCCESS" "설정 파일이 저장되었습니다."
}

# 템플릿 처리 함수
process_template() {
    local template_file=$1
    local output_file=$2
    
    # 설정 로드
    load_config
    
    # 필요한 디렉토리 생성
    mkdir -p "$(dirname "$output_file")"
    
    # BASE_IMAGE가 설정되어 있는지 확인
    if [ -z "$BASE_IMAGE" ]; then
        log "WARNING" "BASE_IMAGE가 설정되지 않았습니다. 기본 이미지를 사용합니다."
        BASE_IMAGE="namugach/ubuntu-basic:24.04-kor-deno"
    fi
    
    log "INFO" "사용할 베이스 이미지: $BASE_IMAGE"
    
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

# 컨테이너 상태 확인 함수
check_container_status() {
    local container_name="$1"
    
    if [ -z "$container_name" ]; then
        container_name="$CONTAINER_NAME"
    fi
    
    if docker ps -q --filter "name=$container_name" | grep -q .; then
        log "INFO" "컨테이너가 실행 중입니다: $container_name"
        return 0
    elif docker ps -aq --filter "name=$container_name" | grep -q .; then
        log "INFO" "컨테이너가 중지되었습니다: $container_name"
        return 1
    else
        log "INFO" "컨테이너가 존재하지 않습니다: $container_name"
        return 2
    fi
}

# Docker Compose 파일 존재 확인
check_docker_compose_file() {
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "docker-compose.yml 파일을 찾을 수 없습니다"
        log "INFO" "먼저 install 명령을 실행하세요: ./dockit.sh install"
        return 1
    fi
    return 0
}

# 직접 실행 시 헬프 메시지
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "이 스크립트는 직접 실행할 수 없습니다. dockit.sh를 통해 사용하세요."
    exit 1
fi

# 초기화
load_config 