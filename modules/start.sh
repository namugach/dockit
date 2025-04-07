#!/bin/bash

# start 모듈 - Docker 컨테이너 시작

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 컨테이너 시작 함수
start_container() {
    log "INFO" "컨테이너 시작 중..."
    
    # Docker Compose 파일 존재 확인
    if ! check_docker_compose_file; then
        return 1
    fi
    
    # 컨테이너 상태 확인
    check_container_status "$CONTAINER_NAME"
    local status=$?
    
    if [ $status -eq 0 ]; then
        log "INFO" "컨테이너가 이미 실행 중입니다: $CONTAINER_NAME"
    else
        # docker-compose를 사용하여 컨테이너 시작
        log "INFO" "docker-compose로 컨테이너 시작 중..."
        
        if docker-compose -f "$PROJECT_ROOT/docker-compose.yml" up -d; then
            log "SUCCESS" "컨테이너가 성공적으로 시작되었습니다!"
        else
            log "ERROR" "컨테이너 시작 중 오류가 발생했습니다."
            log "INFO" "다음을 확인하세요:"
            log "INFO" "1. Docker 서비스가 실행 중인지"
            log "INFO" "2. 포트 충돌이 없는지"
            log "INFO" "3. 이미지가 존재하는지 (없다면 설치 필요)"
            return 1
        fi
    fi
    
    # 컨테이너 접속 여부 확인
    echo -e "\n${YELLOW}컨테이너에 접속할까요? (y/n):${NC}"
    read -p "선택 [Y/n]: " connect_container
    connect_container=${connect_container:-y}
    
    if [[ $connect_container == "y" || $connect_container == "Y" ]]; then
        log "INFO" "컨테이너에 접속 중..."
        docker exec -it "$CONTAINER_NAME" /bin/bash
    else
        log "INFO" "컨테이너 접속을 건너뜁니다."
        echo -e "\n${BLUE}나중에 컨테이너에 접속하려면:${NC} ./docker-tools.sh connect"
    fi
    
    return 0
}

# 메인 함수
start_main() {
    log "INFO" "컨테이너 시작 모듈 실행 중..."
    start_container
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start_main "$@"
fi 