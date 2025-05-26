#!/bin/bash

# down 모듈 - Docker 개발 환경 종료
# down module - Terminate Docker development environment

# 공통 모듈 로드
# Load common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 메인 함수
# Main function
down_main() {
    log "INFO" "$MSG_DOWN_START"
    
    # Docker Compose 파일이 있는지 확인
    # Check if Docker Compose file exists
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        log "ERROR" "$MSG_COMPOSE_NOT_FOUND"
        exit 1
    fi
    
    # 컨테이너 중지
    # Stop container
    if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" down; then
        log "SUCCESS" "$MSG_CONTAINER_DOWN"
        
        # 레지스트리 상태 업데이트
        local project_id
        if project_id=$(get_current_project_id); then
            update_project_state "$project_id" "$PROJECT_STATE_DOWN"
            log "INFO" "Project status updated to stopped"
        else
            log "WARNING" "Could not update project status - project ID not found"
        fi
    else
        log "ERROR" "$MSG_CONTAINER_STOP_FAILED"
        exit 1
    fi
}

# 직접 실행 시
# When executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    down_main "$@"
fi 