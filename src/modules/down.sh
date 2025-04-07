#!/bin/bash

# down 모듈 - Docker 컨테이너 완전 제거

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 컨테이너 제거 함수
down_container() {
    log "INFO" "컨테이너 제거 중..."
    
    # Docker Compose 파일 존재 확인
    if ! check_docker_compose_file; then
        return 1
    fi
    
    # 컨테이너 상태 확인 (실행 중이든 정지 상태든 확인)
    if docker container inspect "$CONTAINER_NAME" &>/dev/null; then
        # 컨테이너가 존재함
        echo -e "\n${YELLOW}컨테이너를 완전히 제거할까요? (y/n):${NC}"
        echo -e "${RED}주의: 컨테이너 내부의 모든 데이터가 삭제됩니다!${NC}"
        read -p "선택 [Y/n]: " confirm
        confirm=${confirm:-y}
        
        if [[ $confirm == "y" || $confirm == "Y" ]]; then
            log "INFO" "docker compose down 실행 중..."
            
            if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" down; then
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
        log "WARNING" "제거할 컨테이너가 없습니다: $CONTAINER_NAME"
        return 0
    fi
}

# 메인 함수
down_main() {
    log "INFO" "컨테이너 제거 모듈 실행 중..."
    down_container
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    down_main "$@"
fi 