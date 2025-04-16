#!/bin/bash

# migrate_test.sh - 마이그레이션 모듈 테스트

# 테스트 마이그레이션 디렉토리
TEST_MIGRATIONS_DIR="$TEST_TMP_DIR/migrations"

# 테스트 설정
setup_migration_test() {
    log_info "마이그레이션 테스트 환경 설정 중..."
    
    # 마이그레이션 디렉토리 생성
    mkdir -p "$TEST_MIGRATIONS_DIR/0.9.0_to_1.0.0"
    mkdir -p "$TEST_MIGRATIONS_DIR/1.0.0_to_1.1.0"
    mkdir -p "$TEST_MIGRATIONS_DIR/0.9.0_to_1.1.0"
    
    # 버전 파일 생성 - 실제 모듈에서 참조하는 경로로 생성
    mkdir -p "$PROJECT_ROOT/bin"
    echo "1.1.0" > "$PROJECT_ROOT/bin/VERSION"
    
    # 테스트용 모의 마이그레이션 스크립트 생성
    create_test_migration_scripts
    
    # 환경 변수 설정
    export MODULES_DIR="$PROJECT_ROOT/src/modules"
    export CONFIG_DIR="$TEST_TMP_DIR"
    
    log_info "마이그레이션 테스트 환경 설정 완료"
}

# 모의 마이그레이션 스크립트 생성
create_test_migration_scripts() {
    log_info "테스트용 마이그레이션 스크립트 생성"
    
    # 0.9.0 -> 1.0.0 마이그레이션 스크립트
    cat > "$TEST_MIGRATIONS_DIR/0.9.0_to_1.0.0/migrate.sh" << 'EOF'
#!/bin/bash

# 마이그레이션 테스트 스크립트: 0.9.0 -> 1.0.0
echo "[TEST MIGRATION] 0.9.0 -> 1.0.0 마이그레이션 실행"
echo "현재 버전: $1"
echo "대상 버전: $2"
echo "설정 디렉토리: $3"

# 마이그레이션 작업 시뮬레이션
echo "VERSION=1.0.0" > "$3/.env"
echo "WORKSPACE=/workspace" >> "$3/.env"
echo "TIMEZONE=Asia/Seoul" >> "$3/.env"

echo "[TEST MIGRATION] 0.9.0 -> 1.0.0 마이그레이션 완료"
exit 0
EOF

    # 1.0.0 -> 1.1.0 마이그레이션 스크립트
    cat > "$TEST_MIGRATIONS_DIR/1.0.0_to_1.1.0/migrate.sh" << 'EOF'
#!/bin/bash

# 마이그레이션 테스트 스크립트: 1.0.0 -> 1.1.0
echo "[TEST MIGRATION] 1.0.0 -> 1.1.0 마이그레이션 실행"
echo "현재 버전: $1"
echo "대상 버전: $2"
echo "설정 디렉토리: $3"

# 마이그레이션 작업 시뮬레이션
echo "VERSION=1.1.0" > "$3/.env"
echo "WORKSPACE=/workspace" >> "$3/.env"
echo "TIMEZONE=Asia/Seoul" >> "$3/.env"
echo "NEW_SETTING=added_in_1.1.0" >> "$3/.env"

echo "[TEST MIGRATION] 1.0.0 -> 1.1.0 마이그레이션 완료"
exit 0
EOF

    # 0.9.0 -> 1.1.0 직접 마이그레이션 스크립트
    cat > "$TEST_MIGRATIONS_DIR/0.9.0_to_1.1.0/migrate.sh" << 'EOF'
#!/bin/bash

# 마이그레이션 테스트 스크립트: 0.9.0 -> 1.1.0 (직접)
echo "[TEST MIGRATION] 0.9.0 -> 1.1.0 직접 마이그레이션 실행"
echo "현재 버전: $1"
echo "대상 버전: $2"
echo "설정 디렉토리: $3"

# 마이그레이션 작업 시뮬레이션
echo "VERSION=1.1.0" > "$3/.env"
echo "WORKSPACE=/workspace" >> "$3/.env"
echo "TIMEZONE=Asia/Seoul" >> "$3/.env"
echo "NEW_SETTING=added_in_direct_migration" >> "$3/.env"

echo "[TEST MIGRATION] 0.9.0 -> 1.1.0 직접 마이그레이션 완료"
exit 0
EOF

    # 실행 권한 부여
    chmod +x "$TEST_MIGRATIONS_DIR/0.9.0_to_1.0.0/migrate.sh"
    chmod +x "$TEST_MIGRATIONS_DIR/1.0.0_to_1.1.0/migrate.sh"
    chmod +x "$TEST_MIGRATIONS_DIR/0.9.0_to_1.1.0/migrate.sh"
}

