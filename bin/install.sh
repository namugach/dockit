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

# 메시지 시스템 로드
# Load message system
if [ -f "$PROJECT_ROOT/config/messages/load.sh" ]; then
    source "$PROJECT_ROOT/config/messages/load.sh"
    load_messages
fi

# 언어 설정 로드
# Load language settings
if [ -f "$PROJECT_ROOT/config/system.sh" ]; then
    source "$PROJECT_ROOT/config/system.sh"
fi

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
    log_info "$(get_message MSG_INSTALL_CHECKING_DEPENDENCIES)"
    
    # Docker 체크
    if ! command -v docker >/dev/null 2>&1; then
        log_error "$(get_message MSG_INSTALL_DOCKER_MISSING)"
        exit 1
    fi
    
    # Docker Compose 체크 (docker-compose 또는 docker compose)
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        log_error "$(get_message MSG_INSTALL_COMPOSE_MISSING)"
        exit 1
    fi
    
    # 기본 도구 체크
    local required_tools=("git" "curl" "sed" "grep")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_error "$(printf "$(get_message MSG_INSTALL_TOOL_MISSING)" "$tool" "$tool")"
            exit 1
        fi
    done
    
    log_info "$(get_message MSG_INSTALL_DEPENDENCIES_OK)"
}

# 기존 설치 확인
# Check existing installation
check_existing_installation() {
    log_info "$(get_message MSG_INSTALL_CHECKING_EXISTING)"
    
    # dockit 명령어 체크
    if command -v dockit >/dev/null 2>&1; then
        log_warn "$(get_message MSG_INSTALL_ALREADY_INSTALLED)"
        read -p "$(get_message MSG_INSTALL_REINSTALL) " reinstall
        if [[ ! $reinstall =~ ^[Yy]$ ]]; then
            log_info "$(get_message MSG_INSTALL_CANCELLED)"
            exit 0
        fi
    fi
    
    # 프로젝트 디렉토리 체크
    if [ -d "$PROJECT_DIR" ]; then
        log_warn "$(printf "$(get_message MSG_INSTALL_DIR_EXISTS)" "$PROJECT_DIR")"
        read -p "$(get_message MSG_INSTALL_OVERWRITE) " overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            log_info "$(get_message MSG_INSTALL_CANCELLED)"
            exit 0
        fi
    fi
}

# 권한 체크
# Check permissions
check_permissions() {
    log_info "$(get_message MSG_INSTALL_CHECKING_PERMISSIONS)"
    
    # 설치 디렉토리 권한 체크
    local dirs=("$INSTALL_DIR" "$PROJECT_DIR" "$COMPLETION_DIR" "$ZSH_COMPLETION_DIR" "$CONFIG_DIR")
    for dir in "${dirs[@]}"; do
        if [ ! -w "$(dirname "$dir")" ]; then
            log_error "$(printf "$(get_message MSG_INSTALL_NO_PERMISSION)" "$(dirname "$dir")")"
            log_info "$(get_message MSG_INSTALL_USE_SUDO)"
            exit 1
        fi
    done
}

# 디렉토리 생성
# Create directories
create_directories() {
    log_info "$(get_message MSG_INSTALL_CREATING_DIRS)"
    mkdir -p "$PROJECT_DIR"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$COMPLETION_DIR"
    mkdir -p "$ZSH_COMPLETION_DIR"
    mkdir -p "$CONFIG_DIR"
}

# 프로젝트 파일 설치
# Install project files
install_project() {
    log_info "$(get_message MSG_INSTALL_INSTALLING_FILES)"
    
    # 기존 설치 제거
    rm -rf "$PROJECT_DIR"
    
    # 프로젝트 파일 복사
    mkdir -p "$PROJECT_DIR"
    cp -r "$PROJECT_ROOT/src" "$PROJECT_DIR/"
    cp -r "$PROJECT_ROOT/config" "$PROJECT_DIR/"
    cp -r "$PROJECT_ROOT/completion" "$PROJECT_DIR/"
    
    # VERSION 파일 복사
    mkdir -p "$PROJECT_DIR/bin"
    cp "$PROJECT_ROOT/bin/VERSION" "$PROJECT_DIR/bin/"
    
    # dockit 스크립트 설치
    cp "$PROJECT_ROOT/bin/dockit.sh" "$INSTALL_DIR/dockit"
    chmod +x "$INSTALL_DIR/dockit"
    
    # 스크립트 경로 수정
    sed -i "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$PROJECT_DIR\"|" "$INSTALL_DIR/dockit"
    sed -i "s|MODULES_DIR=.*|MODULES_DIR=\"$PROJECT_DIR/src/modules\"|" "$INSTALL_DIR/dockit"
    sed -i "s|CONFIG_DIR=.*|CONFIG_DIR=\"$PROJECT_DIR/config\"|" "$INSTALL_DIR/dockit"
    
    log_info "$(printf "$(get_message MSG_INSTALL_PATH)" "$PROJECT_DIR")"
}

