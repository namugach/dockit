#!/bin/bash

# stop 모듈 - Docker 컨테이너 정지

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 컨테이너 정지 함수
stop_container() {
    log "INFO" "컨테이너 정지 중..."
    
    # Docker Compose 파일 존재 확인
    if ! check_docker_compose_file; then
        return 1
    fi
    
    # 컨테이너 상태 확인
    check_container_status "$CONTAINER_NAME"
    local status=$?
    
    if [ $status -eq 0 ]; then
        # 컨테이너 정지
        echo -e "\n${YELLOW}컨테이너를 정지할까요? (y/n):${NC}"
        read -p "선택 [Y/n]: " confirm
        confirm=${confirm:-y}
        
        if [[ $confirm == "y" || $confirm == "Y" ]]; then
            log "INFO" "docker compose down 실행 중..."
            
            if $DOCKER_COMPOSE_CMD -f "$PROJECT_ROOT/docker-compose.yml" down; then
                log "SUCCESS" "컨테이너가 성공적으로 정지되었습니다!"
                return 0
            else
                log "ERROR" "컨테이너 정지 중 오류가 발생했습니다."
                return 1
            fi
        else
            log "INFO" "컨테이너 정지를 취소했습니다."
            return 0
        fi
    elif [ $status -eq 1 ]; then
        # 컨테이너가 이미 중지됨
        log "INFO" "컨테이너가 이미 정지되었습니다: $CONTAINER_NAME"
        
        echo -e "\n${YELLOW}컨테이너를 완전히 제거할까요? (y/n):${NC}"
        read -p "선택 [Y/n]: " remove
        remove=${remove:-y}
        
        if [[ $remove == "y" || $remove == "Y" ]]; then
            log "INFO" "docker compose down 실행 중..."
            
            if $DOCKER_COMPOSE_CMD -f "$PROJECT_ROOT/docker-compose.yml" down; then
                log "SUCCESS" "컨테이너가 성공적으로 제거되었습니다!"
                return 0
            else
                log "ERROR" "컨테이너 제거 중 오류가 발생했습니다."
                return 1
            fi
        else
            log "INFO" "컨테이너 제거를 취소했습니다."
            return 0
        fi
    else
        # 컨테이너가 없음
        log "WARNING" "실행 중인 컨테이너가 없습니다."
        return 0
    fi
}

# 메인 함수
stop_main() {
    log "INFO" "컨테이너 정지 모듈 실행 중..."
    stop_container
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    stop_main "$@"
fi 