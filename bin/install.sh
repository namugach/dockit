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

# 언어 설정 불러오기 함수
# Function to load language settings
load_language_setting() {
    # 설치된 환경의 설정 파일만 확인
    # Only check settings file in installed environment
    local settings_file="$HOME/.local/share/dockit/config/settings.env"
    
    # 기본값은 영어
    # Default is English
    export LANGUAGE="en"
    
    # 설치된 환경의 설정 파일이 있으면 로드
    # Load if settings file exists in installed environment
    if [ -f "$settings_file" ]; then
        source "$settings_file"
    fi
}

# 언어 설정 로드
# Load language settings
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

# 로그 출력 함수들
# Log output functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 의존성 체크 함수들
# Dependency check functions
check_dependencies() {
    log_info "$(get_message MSG_INSTALL_CHECKING_DEPENDENCIES)"
    
    check_docker_dependency
    check_compose_dependency
    check_basic_tools
    
    log_info "$(get_message MSG_INSTALL_DEPENDENCIES_OK)"
}

# Docker 의존성 체크
# Check Docker dependency
check_docker_dependency() {
    if ! command -v docker >/dev/null 2>&1; then
        log_error "$(get_message MSG_INSTALL_DOCKER_MISSING)"
        exit 1
    fi
}

# Docker Compose 의존성 체크
# Check Docker Compose dependency
check_compose_dependency() {
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        log_error "$(get_message MSG_INSTALL_COMPOSE_MISSING)"
        exit 1
    fi
}

# 기본 도구 체크
# Check basic tools
check_basic_tools() {
    local required_tools=("git" "curl" "sed" "grep")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_error "$(printf "$(get_message MSG_INSTALL_TOOL_MISSING)" "$tool" "$tool")"
            exit 1
        fi
    done
}

# 기존 설치 확인 함수들
# Functions to check existing installation
check_existing_installation() {
    log_info "$(get_message MSG_INSTALL_CHECKING_EXISTING)"
    
    check_existing_command
    check_existing_directory
}

# 기존 명령어 확인
# Check existing command
check_existing_command() {
    if command -v dockit >/dev/null 2>&1; then
        log_warn "$(get_message MSG_INSTALL_ALREADY_INSTALLED)"
        read -p "$(get_message MSG_INSTALL_REINSTALL) " reinstall
        if [[ ! $reinstall =~ ^[Yy]$ ]]; then
            log_info "$(get_message MSG_INSTALL_CANCELLED)"
            exit 0
        fi
    fi
}

# 기존 디렉토리 확인
# Check existing directory
check_existing_directory() {
    if [ -d "$PROJECT_DIR" ]; then
        log_warn "$(printf "$(get_message MSG_INSTALL_DIR_EXISTS)" "$PROJECT_DIR")"
        read -p "$(get_message MSG_INSTALL_OVERWRITE) " overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            log_info "$(get_message MSG_INSTALL_CANCELLED)"
            exit 0
        fi
    fi
}

# 권한 체크 함수들
# Permission check functions
check_permissions() {
    log_info "$(get_message MSG_INSTALL_CHECKING_PERMISSIONS)"
    
    check_directory_permissions
}

