#!/bin/bash

# dockit 제거 스크립트
# dockit uninstallation script

# 설치 디렉토리
# Installation directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$HOME/.dockit"
INSTALL_DIR="$HOME/.dockit/bin"
COMPLETION_DIR="$HOME/.dockit/completion/bash"
ZSH_COMPLETION_DIR="$HOME/.dockit/completion/zsh"
UTILS_DIR="${PROJECT_ROOT}/src/utils"

# 유틸리티 모듈 로드 (가능한 경우)
# Load utility modules if available
source "${UTILS_DIR}/utils.sh"

# 언어 설정 불러오기
# Load language settings
load_language_setting() {
    # 설치된 환경의 설정 파일만 확인
    local settings_file="$HOME/.dockit/config/settings.env"
    
    # 기본값은 영어
    export LANGUAGE="en"
    
    # 설치된 환경의 설정 파일이 있으면 로드
    if [ -f "$settings_file" ]; then
        source "$settings_file"
    fi
}

# 언어 설정 로드
load_language_setting

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
        # 강제로 모든 하위 디렉토리와 파일 제거
        rm -rf "$PROJECT_DIR"
        
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

# PATH에서 제거
# Remove from PATH
remove_from_path() {
    log_info "$(get_message MSG_UNINSTALL_REMOVING_PATH)"
    
    # Bash
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/export PATH=".*\/.dockit\/bin:/d' "$HOME/.bashrc"
        log_info "$(get_message MSG_UNINSTALL_REMOVED_BASHRC)"
    fi
    
    # Zsh
    if [ -f "$HOME/.zshrc" ]; then
        sed -i '/export PATH=".*\/.dockit\/bin:/d' "$HOME/.zshrc"
        log_info "$(get_message MSG_UNINSTALL_REMOVED_ZSHRC)"
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
    remove_project          # ~/.dockit 전체 삭제 (dockit 스크립트 포함)
    remove_completion_settings  # 자동완성 설정 제거
    remove_from_path        # PATH 설정 제거
    verify_uninstallation   # 제거 확인
    
    log_info "$(get_message MSG_UNINSTALL_RESTART_SHELL)"
}

# 스크립트 실행
# Execute script
main 