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
PROJECT_DIR="$HOME/.local/share/dockit"
INSTALL_DIR="$HOME/.local/bin"
COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
ZSH_COMPLETION_DIR="$HOME/.local/share/zsh/site-functions"

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

# dockit 스크립트 제거
# Remove dockit script
remove_dockit() {
    log_info "Removing dockit script..."
    if [ -f "$INSTALL_DIR/dockit" ]; then
        rm "$INSTALL_DIR/dockit"
        log_info "dockit script removed successfully."
    else
        log_warn "dockit script not found in $INSTALL_DIR"
    fi
}

# 프로젝트 파일 제거
# Remove project files
remove_project() {
    log_info "Removing project files..."
    if [ -d "$PROJECT_DIR" ]; then
        rm -rf "$PROJECT_DIR"
        log_info "Project files removed successfully."
    else
        log_warn "Project directory not found: $PROJECT_DIR"
    fi
}

# 자동완성 스크립트 제거
# Remove completion scripts
remove_completion() {
    log_info "Removing completion scripts..."
    
    # Bash completion
    if [ -f "$COMPLETION_DIR/dockit" ]; then
        rm "$COMPLETION_DIR/dockit"
        log_info "Bash completion script removed."
    fi
    
    # Zsh completion
    if [ -f "$ZSH_COMPLETION_DIR/_dockit" ]; then
        rm "$ZSH_COMPLETION_DIR/_dockit"
        log_info "Zsh completion script removed."
    fi
}

# PATH에서 제거
# Remove from PATH
remove_from_path() {
    log_info "Removing dockit from PATH..."
    
    # Bash
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/export PATH=".*\/.local\/bin:/d' "$HOME/.bashrc"
        log_info "Removed from .bashrc"
    fi
    
    # Zsh
    if [ -f "$HOME/.zshrc" ]; then
        sed -i '/export PATH=".*\/.local\/bin:/d' "$HOME/.zshrc"
        log_info "Removed from .zshrc"
    fi
}

# 설치 디렉토리 정리
# Clean up installation directories
cleanup_directories() {
    log_info "Cleaning up installation directories..."
    
    # 빈 디렉토리 제거
    # Remove empty directories
    if [ -d "$INSTALL_DIR" ] && [ -z "$(ls -A $INSTALL_DIR)" ]; then
        rmdir "$INSTALL_DIR"
        log_info "Removed empty directory: $INSTALL_DIR"
    fi
    
    if [ -d "$COMPLETION_DIR" ] && [ -z "$(ls -A $COMPLETION_DIR)" ]; then
        rmdir "$COMPLETION_DIR"
        log_info "Removed empty directory: $COMPLETION_DIR"
    fi
    
    if [ -d "$ZSH_COMPLETION_DIR" ] && [ -z "$(ls -A $ZSH_COMPLETION_DIR)" ]; then
        rmdir "$ZSH_COMPLETION_DIR"
        log_info "Removed empty directory: $ZSH_COMPLETION_DIR"
    fi
}

# 제거 확인
# Verify uninstallation
verify_uninstallation() {
    if ! command -v dockit >/dev/null 2>&1; then
        log_info "Uninstallation successful!"
    else
        log_error "Uninstallation may be incomplete. Please check manually."
        exit 1
    fi
}

# 메인 제거 프로세스
# Main uninstallation process
main() {
    log_info "Starting dockit uninstallation..."
    
    remove_dockit
    remove_project
    remove_completion
    remove_from_path
    cleanup_directories
    verify_uninstallation
    
    log_info "Please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
}

# 스크립트 실행
# Execute script
main 