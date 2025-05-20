#!/bin/bash

# Docker Development Environment Setup Tool
# 도커 개발 환경 설정 도구

# 스크립트 디렉토리 설정
# Script directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES_DIR="$SCRIPT_DIR/src/modules"
CONFIG_DIR="$SCRIPT_DIR/config"

# 버전 파일 경로 설정
# Set version file path
setup_version_file() {
    local version_file="$(dirname "${BASH_SOURCE[0]}")/VERSION"
    # 설치 시에는 bin 디렉토리 경로가 달라짐
    # Path changes during installation
    if [ ! -f "$version_file" ] && [ -f "$SCRIPT_DIR/bin/VERSION" ]; then
        version_file="$SCRIPT_DIR/bin/VERSION"
    fi
    echo "$version_file"
}

# 버전 정보 가져오기
# Get version information
get_version() {
    local version_file=$(setup_version_file)
    if [ -f "$version_file" ]; then
        cat "$version_file"
    else
        echo "unknown"
    fi
}

# 버전 표시 함수
# Display version function
show_version() {
    local version=$(get_version)
    echo "Dockit version $version"
    echo "Copyright (c) $(date +%Y)"
    echo "MIT License"
}

# 모듈 로드 함수
# Load module function
load_module() {
    local command="$1"
    if [[ "$command" == "init" ]] || [[ "$command" == "help" ]]; then
        source "$MODULES_DIR/common.sh" "init"
    else
        source "$MODULES_DIR/common.sh" "$command"
    fi
}

# 명령어 실행 함수
# Execute command function
execute_command() {
    local command="$1"
    shift
    
    case "$command" in
        init)
            source "$MODULES_DIR/init.sh"
            init_main "$@"
            ;;
        start)
            source "$MODULES_DIR/start.sh"
            start_main "$@"
            ;;
        build)
            source "$MODULES_DIR/build.sh"
            build_main "$@"
            ;;
        up)
            source "$MODULES_DIR/up.sh"
            up_main "$@"
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
        migrate)
            source "$MODULES_DIR/migrate.sh"
            migrate_main "$@"
            ;;
        setup)
            source "$MODULES_DIR/setup.sh"
            setup_main "$@"
            ;;
        run)
            source "$MODULES_DIR/run.sh"
            run_main "$@"
            ;;
        join)
            source "$MODULES_DIR/join.sh"
            join_main "$@"
            ;;
        list)
            source "$MODULES_DIR/list.sh"
            list_main "$@"
            ;;
        ps)
            source "$MODULES_DIR/ps.sh"
            list_main "$@"
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

    load_module "$command"
    execute_command "$command" "$@"
}

# 스크립트가 직접 실행될 때만 메인 함수 실행
# Execute main function only when script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi