#!/bin/bash

# Start module - Start Docker development environment
# start 모듈 - Docker 개발 환경 시작

# Load common module
# 공통 모듈 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$MODULES_DIR/container_actions.sh"

# 메시지 선언
MSG_NO_CONTAINERS="No containers found."

# 사용법 표시 함수
# Show usage function
show_usage() {
    log "INFO" "$MSG_START_USAGE"
    echo -e "  dockit start <no> - $MSG_START_USAGE_NO"
    echo -e "  dockit start this - $MSG_START_USAGE_THIS"
    echo -e "  dockit start all - $MSG_START_USAGE_ALL"
    echo ""
}

# Main function
# 메인 함수
start_main() {
    # Docker 사용 가능 여부 확인
    if ! command -v docker &> /dev/null; then
        log "ERROR" "$MSG_COMMON_DOCKER_NOT_FOUND"
        return 1
    fi

    # 인자가 없는 경우 컨테이너 목록 표시
    # If no arguments, show container list
    if [ $# -eq 0 ]; then
        show_usage "$@"
        return 0
    fi
    
    # 첫 번째 인자에 따른 처리
    case "$1" in
        "this")
            # this 인자 처리
            handle_this_argument "start"
            ;;
        "all")
            # all 인자 처리
            perform_all_containers_action "start"
            ;;
        *)
            # 숫자 인자 처리 시도
            if handle_numeric_arguments "start" "$@"; then
                return 0
            else
                # 잘못된 인자 처리
                log "ERROR" "$MSG_START_INVALID_ARGS"
                show_usage
            fi
            ;;
    esac
    
    return 0
}

# Execute main function if script is run directly
# 스크립트가 직접 실행되면 메인 함수 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start_main "$@"
fi 