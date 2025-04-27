#!/bin/bash

# stop 모듈 - Docker 개발 환경 일시 중지
# stop module - Pause Docker development environment

# 공통 모듈 로드
# Load common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$MODULES_DIR/container_actions.sh"

# 사용법 표시 함수
# Show usage function
show_usage() {
    log "INFO" "$MSG_STOP_USAGE"
    echo -e "  dockit stop <no> - $MSG_STOP_USAGE_NO"
    echo -e "  dockit stop this - $MSG_STOP_USAGE_THIS"
    echo -e "  dockit stop all - $MSG_STOP_USAGE_ALL"
    echo ""
}

# 메인 함수
# Main function
stop_main() {
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
            handle_this_argument "stop"
            ;;
        "all")
            # all 인자 처리
            perform_all_containers_action "stop"
            ;;
        *)
            # 숫자 인자 처리 시도
            if handle_numeric_arguments "stop" "$@"; then
                return 0
            else
                # 잘못된 인자 처리
                log "ERROR" "$MSG_STOP_INVALID_ARGS"
                show_usage "$@"
            fi
            ;;
    esac
    
    return 0
}

# 직접 실행 시
# When executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    stop_main "$@"
fi 