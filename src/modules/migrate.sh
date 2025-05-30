#!/bin/bash

# Migration module for dockit
# dockit 마이그레이션 모듈

# 스크립트 디렉토리 설정
# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 공통 모듈 로드
# Load common module
source "$SCRIPT_DIR/common.sh" "migrate"

# 로그 출력 함수들은 이제 utils/log.sh에서 제공됨
# These logging functions are now provided by utils/log.sh
# log_info, log_warn, log_error, log_success, log_debug

# 버전 비교 함수
# Compare versions
compare_versions() {
    local current_version="$1"
    local target_version="$2"
    
    # 버전 문자열을 배열로 변환
    # Convert version strings to arrays
    IFS='.' read -ra current_arr <<< "$current_version"
    IFS='.' read -ra target_arr <<< "$target_version"
    
    # 메이저, 마이너, 패치 버전 비교
    # Compare major, minor, patch versions
    for i in {0..2}; do
        local current_num=${current_arr[$i]:-0}
        local target_num=${target_arr[$i]:-0}
        
        if [ "$current_num" -lt "$target_num" ]; then
            # 타겟 버전이 더 높음 (업그레이드 필요)
            # Target version is higher (upgrade needed)
            echo "1"
            return
        elif [ "$current_num" -gt "$target_num" ]; then
            # 현재 버전이 더 높음 (다운그레이드 불가)
            # Current version is higher (downgrade not supported)
            echo "-1"
            return
        fi
    done
    
    # 버전이 동일함
    # Versions are the same
    echo "0"
}

# 마이그레이션 백업 생성
# Create migration backup
create_backup() {
    log_info "$(get_message MSG_MIGRATE_BACKING_UP)"
    
    # 기존 설정 백업
    # Backup existing configuration
    if [ -d "$CONFIG_DIR" ]; then
        # .dockit 디렉토리를 .dockit_old로 백업
        # Backup .dockit directory to .dockit_old
        mv "$CONFIG_DIR" "${CONFIG_DIR}_old"
        
        if [ $? -eq 0 ]; then
            log_info "$(printf "$(get_message MSG_MIGRATE_BACKUP_CREATED)" "${CONFIG_DIR}_old")"
            return 0
        else
            log_error "$(get_message MSG_MIGRATE_BACKUP_FAILED)"
            return 1
        fi
    else
        log_warn "$(get_message MSG_MIGRATE_NO_CONFIG)"
        return 0
    fi
}

# 새 환경 초기화
# Initialize new environment
initialize_new_environment() {
    log_info "$(get_message MSG_MIGRATE_PROCESSING)"
    
    # init 모듈 로드 및 실행
    # Load and execute init module
    if [ -f "$MODULES_DIR/init.sh" ]; then
        source "$MODULES_DIR/init.sh"
        
        # init_module의 특정 함수 호출 또는 별도 처리
        # Call specific function from init module or handle separately
        MIGRATE_MODE=true init_main
        
        if [ $? -eq 0 ]; then
            return 0
        else
            log_error "$(get_message MSG_MIGRATE_INIT_FAILED)"
            return 1
        fi
    else
        log_error "$(get_message MSG_MIGRATE_INIT_NOT_FOUND)"
        return 1
    fi
}

# 마이그레이션 디렉토리 구조 생성
# Create migration directory structure
create_migration_structure() {
    local current_version="$1"
    
    # 마이그레이션 디렉토리 생성
    # Create migrations directory
    local migrations_dir="${CONFIG_DIR}/migrations"
    mkdir -p "$migrations_dir"
    
    if [ -d "${CONFIG_DIR}_old" ]; then
        # 기존 migrations 디렉토리가 있으면 먼저 처리
        # Handle existing migrations directory first if exists
        if [ -d "${CONFIG_DIR}_old/migrations" ]; then
            # 기존 migrations의 내용을 새 migrations로 복사
            # Copy contents of existing migrations to new migrations
            cp -R "${CONFIG_DIR}_old/migrations"/* "$migrations_dir/" 2>/dev/null
            
            # 기존 migrations 디렉토리 삭제 (이중 중첩 방지)
            # Delete existing migrations directory (prevent nesting)
            rm -rf "${CONFIG_DIR}_old/migrations"
        fi
        
        # 이전 설정을 버전 이름의 디렉토리로 이동
        # Move old config to directory named with version
        local version_dir="${migrations_dir}/${current_version}"
        mv "${CONFIG_DIR}_old" "$version_dir"
        
        if [ $? -eq 0 ]; then
            log_info "$(printf "$(get_message MSG_MIGRATE_SAVED_CONFIG)" "$version_dir")"
            return 0
        else
            log_error "$(get_message MSG_MIGRATE_SAVE_FAILED)"
            return 1
        fi
    else
        log_warn "$(get_message MSG_MIGRATE_NO_OLD_CONFIG)"
        return 0
    fi
}

# 설정값 마이그레이션
# Migrate configuration values
# 환경 변수 추출
# Extract environment variables
extract_env_vars() {
    local env_file="$1"
    local var_name="$2"
    grep "^${var_name}=" "$env_file" | cut -d'=' -f2
}

# 환경 변수 업데이트
# Update environment variables
update_env_var() {
    local config_env="$1" 
    local var_name="$2"
    local var_value="$3"
    
    if [ -n "$var_value" ]; then
        sed -i "s/^${var_name}=.*/${var_name}=$var_value/" "$config_env"
    fi
}

# 설정값 마이그레이션
# Migrate configuration values
migrate_settings() {
    local current_version="$1"
    local migrations_dir="${CONFIG_DIR}/migrations"
    local old_env="${migrations_dir}/${current_version}/.env"
    local new_env="${CONFIG_DIR}/.env"
    
    if [ ! -f "$old_env" ]; then
        log_warn "$(get_message MSG_MIGRATE_NO_ENV)"
        return 0
    fi
    
    log_info "$(get_message MSG_MIGRATE_UPDATING_ENV)"
    
    # 환경 변수 추출 및 업데이트
    # Extract and update environment variables
    local workspace=$(extract_env_vars "$old_env" "WORKSPACE")
    local timezone=$(extract_env_vars "$old_env" "TIMEZONE")
    
    update_env_var "$new_env" "WORKSPACE" "$workspace"
    update_env_var "$new_env" "TIMEZONE" "$timezone"
    
    # 기타 필요한 설정 마이그레이션...
    # Migrate other necessary settings...
    
    return 0
}

# 롤백 수행
# Perform rollback
perform_rollback() {
    log_info "$(get_message MSG_MIGRATE_ROLLBACK)"
    
    # 새 설정 제거
    # Remove new configuration
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
    fi
    
    # 백업에서 복원
    # Restore from backup
    if [ -d "${CONFIG_DIR}_old" ]; then
        mv "${CONFIG_DIR}_old" "$CONFIG_DIR"
        
        if [ $? -eq 0 ]; then
            log_info "$(get_message MSG_MIGRATE_ROLLBACK_SUCCESS)"
            return 0
        else
            log_error "$(printf "$(get_message MSG_MIGRATE_ROLLBACK_FAILED)" "${CONFIG_DIR}_old")"
            return 1
        fi
    else
        log_error "$(get_message MSG_MIGRATE_NO_BACKUP)"
        return 1
    fi
}

# 현재 버전 확인
# Check current version
check_current_version() {
    local current_version=""
    
    if [ -f "${CONFIG_DIR}/.env" ]; then
        # 먼저 DOCKIT_VERSION 확인
        current_version=$(grep "^DOCKIT_VERSION=" "${CONFIG_DIR}/.env" | cut -d'"' -f2)
        
        # DOCKIT_VERSION이 없으면 VERSION 확인
        if [ -z "$current_version" ]; then
            current_version=$(grep "^VERSION=" "${CONFIG_DIR}/.env" | cut -d'=' -f2)
        fi
    fi
    
    # 버전 정보가 없으면 마이그레이션 불가
    # Migration not possible without version information
    if [ -z "$current_version" ]; then
        log_error "$(get_message MSG_MIGRATE_NO_CURRENT_VERSION)"
        return 1
    fi
    
    echo "$current_version"
    return 0
}

# 대상 버전 확인
# Check target version
check_target_version() {
    local version_file="$PROJECT_ROOT/bin/VERSION"
    
    if [ ! -f "$version_file" ]; then
        # 설치 경로에서 확인
        version_file="/home/$USER/.dockit/bin/VERSION"
        
        if [ ! -f "$version_file" ]; then
            log_error "$(printf "$(get_message MSG_MIGRATE_NO_VERSION_FILE)" "$version_file")"
            return 1
        fi
    fi
    
    local target_version=$(cat "$version_file")
    
    if [ -z "$target_version" ]; then
        log_error "$(get_message MSG_MIGRATE_EMPTY_VERSION)"
        return 1
    fi
    
    echo "$target_version"
    return 0
}

# 버전 검증
# Validate versions
validate_versions() {
    local current_version="$1"
    local target_version="$2"
    
    log_info "$(printf "$(get_message MSG_MIGRATE_CURRENT_VER)" "$current_version")"
    log_info "$(printf "$(get_message MSG_MIGRATE_TARGET_VER)" "$target_version")"
    
    # 버전 비교 (1: 업그레이드 필요, 0: 동일, -1: 다운그레이드 시도)
    # Compare versions (1: upgrade needed, 0: same, -1: downgrade attempt)
    local comparison=$(compare_versions "$current_version" "$target_version")
    
    if [ "$comparison" = "0" ]; then
        # 버전이 같으면 마이그레이션 필요 없음
        # No migration needed if versions are the same
        echo -e "${GREEN}$(get_message MSG_MIGRATE_UP_TO_DATE)${NC}"
        return 1
    elif [ "$comparison" = "-1" ]; then
        # 다운그레이드는 지원하지 않음
        # Downgrade not supported
        log_error "$(get_message MSG_MIGRATE_DOWNGRADE_NOT_SUPPORTED)"
        return 1
    fi
    
    # 업그레이드 필요
    # Upgrade needed
    return 0
}

# 사용자 확인 획득
# Get user confirmation
get_user_confirmation() {
    local current_version="$1"
    local target_version="$2"
    
    echo ""
    echo -e "$(printf "$(get_message MSG_MIGRATE_CONFIRM)" "$current_version" "$target_version")"
    read -p "[y/N] " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "$(get_message MSG_MIGRATE_CANCELLED)"
        return 1
    fi
    
    return 0
}

# 마이그레이션 프로세스 실행
# Execute migration process
# 백업 및 초기화 단계 실행
# Execute backup and initialization steps
execute_backup_and_init() {
    # 1. 백업 생성
    # 1. Create backup
    if ! create_backup; then
        return 1
    fi

    # 2. 새 환경 초기화
    # 2. Initialize new environment 
    if ! initialize_new_environment; then
        return 1
    fi

    return 0
}

# 마이그레이션 구조 및 설정 단계 실행
# Execute migration structure and settings steps
execute_migration_steps() {
    local current_version="$1"
    local target_version="$2"

    log_info "$(printf "$(get_message MSG_MIGRATE_EXECUTING_STEPS)" "$current_version" "$target_version")"

    # 3. 마이그레이션 디렉토리 구조 생성
    # 3. Create migration directory structure
    if ! create_migration_structure "$current_version"; then
        log_error "$(get_message MSG_MIGRATE_DIR_STRUCTURE_FAILED)"
        return 1
    fi

    # 4. 설정값 마이그레이션
    # 4. Migrate settings
    if ! migrate_settings "$current_version"; then
        log_error "$(get_message MSG_MIGRATE_SETTINGS_FAILED)"
        return 1
    fi
    
    # 5. 버전별 특수 마이그레이션 로직 실행
    # 5. Execute version-specific migration logic
    execute_version_specific_migration "$current_version" "$target_version"

    log_info "$(get_message MSG_MIGRATE_STEPS_COMPLETED)"
    return 0
}

# 버전별 마이그레이션 로직 실행
# Execute version-specific migration logic
execute_version_specific_migration() {
    local current_version="$1"
    local target_version="$2"
    
    log_info "$(get_message MSG_MIGRATE_LOGIC_COMPLETED)"
    return 0
}

# 마이그레이션 프로세스 실행
# Execute migration process
execute_migration_process() {
    local current_version="$1"
    local target_version="$2"
    
    log_info "$(printf "$(get_message MSG_MIGRATE_PROCESS_STARTED)" "$current_version" "$target_version")"
    
    # 백업 및 초기화 실행
    if ! execute_backup_and_init; then
        log_error "$(get_message MSG_MIGRATE_BACKUP_INIT_FAILED)"
        perform_rollback
        return 1
    fi

    # 마이그레이션 단계 실행
    if ! execute_migration_steps "$current_version" "$target_version"; then
        log_error "$(get_message MSG_MIGRATE_STEPS_FAILED)"
        perform_rollback
        return 1
    fi

    log_info "$(get_message MSG_MIGRATE_PROCESS_COMPLETED)"
    return 0
}

# 마이그레이션 메인 함수
# Migration main function
migrate_main() {
    # 시작 메시지 출력
    # Display start message
    log_info "$(get_message MSG_MIGRATE_START)"
    
    # 버전 정보 확인
    # Check version information
    log_info "$(get_message MSG_MIGRATE_CHECKING)"
    
    # 현재 버전 확인
    # Check current version
    local current_version=""
    current_version=$(check_current_version)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # 대상 버전 확인
    # Check target version
    local target_version=""
    target_version=$(check_target_version)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # 버전 검증
    # Validate versions
    if ! validate_versions "$current_version" "$target_version"; then
        return 0
    fi
    
    # 사용자 확인
    # User confirmation
    if ! get_user_confirmation "$current_version" "$target_version"; then
        return 0
    fi
    
    # 마이그레이션 프로세스 실행
    # Execute migration process
    if execute_migration_process "$current_version" "$target_version"; then
        log_info "$(printf "$(get_message MSG_MIGRATE_SUCCESS)" "$target_version")"
    else
        log_error "$(printf "$(get_message MSG_MIGRATE_FAILED)" "Migration process failed")"
        return 1
    fi
    
    return 0
}

# 스크립트가 직접 실행될 때만 메인 함수 실행
# Run main function only when script is directly executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    migrate_main "$@"
fi 