#!/bin/bash

# dockit 설치 스크립트
# dockit installation script

# 색상 정의
# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 설치 디렉토리
# Installation directory
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

# 디렉토리 생성
# Create directories
create_directories() {
    log_info "Creating installation directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$COMPLETION_DIR"
    mkdir -p "$ZSH_COMPLETION_DIR"
}

# dockit 스크립트 설치
# Install dockit script
install_dockit() {
    log_info "Installing dockit script..."
    cp dockit.sh "$INSTALL_DIR/dockit"
    chmod +x "$INSTALL_DIR/dockit"
}

# 자동완성 스크립트 설치
# Install completion scripts
install_completion() {
    log_info "Installing completion scripts..."
    
    # Bash completion
    cat > "$COMPLETION_DIR/dockit" << 'EOF'
_dockit_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    local commands="init start stop status config connect"
    
    if [[ ${cur} == * ]] ; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
    fi
}
complete -F _dockit_completion dockit
EOF

    # Zsh completion
    cat > "$ZSH_COMPLETION_DIR/_dockit" << 'EOF'
_dockit() {
    local -a commands
    commands=(
        'init:Initialize dockit project'
        'start:Start container'
        'stop:Stop container'
        'status:Check container status'
        'config:Manage configuration'
        'connect:Connect to container'
    )
    _describe 'command' commands
}
compdef _dockit dockit
EOF
}

# PATH 설정 확인
# Check PATH setting
check_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log_warn "Adding $INSTALL_DIR to PATH..."
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.zshrc"
    fi
}

# 설치 확인
# Verify installation
verify_installation() {
    if command -v dockit >/dev/null 2>&1; then
        log_info "Installation successful!"
        log_info "You can now use 'dockit' command."
        log_info "Try: dockit --help"
    else
        log_error "Installation failed!"
        exit 1
    fi
}

# 메인 설치 프로세스
# Main installation process
main() {
    log_info "Starting dockit installation..."
    
    create_directories
    install_dockit
    install_completion
    check_path
    verify_installation
    
    log_info "Please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
}

# 스크립트 실행
# Execute script
main 