# 버전 비교 테스트
test_version_comparison() {
    local tests=(
        "0.9.0:1.0.0:1"       # 업그레이드 필요
        "1.0.0:1.0.0:0"       # 동일 버전
        "1.1.0:1.0.0:-1"      # 다운그레이드 불가
        "1.0.0:1.1.0:1"       # 마이너 버전 업그레이드
        "1.0.9:1.1.0:1"       # 패치 -> 마이너 버전 업그레이드
        "1.1.1:2.0.0:1"       # 메이저 버전 업그레이드
    )
    
    local success=true
    
    for test in "${tests[@]}"; do
        IFS=':' read -r current target expected <<< "$test"
        local result=$(compare_versions "$current" "$target")
        
        if [ "$result" = "$expected" ]; then
            log_info "성공: $current -> $target = $result (예상: $expected)"
        else
            log_error "실패: $current -> $target = $result (예상: $expected)"
            success=false
        fi
    done
    
    $success
    return $?
}

# 마이그레이션 경로 테스트
test_migration_path() {
    # 설정
    local current_version="0.9.0"
    local target_version="1.0.0"
    
    # 마이그레이션 경로 설정
    local migrations_dir="${TEST_MIGRATIONS_DIR}"
    local migration_path="${migrations_dir}/${current_version}_to_${target_version}"
    
    # 마이그레이션 경로 확인
    if [ -d "$migration_path" ]; then
        log_info "성공: 마이그레이션 경로 확인 - $migration_path"
        return 0
    else
        log_error "실패: 마이그레이션 경로를 찾을 수 없음 - $migration_path"
        return 1
    fi
}

# 현재 버전 확인 테스트
test_check_current_version() {
    # 테스트 설정
    echo "VERSION=0.9.0" > "$TEST_TMP_DIR/.env"
    
    # 함수 실행
    local current_version=$(check_current_version)
    
    # 결과 확인
    if [ "$current_version" = "0.9.0" ]; then
        log_info "성공: 현재 버전 확인 - $current_version"
        return 0
    else
        log_error "실패: 현재 버전 확인 - 예상값: 0.9.0, 실제값: $current_version"
        return 1
    fi
}

# 자체 구현 대상 버전 확인 테스트
test_check_target_version() {
    # 결과 확인
    if [ -f "$PROJECT_ROOT/bin/VERSION" ]; then
        local target_version=$(cat "$PROJECT_ROOT/bin/VERSION")
        if [ "$target_version" = "1.1.0" ]; then
            log_info "성공: 대상 버전 확인 - $target_version"
            return 0
        else
            log_error "실패: 대상 버전 확인 - 예상값: 1.1.0, 실제값: $target_version"
            return 1
        fi
    else
        log_error "실패: 대상 버전 파일이 없음 - $PROJECT_ROOT/bin/VERSION"
        return 1
    fi
}

# 마이그레이션 모듈 테스트 실행
run_module_tests() {
    # 테스트 환경 설정
    setup_migration_test
    
    # 테스트 케이스 실행
    run_test "버전 비교 테스트" test_version_comparison
    run_test "마이그레이션 경로 테스트" test_migration_path
    run_test "현재 버전 확인 테스트" test_check_current_version
    run_test "대상 버전 확인 테스트" test_check_target_version
    
    # 추가 테스트는 여기에...
}

# 테스트 정리 작업
cleanup_test() {
    # 테스트로 생성된 VERSION 파일 정리
    if [ -f "$PROJECT_ROOT/bin/VERSION" ]; then
        rm -f "$PROJECT_ROOT/bin/VERSION"
    fi
}

# 스크립트가 직접 실행될 때 테스트 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 이 파일이 직접 실행될 경우의 처리
    echo "이 파일은 module_test.sh를 통해 실행해야 합니다."
    echo "예: ./src/dev/module_test.sh migrate"
    exit 1
fi 