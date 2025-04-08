#!/bin/bash

# Docker Development Environment Setup Tool
# 도커 개발 환경 설정 도구

# 스크립트 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES_DIR="$SCRIPT_DIR/src/modules"
CONFIG_DIR="$SCRIPT_DIR/config"

# 공통 모듈 로드
source "$MODULES_DIR/common.sh"

# 메인 함수
main() {
    local command="$1"
    shift

    case "$command" in
        install)
            source "$MODULES_DIR/install.sh"
            install_main "$@"
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
        help|*)
            source "$MODULES_DIR/help.sh"
            show_help
            ;;
    esac
}

# 스크립트가 직접 실행될 때만 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi