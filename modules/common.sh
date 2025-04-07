#!/bin/bash

# dockit 공통 모듈
# 모든 스크립트에서 공통으로 사용하는 함수와 변수를 정의합니다.

# 이 스크립트가 있는 디렉토리를 기준으로 상대 경로 설정
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

# 설정 파일 경로
CONFIG_FILE="$PROJECT_ROOT/.env"
LOG_FILE="$PROJECT_ROOT/dockit.log"

# 템플릿 파일 경로
TEMPLATES_DIR="$PROJECT_ROOT/templates"
DOCKERFILE_TEMPLATE="$TEMPLATES_DIR/Dockerfile.template"
DOCKER_COMPOSE_TEMPLATE="$TEMPLATES_DIR/docker-compose.yml.template"

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
    if [[ -f "$CONFIG_FILE" ]]; then
        log "INFO" "설정 파일 로드 중: $CONFIG_FILE"
        source "$CONFIG_FILE"
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
    log "INFO" "설정 파일 저장 중: $CONFIG_FILE"
    cat > "$CONFIG_FILE" << EOF
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
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        log "ERROR" "템플릿 파일을 찾을 수 없습니다: $template_file"
        return 1
    fi
    
    log "INFO" "템플릿 처리 중: $template_file -> $output_file"
    
    # 템플릿 파일 읽기
    local template_content=$(<"$template_file")
    
    # 변수 치환
    local processed_content=$(echo "$template_content" | 
        sed -e "s|\${USERNAME}|$USERNAME|g" \
            -e "s|\${WORKDIR}|$WORKDIR|g" \
            -e "s|\${IMAGE_NAME}|$IMAGE_NAME|g" \
            -e "s|\${CONTAINER_NAME}|$CONTAINER_NAME|g")
    
    # 파일에 저장
    echo "$processed_content" > "$output_file"
    
    if [ $? -eq 0 ]; then
        log "SUCCESS" "파일이 생성되었습니다: $output_file"
        return 0
    else
        log "ERROR" "파일 생성에 실패했습니다: $output_file"
        return 1
    fi
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
    if [ ! -f "$PROJECT_ROOT/docker-compose.yml" ]; then
        log "ERROR" "docker-compose.yml 파일을 찾을 수 없습니다"
        log "INFO" "먼저 install 명령을 실행하세요: ./docker-tools.sh install"
        return 1
    fi
    return 0
}

# 직접 실행 시 헬프 메시지
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "이 스크립트는 직접 실행할 수 없습니다. docker-tools.sh를 통해 사용하세요."
    exit 1
fi

# 초기화
load_config 