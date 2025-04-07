#!/bin/bash

# connect 모듈 - Docker 컨테이너 접속

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 컨테이너 접속 함수
connect_to_container() {
    log "INFO" "컨테이너 접속 시도 중..."
    
    # 컨테이너 상태 확인
    check_container_status "$CONTAINER_NAME"
    local status=$?
    
    if [ $status -eq 0 ]; then
        # 컨테이너 접속
        log "INFO" "컨테이너에 접속: $CONTAINER_NAME"
        docker exec -it "$CONTAINER_NAME" /bin/bash
    elif [ $status -eq 1 ]; then
        # 컨테이너가 중지됨
        log "WARNING" "컨테이너가 중지되었습니다: $CONTAINER_NAME"
        
        echo -e "\n${YELLOW}컨테이너를 시작할까요? (y/n):${NC}"
        read -p "선택 [Y/n]: " start_container
        start_container=${start_container:-y}
        
        if [[ $start_container == "y" || $start_container == "Y" ]]; then
            log "INFO" "컨테이너 시작 중..."
            
            if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d; then
                log "SUCCESS" "컨테이너가 성공적으로 시작되었습니다!"
                log "INFO" "컨테이너에 접속 중..."
                docker exec -it "$CONTAINER_NAME" /bin/bash
            else
                log "ERROR" "컨테이너 시작 중 오류가 발생했습니다."
                return 1
            fi
        else
            log "INFO" "컨테이너 시작을 취소했습니다."
            return 1
        fi
    else
        # 컨테이너가 없음
        log "ERROR" "컨테이너가 존재하지 않습니다: $CONTAINER_NAME"
        log "INFO" "먼저 컨테이너를 시작해야 합니다: ./dockit.sh start"
        
        # Docker Compose 파일 존재 확인
        if check_docker_compose_file; then
            echo -e "\n${YELLOW}컨테이너를 시작할까요? (y/n):${NC}"
            read -p "선택 [Y/n]: " start_container
            start_container=${start_container:-y}
            
            if [[ $start_container == "y" || $start_container == "Y" ]]; then
                log "INFO" "컨테이너 시작 중..."
                
                if $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d; then
                    log "SUCCESS" "컨테이너가 성공적으로 시작되었습니다!"
                    log "INFO" "컨테이너에 접속 중..."
                    docker exec -it "$CONTAINER_NAME" /bin/bash
                else
                    log "ERROR" "컨테이너 시작 중 오류가 발생했습니다."
                    return 1
                fi
            else
                log "INFO" "컨테이너 시작을 취소했습니다."
                return 1
            fi
        else
            log "ERROR" "설정이 완료되지 않았습니다. 설치를 먼저 실행하세요: ./dockit.sh install"
            return 1
        fi
    fi
    
    return 0
}

# 메인 함수
connect_main() {
    log "INFO" "컨테이너 접속 모듈 실행 중..."
    connect_to_container
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    connect_main "$@"
fi 