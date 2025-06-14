#!/bin/bash

# ===== 기본 설정 변수 =====
# ===== Basic Configuration Variables =====

# 색상 정의 로드
# Load color definitions
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/src/utils/colors.sh"

# 설치 디렉토리
# Installation directories
PROJECT_DIR="$HOME/.dockit"
INSTALL_DIR="$HOME/.dockit/bin"
COMPLETION_DIR="$HOME/.dockit/completion/bash"
ZSH_COMPLETION_DIR="$HOME/.dockit/completion/zsh"
CONFIG_DIR="$HOME/.dockit/config"
GLOBAL_CONFIG_DIR="/etc/dockit"
UTILS_DIR="${PROJECT_ROOT}/src/utils"

# 언어 관련 변수 초기화
# Initialize language-related variables
LANGUAGE="en"

# 유틸리티 모듈 로드 (가능한 경우)
# Load utility modules if available
source "${UTILS_DIR}/utils.sh"


# ===== 레벨 1: 기본 유틸리티 함수 =====
# ===== Level 1: Basic Utility Functions =====

# 메시지 출력 함수
# Message output function
get_message() {
    local message_key="$1"
    if [ -n "${!message_key}" ]; then
        echo "${!message_key}"
    else
        echo "$message_key"
    fi
}

# 파일 존재 확인 함수
# Check if file exists
check_file_exists() {
    [ -f "$1" ]
}

# 디렉토리 존재 확인 함수
# Check if directory exists
check_dir_exists() {
    [ -d "$1" ]
}

# 명령어 존재 확인 함수
# Check if command exists
check_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 디렉토리 생성 함수
# Create directory if it doesn't exist
create_dir_if_not_exists() {
    [ -d "$1" ] || mkdir -p "$1"
}

# 권한 확인 함수
# Check write permission
check_write_permission() {
    [ -w "$1" ]
}

# ===== 레벨 2: 설정 및 환경 관련 함수 =====
# ===== Level 2: Configuration and Environment Functions =====
# 언어 설정 불러오기
# Load language settings
load_language_setting() {
    local settings_file="$HOME/.dockit/config/settings.env"
    
    export LANGUAGE="en"
    
    if check_file_exists "$settings_file"; then
        source "$settings_file"
    fi
}

# 메시지 시스템 로드
# Load message system
load_message_system() {
    if check_file_exists "$PROJECT_ROOT/config/messages/load.sh"; then
        source "$PROJECT_ROOT/config/messages/load.sh"
        load_messages
    fi
    
    if check_file_exists "$PROJECT_ROOT/config/system.sh"; then
        source "$PROJECT_ROOT/config/system.sh"
    fi
}

# 언어 설정 백업
# Backup language settings
backup_language_settings() {
    if check_file_exists "$PROJECT_DIR/config/settings.env"; then
        lang_settings=$(grep "LANGUAGE=" "$PROJECT_DIR/config/settings.env")
    fi
}

# 메시지 백업
# Backup messages
backup_messages() {
    local temp_dir="/tmp/dockit_messages_backup"
    if check_dir_exists "$PROJECT_DIR/config/messages"; then
        create_dir_if_not_exists "$temp_dir"
        cp -r "$PROJECT_DIR/config/messages/"* "$temp_dir/"
    fi
}

# 언어 설정 복원
# Restore language settings
restore_language_settings() {
    if [ -n "$lang_settings" ]; then
        create_dir_if_not_exists "$PROJECT_DIR/config"
        
        if ! check_file_exists "$PROJECT_DIR/config/settings.env"; then
            echo "LANGUAGE=\"en\"" > "$PROJECT_DIR/config/settings.env"
        fi
        
        sed -i "s/LANGUAGE=.*/$lang_settings/" "$PROJECT_DIR/config/settings.env"
    fi
}

# 메시지 복원
# Restore messages
restore_messages() {
    local temp_dir="/tmp/dockit_messages_backup"
    if check_dir_exists "$temp_dir" && [ "$(ls -A "$temp_dir")" ]; then
        cp -r "$temp_dir/"* "$PROJECT_DIR/config/messages/"
        rm -rf "$temp_dir"
    fi
}

# 언어 파일 복사 (실제 설치 단계에서만 호출)
# Copy language files (call only during actual installation)
copy_language_files() {
    create_dir_if_not_exists "$PROJECT_DIR/config/messages"
    
    # settings.env 파일 복사
    cp "$PROJECT_ROOT/config/settings.env" "$PROJECT_DIR/config/"
    log_info "$(get_message MSG_INSTALL_SETTINGS_COPIED)"
    
    # Copy defaults.sh if it exists
    if check_file_exists "$PROJECT_ROOT/config/defaults.sh"; then
        cp "$PROJECT_ROOT/config/defaults.sh" "$PROJECT_DIR/config/"
        log_info "$(get_message MSG_INSTALL_DEFAULTS_COPIED)"
    fi
    
    if check_dir_exists "$PROJECT_ROOT/config/messages"; then
        cp -r "$PROJECT_ROOT/config/messages/"* "$PROJECT_DIR/config/messages/"
        log_info "$(get_message MSG_INSTALL_MESSAGES_COPIED)"
    else
        log_warn "$(printf "$(get_message MSG_INSTALL_MESSAGES_DIR_NOT_FOUND)" "$PROJECT_ROOT/config/messages")"
    fi
}

# ===== 레벨 3: 의존성 및 환경 검사 함수 =====
# ===== Level 3: Dependency and Environment Check Functions =====
# Docker 의존성 체크
# Check Docker dependency
check_docker_dependency() {
    if ! check_command_exists "docker"; then
        log_error "$(get_message MSG_INSTALL_DOCKER_MISSING)"
        exit 1
    fi
}

# Docker Compose 의존성 체크
# Check Docker Compose dependency
check_compose_dependency() {
    if ! check_command_exists "docker-compose" && ! docker compose version >/dev/null 2>&1; then
        log_error "$(get_message MSG_INSTALL_COMPOSE_MISSING)"
        exit 1
    fi
}

# 기본 도구 체크
# Check basic tools
check_basic_tools() {
    local required_tools=("docker" "git" "curl" "sed" "grep" "jq")
    for tool in "${required_tools[@]}"; do
        if ! check_command_exists "$tool"; then
            log_error "$(printf "$(get_message MSG_INSTALL_TOOL_MISSING)" "$tool" "$tool")"
            exit 1
        fi
    done
}

# 기존 명령어 확인
# Check existing command
check_existing_command() {
    if check_command_exists "dockit"; then
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
    if check_dir_exists "$PROJECT_DIR"; then
        log_warn "$(printf "$(get_message MSG_INSTALL_DIR_EXISTS)" "$PROJECT_DIR")"
        read -p "$(get_message MSG_INSTALL_OVERWRITE) " overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            log_info "$(get_message MSG_INSTALL_CANCELLED)"
            exit 0
        fi
    fi
}

# 디렉토리 권한 체크
# Check directory permissions
check_directory_permissions() {
    if ! check_write_permission "$HOME"; then
        log_error "$(printf "$(get_message MSG_INSTALL_NO_PERMISSION)" "$HOME")"
        log_info "$(get_message MSG_INSTALL_USE_SUDO)"
        exit 1
    fi
}