# 자동완성 스크립트 설치
# Install completion scripts
install_completion() {
    log_info "$(get_message MSG_INSTALL_INSTALLING_COMPLETION)"
    
    # Bash completion 디렉토리 확인 및 생성
    mkdir -p "$COMPLETION_DIR"
    
    # Zsh completion 디렉토리 확인 및 생성
    mkdir -p "$ZSH_COMPLETION_DIR"
    
    # Bash completion 설치
    cp "$PROJECT_DIR/completion/dockit.sh" "$COMPLETION_DIR/dockit"
    chmod +x "$COMPLETION_DIR/dockit"
    
    # Zsh completion 설치
    cp "$PROJECT_DIR/completion/dockit.zsh" "$ZSH_COMPLETION_DIR/_dockit"
    chmod +x "$ZSH_COMPLETION_DIR/_dockit"
    
    # 시스템 전체 설치 시도 (sudo 권한 있는 경우)
    if [ -d "/etc/bash_completion.d" ] && [ -w "/etc/bash_completion.d" ]; then
        cp "$PROJECT_DIR/completion/dockit.sh" "/etc/bash_completion.d/dockit"
        chmod +x "/etc/bash_completion.d/dockit"
        log_info "$(get_message MSG_INSTALL_GLOBAL_COMPLETION)"
    fi
    
    # 현재 세션에 자동완성 로드
    if [ -n "$BASH_VERSION" ]; then
        source "$COMPLETION_DIR/dockit"
    elif [ -n "$ZSH_VERSION" ]; then
        # ZSH에서는 특별한 처리 필요
        autoload -U compinit
        compinit
    fi
    
    log_info "$(get_message MSG_INSTALL_COMPLETION_HELP)"
}

# PATH 설정 확인
# Check PATH setting
check_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log_warn "$(get_message MSG_INSTALL_ADDING_PATH)"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.zshrc"
    fi
    
    # ZSH 자동완성 설정 추가
    if [ -f "$HOME/.zshrc" ]; then
        # ZSH 완성 시스템 활성화 확인
        if ! grep -q "autoload -Uz compinit" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# $(get_message MSG_INSTALL_ZSH_COMPLETION_ACTIVATE)" >> "$HOME/.zshrc"
            echo "autoload -Uz compinit" >> "$HOME/.zshrc"
            echo "compinit" >> "$HOME/.zshrc"
        fi
        
        # fpath 설정 확인
        if ! grep -q "fpath=.*$ZSH_COMPLETION_DIR" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# $(get_message MSG_INSTALL_ZSH_COMPLETION_ADD_PATH)" >> "$HOME/.zshrc"
            echo "fpath=($ZSH_COMPLETION_DIR \$fpath)" >> "$HOME/.zshrc"
        fi
        
        # ZSH에서는 특별히 직접 source 명령어 추가
        if ! grep -q "source $ZSH_COMPLETION_DIR/_dockit" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# $(get_message MSG_INSTALL_ZSH_COMPLETION_LOAD)" >> "$HOME/.zshrc"
            echo "[ -f $ZSH_COMPLETION_DIR/_dockit ] && source $ZSH_COMPLETION_DIR/_dockit" >> "$HOME/.zshrc"
        fi
        
        log_info "$(get_message MSG_INSTALL_ZSH_COMPLETION_ADDED)"
    fi
}

# 설치 확인
# Verify installation
verify_installation() {
    if command -v dockit >/dev/null 2>&1; then
        log_info "$(get_message MSG_INSTALL_COMPLETED)"
        log_info "$(get_message MSG_INSTALL_CMD_AVAILABLE)"
        log_info "$(get_message MSG_INSTALL_HELP_TIP)"
    else
        log_error "$(get_message MSG_INSTALL_FAILED)"
        exit 1
    fi
}

# 메인 설치 프로세스
# Main installation process
main() {
    log_info "$(get_message MSG_INSTALL_START)"
    
    check_dependencies
    check_existing_installation
    check_permissions
    create_directories
    install_project
    install_completion
    check_path
    verify_installation
    
    # 설치 후 안내 메시지
    echo ""
    log_info "$(get_message MSG_INSTALL_SHELL_RESTART)"
    log_info "$(get_message MSG_INSTALL_COMPLETION_ENABLE)"
    echo ""
    log_info "$(get_message MSG_INSTALL_BASH_RELOAD)"
    echo "        source ~/.bashrc"
    log_info "$(get_message MSG_INSTALL_ZSH_RELOAD)"
    echo "        source ~/.zshrc"
}

# 메시지 출력 함수 (시스템에 없는 경우를 위한 예비)
# Function to print messages (fallback if system doesn't have it)
if ! type get_message &>/dev/null; then
    get_message() {
        local message_key="$1"
        if [ -n "${!message_key}" ]; then
            echo "${!message_key}"
        else
            echo "$message_key"
        fi
    }
fi

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