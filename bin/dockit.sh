#!/bin/bash

# Docker Development Environment Setup Tool
# 도커 개발 환경 설정 도구

# 스크립트 디렉토리 설정
# Script directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES_DIR="$SCRIPT_DIR/src/modules"
CONFIG_DIR="$SCRIPT_DIR/config"

# 공통 모듈 로드
# Load common module
source "$MODULES_DIR/common.sh"

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

    # init과 help를 제외한 모든 명령어에 대해 유효성 검사
    # Check validity for all commands except init and help
    if [[ "$command" != "init" ]] && [[ "$command" != "help" ]]; then
        if ! check_dockit_validity; then
            exit 1
        fi
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