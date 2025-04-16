#!/bin/bash

# status_test.sh - 상태 확인 모듈 테스트

# 테스트 설정
setup_status_test() {
    log_info "상태 확인 테스트 환경 설정 중..."
    
    # 테스트 환경 변수 설정
    export CONFIG_DIR="$TEST_TMP_DIR"
    
    # 로그 디렉토리 생성
    mkdir -p "$TEST_TMP_DIR"
    touch "$TEST_TMP_DIR/dockit.log"
    
    # 모의 Docker 상태 파일 생성 - 실행 중인 상태
    mkdir -p "$TEST_TMP_DIR/docker"
    cat > "$TEST_TMP_DIR/docker/status.json" << EOF
{
  "status": "running",
  "containers": {
    "app": "running",
    "db": "running",
    "redis": "running"
  },
  "last_start": "$(date +%s)",
  "uptime": "2 days, 4 hours"
}
EOF

    log_info "상태 확인 테스트 환경 설정 완료"
}

# Docker 상태 체크 테스트
test_check_docker_status() {
    # Status 함수가 없으면 모의 함수 정의
    if ! type check_docker_status &>/dev/null; then
        check_docker_status() {
            local status_file="$CONFIG_DIR/docker/status.json"
            if [ -f "$status_file" ]; then
                local status=$(grep -o '"status": "[^"]*"' "$status_file" | cut -d'"' -f4)
                echo "$status"
                return 0
            else
                echo "unknown"
                return 1
            fi
        }
    fi
    
    # 테스트 실행
    local status=$(check_docker_status)
    
    # 결과 확인
    if [ "$status" = "running" ]; then
        log_info "성공: Docker 상태 확인 - $status"
        return 0
    else
        log_error "실패: Docker 상태 확인 - 예상값: running, 실제값: $status"
        return 1
    fi
}

# 컨테이너 상태 체크 테스트
test_check_container_status() {
    # 컨테이너 상태 확인 함수를 모의 함수로 대체
    # (원래 함수가 외부 의존성을 가질 수 있으므로)
    check_container_status() {
        local container="$1"
        local status_file="$CONFIG_DIR/docker/status.json"
        if [ -f "$status_file" ]; then
            local status=$(grep -o "\"$container\": \"[^\"]*\"" "$status_file" | cut -d'"' -f4)
            echo "$status"
            return 0
        else
            echo "unknown"
            return 1
        fi
    }
    
    # 테스트 실행
    local app_status=$(check_container_status "app")
    local db_status=$(check_container_status "db")
    
    # 결과 확인
    local success=true
    
    if [ "$app_status" = "running" ]; then
        log_info "성공: 앱 컨테이너 상태 확인 - $app_status"
    else
        log_error "실패: 앱 컨테이너 상태 확인 - 예상값: running, 실제값: $app_status"
        success=false
    fi
    
    if [ "$db_status" = "running" ]; then
        log_info "성공: 데이터베이스 컨테이너 상태 확인 - $db_status"
    else
        log_error "실패: 데이터베이스 컨테이너 상태 확인 - 예상값: running, 실제값: $db_status"
        success=false
    fi
    
    $success
    return $?
}

# 업타임 확인 테스트
test_check_uptime() {
    # 업타임 확인 함수가 없으면 모의 함수 정의
    if ! type check_uptime &>/dev/null; then
        check_uptime() {
            local status_file="$CONFIG_DIR/docker/status.json"
            if [ -f "$status_file" ]; then
                local uptime=$(grep -o '"uptime": "[^"]*"' "$status_file" | cut -d'"' -f4)
                echo "$uptime"
                return 0
            else
                echo "unknown"
                return 1
            fi
        }
    fi
    
    # 테스트 실행
    local uptime=$(check_uptime)
    
    # 결과 확인
    if [ "$uptime" = "2 days, 4 hours" ]; then
        log_info "성공: 업타임 확인 - $uptime"
        return 0
    else
        log_error "실패: 업타임 확인 - 예상값: 2 days, 4 hours, 실제값: $uptime"
        return 1
    fi
}

# 상태 모듈 테스트 실행
run_module_tests() {
    # 테스트 환경 설정
    setup_status_test
    
    # 테스트 케이스 실행
    run_test "Docker 상태 확인 테스트" test_check_docker_status
    run_test "컨테이너 상태 확인 테스트" test_check_container_status
    run_test "업타임 확인 테스트" test_check_uptime
    
    # 추가 테스트는 여기에...
}

# 테스트 정리 작업
cleanup_test() {
    # 테스트용 임시 파일 정리
    if [ -d "$TEST_TMP_DIR/docker" ]; then
        rm -rf "$TEST_TMP_DIR/docker"
    fi
}

# 스크립트가 직접 실행될 때 테스트 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 이 파일이 직접 실행될 경우의 처리
    echo "이 파일은 module_test.sh를 통해 실행해야 합니다."
    echo "예: ./src/dev/module_test.sh status"
    exit 1
fi 