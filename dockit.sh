#!/bin/bash

# dockit - Docker 개발 환경 관리 도구
# dockit - Docker development environment management tool
# 모듈식 구조로 Docker 컨테이너 관리를 간소화합니다.
# Simplifies Docker container management with a modular structure.

# 스크립트 경로 설정
# Set script paths
SCRIPT_DIR=$(readlink -f "$(dirname "$0")")
export DOCKIT_ROOT="$SCRIPT_DIR"
export MODULES_DIR="$SCRIPT_DIR/src/modules"
export TEMPLATES_DIR="$SCRIPT_DIR/src/templates"
export CONFIG_DIR="$SCRIPT_DIR/config"

# 시스템 설정 파일 로드 (존재하는 경우)
# Load system configuration file (if exists)
if [ -f "$CONFIG_DIR/system.sh" ]; then
    # 디버깅을 위한 설정 표시
    # Display settings for debugging
    if [ "$DEBUG" = "true" ]; then
        echo "시스템 설정 파일 로드: $CONFIG_DIR/system.sh"
    fi
    
    # 설정 파일 로드
    # Load configuration file
    source "$CONFIG_DIR/system.sh"
fi

# 디버깅을 위한 경로 표시
# Display paths for debugging
if [ "$DEBUG" = "true" ]; then
    echo "MODULES_DIR=$MODULES_DIR"
    echo "TEMPLATES_DIR=$TEMPLATES_DIR"
    echo "CONFIG_DIR=$CONFIG_DIR"
    echo "LANGUAGE=$LANGUAGE"
fi

# 공통 모듈 로드
# Load common module
source "$MODULES_DIR/common.sh"

# 현재 디렉토리를 기억
# Remember current directory
ORIGINAL_PWD=$(pwd)

# 사용법 출력 함수
# Function to display usage
usage() {
    "$MODULES_DIR/help.sh"
    exit 0
}

# 인자 검사
# Check arguments
if [ $# -lt 1 ]; then
    # 인자가 없으면 자동으로 help 실행
    # If no arguments, automatically run help
    usage
fi

# 명령 인식
# Command recognition
COMMAND="$1"
shift # 첫 번째 인자 제거 # Remove first argument

# 명령 처리
# Command processing
case "$COMMAND" in
    install)
        # 설치 및 초기 설정 실행
        # Run installation and initial setup
        "$MODULES_DIR/install.sh" "$@"
        ;;
    start)
        # 컨테이너 시작
        # Start container
        "$MODULES_DIR/start.sh" "$@"
        ;;
    stop)
        # 컨테이너 정지
        # Stop container
        "$MODULES_DIR/stop.sh" "$@"
        ;;
    down)
        # 컨테이너 완전 제거
        # Completely remove container
        "$MODULES_DIR/down.sh" "$@"
        ;;
    connect)
        # 컨테이너 접속
        # Connect to container
        "$MODULES_DIR/connect.sh" "$@"
        ;;
    status)
        # 컨테이너 상태 확인
        # Check container status
        "$MODULES_DIR/status.sh" "$@"
        ;;
    help)
        # 도움말 표시
        # Display help
        "$MODULES_DIR/help.sh" "$@"
        ;;
    *)
        # 알 수 없는 명령
        # Unknown command
        echo "알 수 없는 명령: $COMMAND"
        usage
        ;;
esac

# 원래 디렉토리로 복귀
# Return to original directory
cd "$ORIGINAL_PWD"

exit 0