# 최소 요구사항 체크
# Check minimal requirements
check_minimal_requirements() {
    if ! check_command_exists "docker"; then
        log_error "$(get_message MSG_INSTALL_DOCKER_NOT_INSTALLED)"
        exit 1
    fi
    
    if ! check_write_permission "$HOME"; then
        log_error "$(get_message MSG_INSTALL_PERMISSION_DENIED)"
        log_info "$(get_message MSG_INSTALL_RUN_WITH_SUDO)"
        exit 1
    fi
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
# Check if image exists
check_image_existence() {
    if ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
        echo "$(get_message MSG_INSTALL_CHECK_IMAGE)"
        return 1
    fi
}

# ===== 레벨 4: 설치 단계별 작업 함수 =====
# ===== Level 4: Installation Step Functions =====
# 스크립트 경로 업데이트
# Update script paths
update_script_paths() {
    sed -i "s|SCRIPT_DIR=.*|SCRIPT_DIR=\"$PROJECT_DIR\"|" "$INSTALL_DIR/dockit"
    sed -i "s|MODULES_DIR=.*|MODULES_DIR=\"$PROJECT_DIR/src/modules\"|" "$INSTALL_DIR/dockit"
    sed -i "s|CONFIG_DIR=.*|CONFIG_DIR=\"$PROJECT_DIR/config\"|" "$INSTALL_DIR/dockit"
}

# Dockit 스크립트 설치
# Install Dockit script
install_dockit_script() {
    create_dir_if_not_exists "$INSTALL_DIR"
    
    cp "$PROJECT_ROOT/bin/dockit.sh" "$INSTALL_DIR/dockit"
    chmod +x "$INSTALL_DIR/dockit"
    
    update_script_paths
    
    if check_file_exists "$INSTALL_DIR/dockit" && [ -x "$INSTALL_DIR/dockit" ]; then
        log_info "$(printf "$(get_message MSG_INSTALL_SCRIPT_SUCCESS)" "$INSTALL_DIR/dockit")"
    else
        log_error "$(get_message MSG_INSTALL_SCRIPT_FAILED)"
        return 1
    fi
}

# 기존 설치 제거
# Remove old installation
remove_old_installation() {
    if check_dir_exists "$PROJECT_DIR"; then
        rm -rf "$PROJECT_DIR"
    fi
    create_dir_if_not_exists "$PROJECT_DIR"
}

# 프로젝트 파일 복사
# Copy project files
copy_project_files() {
    create_dir_if_not_exists "$PROJECT_DIR/src/completion"
    create_dir_if_not_exists "$PROJECT_DIR/bin"
    create_dir_if_not_exists "$PROJECT_DIR/config/messages"
    
    cp -r "$PROJECT_ROOT/src/"* "$PROJECT_DIR/src/"
    
    cp "$PROJECT_ROOT/bin/VERSION" "$PROJECT_DIR/bin/"
    
    install_dockit_script
}

# 성공 메시지 표시
# Show success message
show_success_message() {
    log_info "$(get_message MSG_INSTALL_COMPLETED)"
    log_info "$(get_message MSG_INSTALL_CMD_AVAILABLE)"
    log_info "$(get_message MSG_INSTALL_HELP_TIP)"
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

# 자동완성 디렉토리 생성
# Create completion directories
create_completion_directories() {
    create_dir_if_not_exists "$COMPLETION_DIR"
    create_dir_if_not_exists "$ZSH_COMPLETION_DIR"
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
    cp "$PROJECT_DIR/src/completion/bash.sh" "$COMPLETION_DIR/dockit"
    chmod +x "$COMPLETION_DIR/dockit"
    
    cp "$PROJECT_DIR/src/completion/zsh.sh" "$ZSH_COMPLETION_DIR/_dockit"
    chmod +x "$ZSH_COMPLETION_DIR/_dockit"
}

# 시스템 자동완성 설치
# Install system completion
install_system_completion() {
    if check_dir_exists "/etc/bash_completion.d" && check_write_permission "/etc/bash_completion.d"; then
        cp "$PROJECT_DIR/src/completion/completion-common.sh" "/etc/bash_completion.d/"
        chmod +x "/etc/bash_completion.d/completion-common.sh"
        
        cp "$PROJECT_DIR/src/completion/bash.sh" "/etc/bash_completion.d/dockit"
        chmod +x "/etc/bash_completion.d/dockit"
        log_info "$(get_message MSG_INSTALL_GLOBAL_COMPLETION)"
    fi
}

# Bash 자동완성 설정
# Configure Bash completion
configure_bash_completion() {
    if check_file_exists "$HOME/.bashrc"; then
        if ! grep -q "source $COMPLETION_DIR/dockit" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Dockit completion" >> "$HOME/.bashrc"
            echo "[ -f $COMPLETION_DIR/dockit ] && source $COMPLETION_DIR/dockit" >> "$HOME/.bashrc"
        fi
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

# Zsh 자동완성 설정
# Configure Zsh completion
configure_zsh_completion() {
    if check_file_exists "$HOME/.zshrc"; then
        configure_zsh_completion_system
        configure_zsh_completion_path
        configure_zsh_completion_source
        
        log_info "$(get_message MSG_INSTALL_ZSH_COMPLETION_ADDED)"
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

# PATH 확인 및 업데이트
# Check and update PATH
check_and_update_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        log_warn "$(get_message MSG_INSTALL_ADDING_PATH)"
    fi
    
    if check_file_exists "$HOME/.bashrc"; then
        sed -i '/export PATH=".*\.local\/bin/d' "$HOME/.bashrc"
        sed -i '/export PATH=".*\.dockit\/bin/d' "$HOME/.bashrc"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc"
    fi
    
    if check_file_exists "$HOME/.zshrc"; then
        sed -i '/export PATH=".*\.local\/bin/d' "$HOME/.zshrc"
        sed -i '/export PATH=".*\.dockit\/bin/d' "$HOME/.zshrc"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.zshrc"
    fi
    
    log_info "$(get_message MSG_INSTALL_PATH_UPDATED)"
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
    echo ""
    log_info "$(get_message MSG_INSTALL_DIRECT_PATH)"
    echo "        $INSTALL_DIR/dockit"
}

# 설치 모듈 (다른 스크립트에서 사용할 수 있게 내보내기 위한 함수)
# Installation module (exported for use in other scripts)
install() {
    echo "$(get_message MSG_INSTALL_START)"
    
    check_docker_status
    check_port_availability
    check_image_existence
    start_container
}

# ===== 스크립트 실행 시작 =====
# ===== Script Execution Start =====
# 언어 설정 로드
# Load language settings
load_language_setting

# 메시지 시스템 로드
# Load message system
load_message_system

# 메인 함수 정의는 여기 있고, 호출은 아래에서 할 것임
# Main function is defined here, and will be called below

# 함수 내보내기 (다른 스크립트에서 사용 가능하도록)
# Export functions (for use in other scripts)
export -f install

# ===== 레벨 5: 중간 레벨 통합 함수 =====
# ===== Level 5: Mid-level Integration Functions =====
# 의존성 체크
# Check dependencies
check_dependencies() {
    log_info "$(get_message MSG_INSTALL_CHECKING_DEPENDENCIES)"
    
    check_docker_dependency
    check_compose_dependency
    check_basic_tools
    
    log_info "$(get_message MSG_INSTALL_DEPENDENCIES_OK)"
}

# 기존 설치 확인
# Check existing installation
check_existing_installation() {
    log_info "$(get_message MSG_INSTALL_CHECKING_EXISTING)"
    
    check_existing_command
    check_existing_directory
}

# 권한 체크
# Check permissions
check_permissions() {
    log_info "$(get_message MSG_INSTALL_CHECKING_PERMISSIONS)"
    
    check_directory_permissions
}

# 쉘 자동완성 설정
# Configure shell completion
configure_shell_completion() {
    configure_bash_completion
    configure_zsh_completion
}

# PATH 설정 확인
# Check PATH setting
check_path() {
    check_and_update_path
}

# 설치 확인
# Verify installation
verify_installation() {
    if check_file_exists "$INSTALL_DIR/dockit" && [ -x "$INSTALL_DIR/dockit" ]; then
        show_success_message
    else
        log_error "$(get_message MSG_INSTALL_FAILED)"
        log_error "$(printf "$(get_message MSG_INSTALL_SCRIPT_NOT_FOUND)" "$INSTALL_DIR/dockit")"
        exit 1
    fi
}

# 언어 설정
# Setup language
setup_language() {
    local lang_dir="$PROJECT_ROOT/config/messages"
    local default_lang="en"
    
    find_available_languages_from_source
    display_language_options
    handle_language_selection
}

# 설치 초기화
# Initialize installation
initialize_installation() {
    log_info "$(get_message MSG_INSTALL_INITIALIZING)"
    check_minimal_requirements
}

# 원본 소스에서 사용 가능한 언어 찾기 (파일 시스템 변경 없음)
# Find available languages from source (no filesystem changes)
find_available_languages_from_source() {
    langs=()
    lang_names=()
    default_idx=0
    i=0
    
    log_info "$(get_message MSG_INSTALL_FINDING_LANGUAGES)"
    for lang_file in "$PROJECT_ROOT/config/messages"/*.sh; do
        if check_file_exists "$lang_file"; then
            process_language_file "$lang_file"
        fi
    done
    
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
    
    prepare_language_settings
}

# 선택된 언어 설정 (메모리에만 저장)
# Set selected language (in memory only)
set_selected_language() {
    local idx=$((lang_choice-1))
    selected_lang="${langs[$idx]}"
    selected_name="${lang_names[$idx]}"
    
    LANGUAGE="$selected_lang"
    load_source_language_file "$selected_lang"
    printf "$(get_message MSG_INSTALL_LANGUAGE_SELECTED)\n" "$selected_name" "$selected_lang"
}

# 기본 언어 설정 (메모리에만 저장)
# Set default language (in memory only)
set_default_language() {
    local default_lang="${langs[$default_idx]}"
    local default_name="${lang_names[$default_idx]}"
    
    selected_lang="$default_lang"
    selected_name="$default_name"
    
    LANGUAGE="$default_lang"
    load_source_language_file "$default_lang"
    printf "$(get_message MSG_INSTALL_LANGUAGE_INVALID)\n" "$default_name" "$default_lang"
}

# 원본 소스에서 언어 파일 로드 (파일 시스템 변경 없음)
# Load language file from source (no filesystem changes)
load_source_language_file() {
    local lang="$1"
    if check_file_exists "$PROJECT_ROOT/config/messages/$lang.sh"; then
        source "$PROJECT_ROOT/config/messages/$lang.sh"
    fi
}

# 언어 설정을 위한 준비 (메모리에만 저장)
# Prepare language settings (in memory only)
prepare_language_settings() {
    local selected_lang="$LANGUAGE"
    local lang_file="$PROJECT_ROOT/config/messages/$selected_lang.sh"
    
    if check_file_exists "$lang_file"; then
        prepare_locale_setting "$lang_file"
        prepare_timezone_setting "$lang_file"
        prepare_base_image_setting "$selected_lang"
        prepare_password_workdir_setting
    fi
}

# 로케일 설정 준비 (메모리에만 저장)
# Prepare locale setting (in memory only)
prepare_locale_setting() {
    local lang_file="$1"
    locale=$(grep "^LANG_LOCALE=" "$lang_file" | cut -d'"' -f2)
    
    if [ -n "$locale" ]; then
        export LOCALE="$locale"
        log_info "$(printf "$(get_message MSG_INSTALL_LOCALE_SET)" "$locale")"
    fi
}

# 타임존 설정 준비 (메모리에만 저장)
# Prepare timezone setting (in memory only)
prepare_timezone_setting() {
    local lang_file="$1"
    timezone=$(grep "^LANG_TIMEZONE=" "$lang_file" | cut -d'"' -f2)
    
    if [ -n "$timezone" ]; then
        export TIMEZONE="$timezone" 
        log_info "$(printf "$(get_message MSG_INSTALL_TIMEZONE_SET)" "$timezone")"
    fi
}

# 베이스 이미지 설정 준비 (메모리에만 저장)
# Prepare base image setting (in memory only)
prepare_base_image_setting() {
    local selected_lang="$1"
    
    # defaults.sh에서 언어별 기본 이미지 가져오기
    source "$PROJECT_ROOT/config/defaults.sh"
    
    # 지원하지 않는 언어인 경우 en(영어)을 기본값으로 사용
    if [[ -z "${DEFAULT_IMAGES[$selected_lang]}" ]]; then
        selected_lang="en"
    fi
    
    base_image="${DEFAULT_IMAGES[$selected_lang]}"
    
    if [ -n "$base_image" ]; then
        export BASE_IMAGE="$base_image"
        log_info "$(printf "$(get_message MSG_INSTALL_BASE_IMAGE_SET)" "$base_image")"
    fi
}

# 비밀번호와 작업 디렉토리 설정 준비 (메모리에만 저장)
# Prepare password and workdir setting (in memory only)
prepare_password_workdir_setting() {
    # defaults.sh에서 기본 비밀번호와 작업 디렉토리 가져오기
    source "$PROJECT_ROOT/config/defaults.sh"
    
    password="$DEFAULT_PASSWORD"
    workdir="$DEFAULT_WORKDIR"
    
    if [ -n "$password" ]; then
        export PASSWORD="$password"
        log_info "$(printf "$(get_message MSG_INSTALL_PASSWORD_SET)" "$password")"
    fi
    
    if [ -n "$workdir" ]; then
        export WORKDIR="$workdir"
        log_info "$(printf "$(get_message MSG_INSTALL_WORKDIR_SET)" "$workdir")"
    fi
}

# 언어 설정 적용 (실제 설치 단계에서만 호출)
# Apply language settings (call only during actual installation)
apply_language_settings() {
    if [ -n "$selected_lang" ]; then
        # timezone이 비어있으면 다시 설정
        if [ -z "$timezone" ]; then
            local lang_file="$PROJECT_ROOT/config/messages/$selected_lang.sh"
            if [ -f "$lang_file" ]; then
                timezone=$(grep "^LANG_TIMEZONE=" "$lang_file" | cut -d'"' -f2)
            fi
        fi
        
        # base_image가 비어있으면 다시 설정
        if [ -z "$base_image" ]; then
            source "$PROJECT_ROOT/config/defaults.sh"
            local lang_for_image="$selected_lang"
            if [[ -z "${DEFAULT_IMAGES[$selected_lang]}" ]]; then
                lang_for_image="en"
            fi
            base_image="${DEFAULT_IMAGES[$lang_for_image]}"
        fi
        
        # 기존 settings.env 파일을 임시 파일로 복사
        cp "$PROJECT_DIR/config/settings.env" "$PROJECT_DIR/config/settings.env.tmp"
        
        # 언어 관련 설정만 업데이트 (구분자를 |로 변경)
        sed -i "s|^LANGUAGE=.*|LANGUAGE=\"$selected_lang\"|" "$PROJECT_DIR/config/settings.env.tmp"
        sed -i "s|^LOCALE=.*|LOCALE=\"$locale\"|" "$PROJECT_DIR/config/settings.env.tmp"
        sed -i "s|^TIMEZONE=.*|TIMEZONE=\"$timezone\"|" "$PROJECT_DIR/config/settings.env.tmp"
        sed -i "s|^BASE_IMAGE=.*|BASE_IMAGE=\"$base_image\"|" "$PROJECT_DIR/config/settings.env.tmp"
        sed -i "s|^PASSWORD=.*|PASSWORD=\"$password\"|" "$PROJECT_DIR/config/settings.env.tmp"
        sed -i "s|^WORKDIR=.*|WORKDIR=\"$workdir\"|" "$PROJECT_DIR/config/settings.env.tmp"
        
        # 임시 파일을 원래 파일로 이동
        mv "$PROJECT_DIR/config/settings.env.tmp" "$PROJECT_DIR/config/settings.env"
    fi
}

# 초기 체크 수행 (파일 시스템 변경 없음)
# Perform initial checks (no filesystem changes)
perform_initial_checks() {
    check_existing_installation
}

# 최종 설치 확인 요청
# Ask for final installation confirmation
confirm_installation() {
    echo ""
    log_info "$(get_message MSG_INSTALL_CONFIRM_PROCEED)"
    read -r confirmation
    
    # 빈 입력이거나 'Y' 또는 'y'면 계속 진행
    # Continue if input is empty or 'Y' or 'y'
    if [[ ! $confirmation =~ ^[Nn]$ ]]; then
        return 0
    else
        log_info "$(get_message MSG_INSTALL_CANCELLED)"
        exit 0
    fi
}

# ===== 레벨 6: 프로젝트 설치 함수 =====
# ===== Level 6: Project Installation Functions =====
# 프로젝트 파일 설치 (언어 설정 보존)
# Install project files (preserving language settings)
install_project_preserving_lang() {
    log_info "$(get_message MSG_INSTALL_INSTALLING_FILES)"
    
    if check_dir_exists "$PROJECT_DIR"; then
        backup_language_settings
        backup_messages
    fi
    
    remove_old_installation || {
        log_error "$(get_message MSG_INSTALL_REMOVE_FAILED)"
        return 1
    }
    
    # 언어 파일을 먼저 복사하여 메시지가 제대로 표시되도록 함
    # Copy language files first so messages display correctly
    copy_language_files
    
    copy_project_files || {
        log_error "$(get_message MSG_INSTALL_COPY_FAILED)"
        return 1
    }
    
    if [ -n "$lang_settings" ]; then
        restore_language_settings
    fi
    
    local temp_dir="/tmp/dockit_messages_backup"
    if check_dir_exists "$temp_dir" && [ "$(ls -A "$temp_dir")" ]; then
        restore_messages
    fi
    
    log_info "$(printf "$(get_message MSG_INSTALL_PATH)" "$PROJECT_DIR")"
    return 0
}

# 초기 체크 수행 (파일 시스템 변경 없음)
# Perform initial checks (no filesystem changes)
perform_initial_checks() {
    check_existing_installation
}

# 최종 설치 확인 요청
# Ask for final installation confirmation
confirm_installation() {
    echo ""
    log_info "$(get_message MSG_INSTALL_CONFIRM_PROCEED)"
    read -r confirmation
    
    # 빈 입력이거나 'Y' 또는 'y'면 계속 진행
    # Continue if input is empty or 'Y' or 'y'
    if [[ ! $confirmation =~ ^[Nn]$ ]]; then
        return 0
    else
        log_info "$(get_message MSG_INSTALL_CANCELLED)"
        exit 0
    fi
}

# ===== 레벨 7: 메인 설치 프로세스 =====
# ===== Level 7: Main Installation Process =====
# 메인 설치 프로세스
# Main installation process
main() {
    initialize_installation
    perform_initial_checks
    check_dependencies
    check_permissions
    setup_language
    
    # 최종 확인 후에만 파일 시스템 변경
    # Only change filesystem after final confirmation
    confirm_installation
    
    # 여기서부터 실제 파일 시스템 변경 시작
    # Actual filesystem changes start here
    install_project_preserving_lang || return 1
    apply_language_settings
    install_completion || return 1
    check_path || return 1
    verify_installation
    show_final_instructions
}

# 이제 모든 함수가 정의된 후에 메인 함수 실행
# Now execute the main function after all functions are defined
main