# 디렉토리 권한 체크
# Check directory permissions
check_directory_permissions() {
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

# 프로젝트 파일 설치 (언어 설정 보존)
# Install project files while preserving language settings
install_project_preserving_lang() {
    log_info "$(get_message MSG_INSTALL_INSTALLING_FILES)"
    
    backup_language_settings
    backup_messages
    remove_old_installation
    copy_project_files
    restore_language_settings
    restore_messages
    
    log_info "$(printf "$(get_message MSG_INSTALL_PATH)" "$PROJECT_DIR")"
}

# 언어 설정 백업
# Backup language settings
backup_language_settings() {
    if [ -f "$PROJECT_DIR/config/settings.env" ]; then
        lang_settings=$(grep "LANGUAGE=" "$PROJECT_DIR/config/settings.env")
    fi
}

# 메시지 백업
# Backup messages
backup_messages() {
    local temp_dir="/tmp/dockit_messages_backup"
    if [ -d "$PROJECT_DIR/config/messages" ]; then
        mkdir -p "$temp_dir"
        cp -r "$PROJECT_DIR/config/messages/"* "$temp_dir/"
    fi
}

# 기존 설치 제거
# Remove old installation
remove_old_installation() {
    rm -rf "$PROJECT_DIR/src" "$PROJECT_DIR/src/completion" "$PROJECT_DIR/bin"
}

# 프로젝트 파일 복사
# Copy project files
copy_project_files() {
    mkdir -p "$PROJECT_DIR/src" "$PROJECT_DIR/src/completion" "$PROJECT_DIR/bin"
    cp -r "$PROJECT_ROOT/src/"* "$PROJECT_DIR/src/"
    cp -r "$PROJECT_ROOT/src/completion/"* "$PROJECT_DIR/src/completion/"
    cp "$PROJECT_ROOT/bin/VERSION" "$PROJECT_DIR/bin/"
    install_dockit_script
}

# Dockit 스크립트 설치
# Install dockit script
install_dockit_script() {
    cp "$PROJECT_ROOT/bin/dockit.sh" "$INSTALL_DIR/dockit"
    chmod +x "$INSTALL_DIR/dockit"
    update_script_paths
}

# 스크립트 경로 업데이트
# Update script paths
update_script_paths() {
    sed -i "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$PROJECT_DIR\"|" "$INSTALL_DIR/dockit"
    sed -i "s|MODULES_DIR=.*|MODULES_DIR=\"$PROJECT_DIR/src/modules\"|" "$INSTALL_DIR/dockit"
    sed -i "s|CONFIG_DIR=.*|CONFIG_DIR=\"$PROJECT_DIR/config\"|" "$INSTALL_DIR/dockit"
}

# 언어 설정 복원
# Restore language settings
restore_language_settings() {
    if [ -n "$lang_settings" ]; then
        sed -i "s/LANGUAGE=.*/$lang_settings/" "$PROJECT_DIR/config/settings.env"
    fi
}

# 메시지 복원
# Restore messages
restore_messages() {
    local temp_dir="/tmp/dockit_messages_backup"
    if [ -d "$temp_dir" ] && [ "$(ls -A "$temp_dir")" ]; then
        cp -r "$temp_dir/"* "$PROJECT_DIR/config/messages/"
        rm -rf "$temp_dir"
    fi
}

# 언어 설정 함수
# Language setup function
setup_language() {
    local lang_dir="$PROJECT_ROOT/config/messages"
    local default_lang="en"
    
    find_available_languages
    display_language_options
    handle_language_selection
}

# 사용 가능한 언어 찾기
# Find available languages
find_available_languages() {
    langs=()
    lang_names=()
    default_idx=0
    i=0
    
    log_info "Finding available languages..."
    for lang_file in "$lang_dir"/*.sh; do
        if [ -f "$lang_file" ]; then
            process_language_file "$lang_file"
        fi
    done
    
    # 언어가 없으면 영어를 기본값으로 설정
    # Set English as default if no languages found
    if [ ${#langs[@]} -eq 0 ]; then
        langs=("en")
        lang_names=("English")
        default_idx=0
    fi
}

# 언어 파일 처리
# Process language file
process_language_file() {
    local lang_file="$1"
    local code=""
    local name=""
    
    code=$(grep "^LANG_CODE=" "$lang_file" | cut -d'"' -f2)
    name=$(grep "^LANG_NAME=" "$lang_file" | cut -d'"' -f2)
    
    if [ -n "$code" ] && [ -n "$name" ]; then
        langs+=("$code")
        lang_names+=("$name")
        
        if [ "$code" = "$default_lang" ]; then
            default_idx=$i
        fi
        
        i=$((i+1))
    fi
}

# 언어 옵션 표시
# Display language options
display_language_options() {
    echo ""
    log_info "$(get_message MSG_INSTALL_LANGUAGE_AVAILABLE)"
    echo "  0. $(get_message MSG_CANCEL)"
    
    for i in "${!langs[@]}"; do
        local default_mark=""
        if [ $i -eq $default_idx ]; then
            default_mark=" ($(get_message MSG_INSTALL_LANGUAGE_DEFAULT))"
        fi
        echo "  $((i+1)). ${lang_names[$i]}${default_mark}"
    done
}

# 언어 선택 처리
# Handle language selection
handle_language_selection() {
    echo ""
    log_info "$(get_message MSG_INSTALL_LANGUAGE_SELECT) (0-${#langs[@]}):"
    read -r lang_choice
    
    if [ "$lang_choice" = "0" ]; then
        log_info "$(get_message MSG_INSTALL_CANCELLED)"
        exit 0
    fi
    
    process_language_choice
}

# 언어 선택 처리
# Process language choice
process_language_choice() {
    if [[ "$lang_choice" =~ ^[0-9]+$ ]] && [ "$lang_choice" -ge 1 ] && [ "$lang_choice" -le "${#langs[@]}" ]; then
        set_selected_language
    else
        set_default_language
    fi
    
    apply_language_settings
}

# 선택된 언어 설정
# Set selected language
set_selected_language() {
    local idx=$((lang_choice-1))
    local selected_lang="${langs[$idx]}"
    local selected_name="${lang_names[$idx]}"
    
    save_language_setting "$selected_lang"
    load_language_file "$selected_lang"
    printf "$(get_message MSG_INSTALL_LANGUAGE_SELECTED)\n" "$selected_name" "$selected_lang"
}

# 기본 언어 설정
# Set default language
set_default_language() {
    local default_lang="${langs[$default_idx]}"
    local default_name="${lang_names[$default_idx]}"
    
    save_language_setting "$default_lang"
    load_language_file "$default_lang"
    printf "$(get_message MSG_INSTALL_LANGUAGE_INVALID)\n" "$default_name" "$default_lang"
}

# 언어 설정 저장
# Save language setting
save_language_setting() {
    local lang="$1"
    echo "LANGUAGE=\"$lang\"" > "$PROJECT_DIR/config/settings.env"
    export LANGUAGE="$lang"
}

# 언어 파일 로드
# Load language file
load_language_file() {
    local lang="$1"
    if [ -f "$PROJECT_ROOT/config/messages/$lang.sh" ]; then
        source "$PROJECT_ROOT/config/messages/$lang.sh"
    fi
}

# 언어 설정에 따른 추가 설정 적용
# Apply additional settings based on language selection
apply_language_settings() {
    local selected_lang="$LANGUAGE"
    local lang_file="$PROJECT_ROOT/config/messages/$selected_lang.sh"
    
    if [ -f "$lang_file" ]; then
        apply_locale_setting "$lang_file"
        apply_timezone_setting "$lang_file"
    fi
}

# 로케일 설정 적용
# Apply locale setting
apply_locale_setting() {
    local lang_file="$1"
    local locale=$(grep "^LANG_LOCALE=" "$lang_file" | cut -d'"' -f2)
    
    if [ -n "$locale" ]; then
        echo "LOCALE=\"$locale\"" >> "$PROJECT_DIR/config/settings.env"
        export LOCALE="$locale"
        log_info "Locale set to: $locale"
    fi
}

# 타임존 설정 적용
# Apply timezone setting
apply_timezone_setting() {
    local lang_file="$1"
    local timezone=$(grep "^LANG_TIMEZONE=" "$lang_file" | cut -d'"' -f2)
    
    if [ -n "$timezone" ]; then
        echo "TIMEZONE=\"$timezone\"" >> "$PROJECT_DIR/config/settings.env"
        export TIMEZONE="$timezone" 
        log_info "Timezone set to: $timezone"
    fi
}

# 자동완성 스크립트 설치
# Install completion scripts
install_completion() {
    log_info "$(get_message MSG_INSTALL_INSTALLING_COMPLETION)"
    
    create_completion_directories
    install_common_modules
    install_shell_completions
    install_system_completion
    configure_shell_completion
    load_current_session_completion
    
    log_info "$(get_message MSG_INSTALL_COMPLETION_HELP)"
}

# 자동완성 디렉토리 생성
# Create completion directories
create_completion_directories() {
    mkdir -p "$COMPLETION_DIR"
    mkdir -p "$ZSH_COMPLETION_DIR"
}

# 공통 모듈 설치
# Install common modules
install_common_modules() {
    cp "$PROJECT_DIR/src/completion/completion-common.sh" "$COMPLETION_DIR/"
    cp "$PROJECT_DIR/src/completion/completion-common.sh" "$ZSH_COMPLETION_DIR/"
    chmod +x "$COMPLETION_DIR/completion-common.sh"
    chmod +x "$ZSH_COMPLETION_DIR/completion-common.sh"
}

# 쉘별 자동완성 설치
# Install shell-specific completions
install_shell_completions() {
    # Bash completion
    cp "$PROJECT_DIR/src/completion/bash.sh" "$COMPLETION_DIR/dockit"
    chmod +x "$COMPLETION_DIR/dockit"
    
    # Zsh completion
    cp "$PROJECT_DIR/src/completion/zsh.sh" "$ZSH_COMPLETION_DIR/_dockit"
    chmod +x "$ZSH_COMPLETION_DIR/_dockit"
}

# 시스템 자동완성 설치
# Install system completion
install_system_completion() {
    if [ -d "/etc/bash_completion.d" ] && [ -w "/etc/bash_completion.d" ]; then
        cp "$PROJECT_DIR/src/completion/completion-common.sh" "/etc/bash_completion.d/"
        chmod +x "/etc/bash_completion.d/completion-common.sh"
        
        cp "$PROJECT_DIR/src/completion/bash.sh" "/etc/bash_completion.d/dockit"
        chmod +x "/etc/bash_completion.d/dockit"
        log_info "$(get_message MSG_INSTALL_GLOBAL_COMPLETION)"
    fi
}

# 쉘 자동완성 설정
# Configure shell completion
configure_shell_completion() {
    configure_bash_completion
    configure_zsh_completion
}

# Bash 자동완성 설정
# Configure Bash completion
configure_bash_completion() {
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "source $COMPLETION_DIR/dockit" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Dockit completion" >> "$HOME/.bashrc"
            echo "[ -f $COMPLETION_DIR/dockit ] && source $COMPLETION_DIR/dockit" >> "$HOME/.bashrc"
        fi
    fi
}

# Zsh 자동완성 설정
# Configure Zsh completion
configure_zsh_completion() {
    if [ -f "$HOME/.zshrc" ]; then
        configure_zsh_completion_system
        configure_zsh_completion_path
        configure_zsh_completion_source
        
        log_info "$(get_message MSG_INSTALL_ZSH_COMPLETION_ADDED)"
    fi
}

# Zsh 자동완성 시스템 설정
# Configure Zsh completion system
configure_zsh_completion_system() {
    if ! grep -q "autoload -Uz compinit" "$HOME/.zshrc"; then
        echo "" >> "$HOME/.zshrc"
        echo "# $(get_message MSG_INSTALL_ZSH_COMPLETION_ACTIVATE)" >> "$HOME/.zshrc"
        echo "autoload -Uz compinit" >> "$HOME/.zshrc"
        echo "compinit" >> "$HOME/.zshrc"
    fi
}

# Zsh 자동완성 경로 설정
# Configure Zsh completion path
configure_zsh_completion_path() {
    if ! grep -q "fpath=.*$ZSH_COMPLETION_DIR" "$HOME/.zshrc"; then
        echo "" >> "$HOME/.zshrc"
        echo "# $(get_message MSG_INSTALL_ZSH_COMPLETION_ADD_PATH)" >> "$HOME/.zshrc"
        echo "fpath=($ZSH_COMPLETION_DIR \$fpath)" >> "$HOME/.zshrc"
    fi
}

# Zsh 자동완성 소스 설정
# Configure Zsh completion source
configure_zsh_completion_source() {
    if ! grep -q "source $ZSH_COMPLETION_DIR/_dockit" "$HOME/.zshrc"; then
        echo "" >> "$HOME/.zshrc"
        echo "# $(get_message MSG_INSTALL_ZSH_COMPLETION_LOAD)" >> "$HOME/.zshrc"
        echo "[ -f $ZSH_COMPLETION_DIR/_dockit ] && source $ZSH_COMPLETION_DIR/_dockit" >> "$HOME/.zshrc"
    fi
}

# 현재 세션 자동완성 로드
# Load current session completion
load_current_session_completion() {
    if [ -n "$BASH_VERSION" ]; then
        source "$COMPLETION_DIR/dockit"
    elif [ -n "$ZSH_VERSION" ]; then
        autoload -U compinit
        compinit
    fi
}

# PATH 설정 확인
# Check PATH setting
check_path() {
    check_and_update_path
    configure_zsh_settings
}

# PATH 확인 및 업데이트
# Check and update PATH
check_and_update_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log_warn "$(get_message MSG_INSTALL_ADDING_PATH)"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.zshrc"
    fi
}

# Zsh 설정 구성
# Configure Zsh settings
configure_zsh_settings() {
    if [ -f "$HOME/.zshrc" ]; then
        configure_zsh_completion_system
        configure_zsh_completion_path
        configure_zsh_completion_source
        log_info "$(get_message MSG_INSTALL_ZSH_COMPLETION_ADDED)"
    fi
}

# 설치 확인
# Verify installation
verify_installation() {
    if command -v dockit >/dev/null 2>&1; then
        show_success_message
    else
        show_failure_message
    fi
}

# 성공 메시지 표시
# Show success message
show_success_message() {
    log_info "$(get_message MSG_INSTALL_COMPLETED)"
    log_info "$(get_message MSG_INSTALL_CMD_AVAILABLE)"
    log_info "$(get_message MSG_INSTALL_HELP_TIP)"
}

# 실패 메시지 표시
# Show failure message
show_failure_message() {
    log_error "$(get_message MSG_INSTALL_FAILED)"
    exit 1
}

# 메인 설치 프로세스
# Main installation process
main() {
    initialize_installation
    perform_initial_checks
    setup_language
    perform_main_installation
    show_final_instructions
}

# 설치 초기화
# Initialize installation
initialize_installation() {
    log_info "Starting dockit installation..."
    check_minimal_requirements
}

# 최소 요구사항 체크
# Check minimal requirements
check_minimal_requirements() {
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker not installed. Please install Docker first."
        exit 1
    fi
    
    if [ ! -w "$(dirname "$PROJECT_DIR")" ] || [ ! -w "$(dirname "$INSTALL_DIR")" ]; then
        log_error "Permission denied. Please check your permissions."
        log_info "You may need to run with sudo or check directory permissions."
        exit 1
    fi
}

# 초기 체크 수행
# Perform initial checks
perform_initial_checks() {
    check_existing_installation
    create_initial_directories
    copy_language_files
}

# 초기 디렉토리 생성
# Create initial directories
create_initial_directories() {
    mkdir -p "$PROJECT_DIR/config/messages"
}

# 언어 파일 복사
# Copy language files
copy_language_files() {
    cp "$PROJECT_ROOT/config/settings.env" "$PROJECT_DIR/config/"
    cp -r "$PROJECT_ROOT/config/messages/"* "$PROJECT_DIR/config/messages/"
}

# 메인 설치 수행
# Perform main installation
perform_main_installation() {
    log_info "$(get_message MSG_INSTALL_START)"
    check_dependencies
    check_permissions
    create_directories
    install_project_preserving_lang
    install_completion
    check_path
    verify_installation
}

# 최종 지침 표시
# Show final instructions
show_final_instructions() {
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
# Message output function (fallback if system doesn't have it)
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

# 설치 모듈
# Installation module
install() {
    echo "$(get_message MSG_INSTALL_START)"
    
    check_docker_status
    check_port_availability
    check_image_existence
    start_container
}

# Docker 상태 체크
# Check Docker status
check_docker_status() {
    if ! docker info > /dev/null 2>&1; then
        echo "$(get_message MSG_INSTALL_CHECK_DOCKER)"
        return 1
    fi
}

# 포트 사용 가능 여부 체크
# Check port availability
check_port_availability() {
    if lsof -i :80 > /dev/null 2>&1 || lsof -i :443 > /dev/null 2>&1; then
        echo "$(get_message MSG_INSTALL_CHECK_PORTS)"
        return 1
    fi
}

# 이미지 존재 여부 체크
# Check image existence
check_image_existence() {
    if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
        echo "$(get_message MSG_INSTALL_CHECK_IMAGE)"
        return 1
    fi
}

# 컨테이너 시작
# Start container
start_container() {
    if docker-compose up -d; then
        echo "$(get_message MSG_INSTALL_COMPLETE)"
        return 0
    else
        echo "$(get_message MSG_INSTALL_FAILED)"
        return 1
    fi
}

# install 함수 내보내기
# Export the install function
export -f install