#!/bin/bash

# dockit 제거 스크립트
# dockit uninstallation script

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

# dockit 스크립트 제거
# Remove dockit script
remove_dockit() {
    log_info "$(get_message MSG_UNINSTALL_REMOVING_SCRIPT)"
    if [ -f "$INSTALL_DIR/dockit" ]; then
        rm "$INSTALL_DIR/dockit"
        log_info "$(get_message MSG_UNINSTALL_SCRIPT_REMOVED)"
    else
        log_warn "$(get_message MSG_UNINSTALL_SCRIPT_NOT_FOUND) $INSTALL_DIR"
    fi
}

# 프로젝트 파일 제거
# Remove project files
remove_project() {
    log_info "$(get_message MSG_UNINSTALL_REMOVING_FILES)"
    if [ -d "$PROJECT_DIR" ]; then
        # 강제로 모든 하위 디렉토리와 파일 제거 (config 디렉토리 포함)
        find "$PROJECT_DIR" -mindepth 1 -delete 2>/dev/null
        rmdir "$PROJECT_DIR" 2>/dev/null
        
        # 디렉토리가 여전히 존재하는지 확인
        if [ -d "$PROJECT_DIR" ]; then
            # 더 강력한 방법으로 제거 시도
            rm -rf "$PROJECT_DIR"
        fi
        
        # 제거 확인
        if [ ! -d "$PROJECT_DIR" ]; then
            log_info "$(get_message MSG_UNINSTALL_FILES_REMOVED)"
        else
            log_warn "$(get_message MSG_UNINSTALL_REMOVE_FAILED) $PROJECT_DIR"
        fi
    else
        log_warn "$(get_message MSG_UNINSTALL_DIR_NOT_FOUND) $PROJECT_DIR"
    fi
}

# 자동완성 스크립트 제거
# Remove completion scripts
remove_completion() {
    log_info "$(get_message MSG_UNINSTALL_REMOVING_COMPLETION)"
    
    # Bash completion
    if [ -f "$COMPLETION_DIR/dockit" ]; then
        rm "$COMPLETION_DIR/dockit"
        log_info "$(get_message MSG_UNINSTALL_BASH_REMOVED)"
    fi
    
    # Zsh completion
    if [ -f "$ZSH_COMPLETION_DIR/_dockit" ]; then
        rm "$ZSH_COMPLETION_DIR/_dockit"
        log_info "$(get_message MSG_UNINSTALL_ZSH_REMOVED)"
    fi
}

# PATH에서 제거
# Remove from PATH
remove_from_path() {
    log_info "$(get_message MSG_UNINSTALL_REMOVING_PATH)"
    
    # Bash
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/export PATH=".*\/.local\/bin:/d' "$HOME/.bashrc"
        log_info "$(get_message MSG_UNINSTALL_REMOVED_BASHRC)"
    fi
    
    # Zsh
    if [ -f "$HOME/.zshrc" ]; then
        sed -i '/export PATH=".*\/.local\/bin:/d' "$HOME/.zshrc"
        log_info "$(get_message MSG_UNINSTALL_REMOVED_ZSHRC)"
    fi
}

# 설치 디렉토리 정리
# Clean up installation directories
cleanup_directories() {
    log_info "$(get_message MSG_UNINSTALL_CLEANING_DIRS)"
    
    # 빈 디렉토리 제거
    # Remove empty directories
    if [ -d "$INSTALL_DIR" ] && [ -z "$(ls -A $INSTALL_DIR)" ]; then
        rmdir "$INSTALL_DIR"
        log_info "$(get_message MSG_UNINSTALL_REMOVED_EMPTY_DIR) $INSTALL_DIR"
    fi
    
    if [ -d "$COMPLETION_DIR" ] && [ -z "$(ls -A $COMPLETION_DIR)" ]; then
        rmdir "$COMPLETION_DIR"
        log_info "$(get_message MSG_UNINSTALL_REMOVED_EMPTY_DIR) $COMPLETION_DIR"
    fi
    
    if [ -d "$ZSH_COMPLETION_DIR" ] && [ -z "$(ls -A $ZSH_COMPLETION_DIR)" ]; then
        rmdir "$ZSH_COMPLETION_DIR"
        log_info "$(get_message MSG_UNINSTALL_REMOVED_EMPTY_DIR) $ZSH_COMPLETION_DIR"
    fi
}

# 제거 확인
# Verify uninstallation
verify_uninstallation() {
    if ! command -v dockit >/dev/null 2>&1; then
        log_info "$(get_message MSG_UNINSTALL_SUCCESSFUL)"
    else
        log_error "$(get_message MSG_UNINSTALL_INCOMPLETE)"
        exit 1
    fi
}

# 자동완성 설정 제거
# Remove completion settings
remove_completion_settings() {
    log_info "$(get_message MSG_UNINSTALL_REMOVING_COMPLETION_CONFIG)"
    
    # Bash 자동완성 설정 제거
    if [ -f "$HOME/.bashrc" ]; then
        # dockit 자동완성 관련 라인 제거
        sed -i '/# Dockit completion/d' "$HOME/.bashrc"
        sed -i '/\[ -f.*dockit \] && source.*dockit/d' "$HOME/.bashrc"
        log_info "$(get_message MSG_UNINSTALL_REMOVED_BASH_COMPLETION)"
    fi
    
    # ZSH 자동완성 설정 제거
    if [ -f "$HOME/.zshrc" ]; then
        # dockit 자동완성 관련 라인 제거
        sed -i '/# dockit 자동완성/d' "$HOME/.zshrc"
        sed -i '/# Load dockit completion/d' "$HOME/.zshrc"
        sed -i '/\[ -f.*_dockit \] && source/d' "$HOME/.zshrc"
        sed -i '/fpath=(.*dockit/d' "$HOME/.zshrc"
        log_info "$(get_message MSG_UNINSTALL_REMOVED_ZSH_COMPLETION)"
    fi
    
    # 시스템 전역 자동완성 제거
    if [ -f "/etc/bash_completion.d/dockit" ] && [ -w "/etc/bash_completion.d/dockit" ]; then
        rm "/etc/bash_completion.d/dockit"
        log_info "$(get_message MSG_UNINSTALL_REMOVED_GLOBAL_COMPLETION)"
    fi
}

# 사용자 설정 디렉토리 제거
# Remove user config directory
remove_config_dir() {
    log_info "$(get_message MSG_UNINSTALL_REMOVING_CONFIG)"
    local config_dir="$HOME/.config/dockit"
    
    if [ -d "$config_dir" ]; then
        rm -rf "$config_dir"
        log_info "$(get_message MSG_UNINSTALL_CONFIG_REMOVED)"
    fi
}

# 메인 제거 프로세스
# Main uninstallation process
main() {
    log_info "$(get_message MSG_UNINSTALL_START)"
    
    # 제거 확인
    echo ""
    log_info "$(get_message MSG_UNINSTALL_CONFIRM) [y/N]"
    read -r confirm
    
    # 소문자로 변환
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    
    # 'y' 또는 'yes'가 아니면 종료
    if [ "$confirm" != "y" ] && [ "$confirm" != "yes" ]; then
        log_info "$(get_message MSG_UNINSTALL_CANCELLED)"
        exit 0
    fi
    
    # 제거 프로세스 시작
    remove_dockit
    remove_project
    remove_completion
    remove_completion_settings
    remove_config_dir
    remove_from_path
    cleanup_directories
    verify_uninstallation
    
    log_info "$(get_message MSG_UNINSTALL_RESTART_SHELL)"
}

# 스크립트 실행
# Execute script
main 