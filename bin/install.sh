#!/bin/bash

# 색상 정의
# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 설치 디렉토리
# Installation directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$HOME/.local/share/dockit"
INSTALL_DIR="$HOME/.local/bin"
COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
ZSH_COMPLETION_DIR="$HOME/.local/share/zsh/site-functions"
CONFIG_DIR="$HOME/.config/dockit"
GLOBAL_CONFIG_DIR="/etc/dockit"

# 로그 함수
# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 의존성 체크
# Check dependencies
check_dependencies() {
    log_info "의존성 확인 중..."
    
    # Docker 체크
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker가 설치되어 있지 않습니다. 먼저 Docker를 설치해주세요."
        exit 1
    fi
    
    # Docker Compose 체크 (docker-compose 또는 docker compose)
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        log_error "Docker Compose가 설치되어 있지 않습니다. 먼저 Docker Compose를 설치해주세요."
        exit 1
    fi
    
    # 기본 도구 체크
    local required_tools=("git" "curl" "sed" "grep")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_error "$tool이 설치되어 있지 않습니다. 먼저 $tool을 설치해주세요."
            exit 1
        fi
    done
    
    log_info "모든 의존성이 충족되었습니다."
}

# 기존 설치 확인
# Check existing installation
check_existing_installation() {
    log_info "기존 설치 확인 중..."
    
    # dockit 명령어 체크
    if command -v dockit >/dev/null 2>&1; then
        log_warn "dockit이 이미 설치되어 있습니다."
        read -p "다시 설치하시겠습니까? [y/N] " reinstall
        if [[ ! $reinstall =~ ^[Yy]$ ]]; then
            log_info "설치가 취소되었습니다."
            exit 0
        fi
    fi
    
    # 프로젝트 디렉토리 체크
    if [ -d "$PROJECT_DIR" ]; then
        log_warn "프로젝트 디렉토리가 이미 존재합니다: $PROJECT_DIR"
        read -p "덮어쓰시겠습니까? [y/N] " overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            log_info "설치가 취소되었습니다."
            exit 0
        fi
    fi
}

# 권한 체크
# Check permissions
check_permissions() {
    log_info "권한 확인 중..."
    
    # 설치 디렉토리 권한 체크
    local dirs=("$INSTALL_DIR" "$PROJECT_DIR" "$COMPLETION_DIR" "$ZSH_COMPLETION_DIR" "$CONFIG_DIR")
    for dir in "${dirs[@]}"; do
        if [ ! -w "$(dirname "$dir")" ]; then
            log_error "쓰기 권한이 없습니다: $(dirname "$dir")"
            log_info "sudo로 실행하거나 디렉토리 권한을 확인해주세요."
            exit 1
        fi
    done
}

# 디렉토리 생성
# Create directories
create_directories() {
    log_info "디렉토리 생성 중..."
    mkdir -p "$PROJECT_DIR"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$COMPLETION_DIR"
    mkdir -p "$ZSH_COMPLETION_DIR"
    mkdir -p "$CONFIG_DIR"
}

# 프로젝트 파일 설치
# Install project files
install_project() {
    log_info "프로젝트 파일 설치 중..."
    
    # 프로젝트 파일 복사
    cp -r "$PROJECT_ROOT/src" "$PROJECT_DIR/"
    cp -r "$PROJECT_ROOT/config" "$PROJECT_DIR/"
    cp -r "$PROJECT_ROOT/completion" "$PROJECT_DIR/"
    
    # dockit 스크립트 설치
    cp "$PROJECT_ROOT/bin/dockit.sh" "$INSTALL_DIR/dockit"
    chmod +x "$INSTALL_DIR/dockit"
    
    # 스크립트 경로 수정
    sed -i "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$PROJECT_DIR\"|" "$INSTALL_DIR/dockit"
}

# 자동완성 스크립트 설치
# Install completion scripts
install_completion() {
    log_info "자동완성 스크립트 설치 중..."
    
    # Bash completion
    cp "$PROJECT_DIR/completion/dockit.sh" "$COMPLETION_DIR/dockit"
    
    # Zsh completion
    cp "$PROJECT_DIR/completion/dockit.zsh" "$ZSH_COMPLETION_DIR/_dockit"
}

# PATH 설정 확인
# Check PATH setting
check_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log_warn "PATH에 설치 디렉토리를 추가합니다."
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.zshrc"
    fi
}

# 설치 확인
# Verify installation
verify_installation() {
    if command -v dockit >/dev/null 2>&1; then
        log_info "설치가 완료되었습니다!"
        log_info "dockit 명령어를 사용할 수 있습니다."
        log_info "도움말을 보려면 'dockit help'를 실행하세요."
    else
        log_error "설치에 실패했습니다."
        exit 1
    fi
}

# 메인 설치 프로세스
# Main installation process
main() {
    log_info "dockit 설치를 시작합니다..."
    
    check_dependencies
    check_existing_installation
    check_permissions
    create_directories
    install_project
    install_completion
    check_path
    verify_installation
    
    log_info "새로운 셸을 시작하거나 'source ~/.bashrc' 또는 'source ~/.zshrc'를 실행하세요."
}

# 스크립트 실행
# Execute script
main

# Installation module
# 설치 모듈
install() {
    echo "$(get_message MSG_INSTALL_START)"
    
    # Check if Docker is running
    # Docker가 실행 중인지 확인
    if ! docker info > /dev/null 2>&1; then
        echo "$(get_message MSG_INSTALL_CHECK_DOCKER)"
        return 1
    fi
    
    # Check if ports are available
    # 포트가 사용 가능한지 확인
    if lsof -i :80 > /dev/null 2>&1 || lsof -i :443 > /dev/null 2>&1; then
        echo "$(get_message MSG_INSTALL_CHECK_PORTS)"
        return 1
    fi
    
    # Check if image exists
    # 이미지가 존재하는지 확인
    if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
        echo "$(get_message MSG_INSTALL_CHECK_IMAGE)"
        return 1
    fi
    
    # Start container
    # 컨테이너 시작
    if docker-compose up -d; then
        echo "$(get_message MSG_INSTALL_COMPLETE)"
        return 0
    else
        echo "$(get_message MSG_INSTALL_FAILED)"
        return 1
    fi
}

# Export the install function
# install 함수 내보내기
export -f install 