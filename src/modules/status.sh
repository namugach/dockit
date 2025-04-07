#!/bin/bash

# status 모듈 - Docker 컨테이너 상태 확인

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 컨테이너 상태 표시 함수
show_container_status() {
    log "INFO" "컨테이너 상태 확인 중..."
    
    echo -e "\n${BLUE}===== Docker 컨테이너 상태 =====${NC}"
    
    # 설정 정보 표시
    echo -e "\n${YELLOW}설정 정보:${NC}"
    echo -e "이미지 이름: ${GREEN}$IMAGE_NAME${NC}"
    echo -e "컨테이너 이름: ${GREEN}$CONTAINER_NAME${NC}"
    echo -e "사용자 이름: ${GREEN}$USERNAME${NC}"
    echo -e "작업 디렉토리: ${GREEN}$WORKDIR${NC}"
    
    # Docker Compose 파일 확인
    if [ -f "$DOCKER_COMPOSE_FILE" ]; then
        echo -e "\n${YELLOW}Docker Compose 설정:${NC}"
        echo -e "${GREEN}파일 존재: $DOCKER_COMPOSE_FILE${NC}"
    else
        echo -e "\n${YELLOW}Docker Compose 설정:${NC}"
        echo -e "${RED}파일 없음: $DOCKER_COMPOSE_FILE${NC}"
        echo -e "${BLUE}설치를 실행하세요: ./dockit.sh install${NC}"
    fi
    
    # 이미지 존재 확인
    if docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo -e "\n${YELLOW}Docker 이미지 상태:${NC}"
        echo -e "${GREEN}이미지가 존재합니다: $IMAGE_NAME${NC}"
        
        # 이미지 정보 표시
        local image_created=$(docker image inspect --format='{{.Created}}' "$IMAGE_NAME")
        local image_size=$(docker image inspect --format='{{.Size}}' "$IMAGE_NAME" | numfmt --to=iec)
        
        echo -e "생성 시간: ${GREEN}$image_created${NC}"
        echo -e "이미지 크기: ${GREEN}$image_size${NC}"
    else
        echo -e "\n${YELLOW}Docker 이미지 상태:${NC}"
        echo -e "${RED}이미지가 존재하지 않습니다: $IMAGE_NAME${NC}"
        echo -e "${BLUE}설치를 실행하세요: ./dockit.sh install${NC}"
    fi
    
    # 컨테이너 상태 확인
    check_container_status "$CONTAINER_NAME"
    local status=$?
    
    echo -e "\n${YELLOW}컨테이너 상태:${NC}"
    
    if [ $status -eq 0 ]; then
        # 컨테이너 실행 중
        echo -e "${GREEN}컨테이너가 실행 중입니다: $CONTAINER_NAME${NC}"
        
        # 컨테이너 상세 정보
        local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_NAME")
        local container_created=$(docker inspect -f '{{.Created}}' "$CONTAINER_NAME")
        local container_status=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME")
        
        echo -e "IP 주소: ${GREEN}$container_ip${NC}"
        echo -e "생성 시간: ${GREEN}$container_created${NC}"
        echo -e "상태: ${GREEN}$container_status${NC}"
        
        # 접속 명령어 안내
        echo -e "\n${BLUE}컨테이너 접속 명령어:${NC} ./dockit.sh connect"
    elif [ $status -eq 1 ]; then
        # 컨테이너 중지됨
        echo -e "${YELLOW}컨테이너가 중지되었습니다: $CONTAINER_NAME${NC}"
        echo -e "${BLUE}컨테이너 시작 명령어:${NC} ./dockit.sh start"
    else
        # 컨테이너 없음
        echo -e "${RED}컨테이너가 존재하지 않습니다: $CONTAINER_NAME${NC}"
        echo -e "${BLUE}컨테이너 시작 명령어:${NC} ./dockit.sh start"
    fi
    
    echo -e "\n${BLUE}=================================${NC}"
}

# 메인 함수
status_main() {
    log "INFO" "상태 확인 모듈 실행 중..."
    show_container_status
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    status_main "$@"
fi 