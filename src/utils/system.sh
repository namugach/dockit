#!/bin/bash

# 시스템 관련 유틸리티 함수들
# System utility functions

# 명령어 존재 확인 함수
# Check if command exists
check_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# OS 타입 확인 함수
# Check OS type
get_os_type() {
    case "$(uname -s)" in
        Linux*)     echo "Linux";;
        Darwin*)    echo "MacOS";;
        CYGWIN*)    echo "Cygwin";;
        MINGW*)     echo "MinGW";;
        MSYS*)      echo "MSYS";;
        *)          echo "Unknown";;
    esac
}

# 리눅스 배포판 확인 함수
# Check Linux distribution
get_linux_distribution() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        echo "$ID"
    elif type lsb_release >/dev/null 2>&1; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/lsb-release ]; then
        source /etc/lsb-release
        echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# 앱 버전 가져오기 함수
# Get application version
get_app_version() {
    local app="$1"
    local version_args="${2:---version}"
    
    if check_command_exists "$app"; then
        "$app" $version_args 2>&1 | head -n 1
    else
        echo "not_installed"
    fi
}

# Docker 검사 함수
# Check Docker
check_docker() {
    if ! check_command_exists "docker"; then
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        return 2
    fi
    
    return 0
}

# Docker Compose 검사 함수
# Check Docker Compose
check_docker_compose() {
    if check_command_exists "docker-compose"; then
        return 0
    elif docker compose version >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 포트 사용 가능 여부 검사 함수
# Check if port is available
check_port_available() {
    local port="$1"
    
    if check_command_exists "nc"; then
        nc -z localhost "$port" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            return 1  # 포트가 이미 사용 중
        else
            return 0  # 포트 사용 가능
        fi
    elif check_command_exists "lsof"; then
        lsof -i:"$port" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            return 1  # 포트가 이미 사용 중
        else
            return 0  # 포트 사용 가능
        fi
    else
        # 대체 메서드가 없는 경우
        # 항상 성공하도록 하되 경고 메시지 출력
        echo "Warning: Cannot check port availability. Neither nc nor lsof found." >&2
        return 0
    fi
}

# 현재 사용자 ID 가져오기
# Get current user ID
get_current_uid() {
    id -u
}

# 현재 그룹 ID 가져오기
# Get current group ID
get_current_gid() {
    id -g
}

# 메모리 정보 가져오기 (MB 단위)
# Get memory info in MB
get_total_memory() {
    if [ "$(get_os_type)" = "Linux" ]; then
        free -m | awk '/^Mem:/{print $2}'
    elif [ "$(get_os_type)" = "MacOS" ]; then
        # macOS에서는 sysctl 명령 사용
        sysctl hw.memsize | awk '{print $2 / 1024 / 1024}'
    else
        echo "unknown"
    fi
}

# 디스크 공간 확인 (GB 단위)
# Check available disk space in GB
get_available_disk_space() {
    local path="${1:-.}"
    
    if [ "$(get_os_type)" = "Linux" ] || [ "$(get_os_type)" = "MacOS" ]; then
        df -BG "$path" | awk 'NR==2 {print $4}' | sed 's/G//'
    else
        echo "unknown"
    fi
} 