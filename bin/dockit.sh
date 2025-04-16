#!/bin/bash

# Docker Development Environment Setup Tool
# 도커 개발 환경 설정 도구

# 스크립트 디렉토리 설정
# Script directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES_DIR="$SCRIPT_DIR/src/modules"
CONFIG_DIR="$SCRIPT_DIR/config"

# 버전 정보 로드
# Load version information
VERSION_FILE="$(dirname "${BASH_SOURCE[0]}")/VERSION"
# 설치 시에는 bin 디렉토리 경로가 달라짐
if [ ! -f "$VERSION_FILE" ] && [ -f "$SCRIPT_DIR/bin/VERSION" ]; then
    VERSION_FILE="$SCRIPT_DIR/bin/VERSION"
fi
if [ -f "$VERSION_FILE" ]; then
    VERSION=$(cat "$VERSION_FILE")
else
    VERSION="unknown"
fi

# 버전 표시 함수
# Display version function
show_version() {
    echo "Dockit version $VERSION"
    echo "Copyright (c) $(date +%Y)"
    echo "MIT License"
}

# 메인 함수
# Main function
main() {
    local command="$1"
    shift

    # 명령어가 비어있을 때만 도움말 표시
    # Show help only when command is empty
    if [[ -z "$command" ]]; then
        source "$MODULES_DIR/help.sh"
        show_help
        exit 0
    fi

    # version 명령어 처리
    # Handle version command
    if [[ "$command" == "version" ]]; then
        show_version
        exit 0
    fi

    # 공통 모듈 로드
    # Load common module
    if [[ "$command" == "init" ]] || [[ "$command" == "help" ]]; then
        source "$MODULES_DIR/common.sh" "init"
    else
        source "$MODULES_DIR/common.sh" "$command"
    fi

    case "$command" in
        init)
            source "$MODULES_DIR/init.sh"
            init_main "$@"
            ;;
        start)
            source "$MODULES_DIR/start.sh"
            start_main "$@"
            ;;
        stop)
            source "$MODULES_DIR/stop.sh"
            stop_main "$@"
            ;;
        down)
            source "$MODULES_DIR/down.sh"
            down_main "$@"
            ;;
        connect)
            source "$MODULES_DIR/connect.sh"
            connect_main "$@"
            ;;
        status)
            source "$MODULES_DIR/status.sh"
            status_main "$@"
            ;;
        help)
            source "$MODULES_DIR/help.sh"
            show_help
            ;;
        *)
            source "$MODULES_DIR/help.sh"
            show_help
            ;;
    esac
}

# 스크립트가 직접 실행될 때만 메인 함수 실행
# Execute main function only when script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi