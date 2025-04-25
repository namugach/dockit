#!/bin/bash

# join 모듈 - run과 connect를 한번에 실행
# join module - Run run and connect in one command

# 공통 모듈 로드
# Load common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" "join"

# 모듈 로드
# Load modules
source "$MODULES_DIR/run.sh"
source "$MODULES_DIR/connect.sh"

# 자동 실행 함수
# Automated run function
join_run() {
    log "INFO" "$MSG_JOIN_RUN_START"
    
    # run 모듈의 메인 함수 실행
    # Execute run module's main function
    run_main "$@"
    
    log "INFO" "$MSG_JOIN_RUN_COMPLETE"
}

# 자동 접속 함수
# Automated connect function
join_connect() {
    log "INFO" "$MSG_JOIN_CONNECT_START"
    
    # connect 모듈의 메인 함수 실행
    # Execute connect module's main function
    # 사용자 입력 프롬프트가 나타나지 않도록 자동 'y' 입력 시뮬레이션
    # Simulate automatic 'y' input to avoid user prompts
    
    # 자동 접속을 위한 입력 오버라이드
    # Override read command for automated connection
    function read() {
        echo "y"
    }
    
    # connect_main 실행
    # Execute connect_main
    connect_main "$@"
    
    log "INFO" "$MSG_JOIN_CONNECT_COMPLETE"
}

# join 메인 함수
# join main function
join_main() {
    log "INFO" "$MSG_JOIN_START"
    
    # 1. 자동 실행 (run)
    join_run "$@"
    
    # 2. 자동 접속 (connect)
    join_connect "$@"
    
    log "SUCCESS" "$MSG_JOIN_COMPLETE"
}

# 스크립트가 직접 실행되면 메인 함수 실행
# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    join_main "$@"
fi 