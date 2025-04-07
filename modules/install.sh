#!/bin/bash

# install 모듈 - Docker 개발 환경 초기 설치 및 설정

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 사용자 입력 함수
get_user_input() {
    log "INFO" "사용자 입력 받는 중..."
    
    echo -e "\n${GREEN}Docker 개발 환경 설정${NC}"
    echo -e "${BLUE}(엔터 키를 누르면 괄호 안의 기본값이 사용됩니다)${NC}"
    
    # 현재 설정 표시
    echo -e "\n${YELLOW}다음 기본값으로 설정됩니다:${NC}"
    echo -e "사용자 이름: ${GREEN}$USERNAME${NC}"
    echo -e "사용자 UID: ${GREEN}$USER_UID${NC}"
    echo -e "사용자 GID: ${GREEN}$USER_GID${NC}"
    echo -e "비밀번호: ${GREEN}$USER_PASSWORD${NC}"
    echo -e "작업 디렉토리: ${GREEN}$WORKDIR${NC}"
    echo -e "이미지 이름: ${GREEN}$IMAGE_NAME${NC}"
    echo -e "컨테이너 이름: ${GREEN}$CONTAINER_NAME${NC}"
    
    # 선택 옵션
    echo -e "\n${BLUE}선택하세요:${NC}"
    echo -e "${GREEN}y${NC} - 기본값으로 계속 진행"
    echo -e "${YELLOW}n${NC} - 각 값을 수정"
    echo -e "${RED}c${NC} - 취소"
    read -p "선택 [Y/n/c]: " choice
    choice=${choice:-y}
    
    case $choice in
        y|Y)
            # 기본값 사용 (이미 설정됨)
            ;;
        n|N)
            # 각 값을 사용자 입력으로 받기
            read -p "사용자 이름 ($USERNAME): " input
            USERNAME=${input:-$USERNAME}
            
            read -p "사용자 UID ($USER_UID): " input
            USER_UID=${input:-$USER_UID}
            
            read -p "사용자 GID ($USER_GID): " input
            USER_GID=${input:-$USER_GID}
            
            read -p "사용자 비밀번호 ($USER_PASSWORD): " input
            USER_PASSWORD=${input:-$USER_PASSWORD}
            
            read -p "작업 디렉토리 이름 ($WORKDIR): " input
            WORKDIR=${input:-$WORKDIR}
            
            read -p "이미지 이름 ($IMAGE_NAME): " input
            IMAGE_NAME=${input:-$IMAGE_NAME}
            
            read -p "컨테이너 이름 ($CONTAINER_NAME): " input
            CONTAINER_NAME=${input:-$CONTAINER_NAME}
            ;;
        c|C)
            # 취소
            log "INFO" "설치가 취소되었습니다."
            exit 0
            ;;
        *)
            # 잘못된 입력
            log "ERROR" "잘못된 선택입니다. 설치가 취소되었습니다."
            exit 1
            ;;
    esac
    
    # 최종 설정 정보 확인
    echo -e "\n${YELLOW}최종 설정 정보:${NC}"
    echo -e "사용자 이름: ${GREEN}$USERNAME${NC}"
    echo -e "사용자 UID: ${GREEN}$USER_UID${NC}"
    echo -e "사용자 GID: ${GREEN}$USER_GID${NC}"
    echo -e "비밀번호: ${GREEN}$USER_PASSWORD${NC}"
    echo -e "작업 디렉토리: ${GREEN}$WORKDIR${NC}"
    echo -e "이미지 이름: ${GREEN}$IMAGE_NAME${NC}"
    echo -e "컨테이너 이름: ${GREEN}$CONTAINER_NAME${NC}"
    
    # 설정 저장
    save_config
}

# Docker Compose 템플릿 파일 생성
create_docker_compose() {
    log "INFO" "Docker Compose 파일 생성 중..."
    
    # 기존 템플릿 파일이 있는지 확인
    if [ ! -f "$DOCKER_COMPOSE_TEMPLATE" ]; then
        log "WARNING" "Docker Compose 템플릿 파일이 없습니다. 새로 생성합니다."
        
        # 템플릿 생성
        mkdir -p "$TEMPLATES_DIR"
        cat > "$DOCKER_COMPOSE_TEMPLATE" << EOF
version: '3.8'

services:
  dev:
    image: \${IMAGE_NAME}
    container_name: \${CONTAINER_NAME}
    volumes:
      - ./:/home/\${USERNAME}/\${WORKDIR}
    stdin_open: true
    tty: true
EOF
        log "SUCCESS" "Docker Compose 템플릿 파일이 생성되었습니다."
    fi
    
    # 템플릿 처리
    process_template "$DOCKER_COMPOSE_TEMPLATE" "$PROJECT_ROOT/docker-compose.yml"
}

# Dockerfile 템플릿 파일 생성
create_dockerfile() {
    log "INFO" "Dockerfile 템플릿 파일 생성 중..."
    
    # 기존 템플릿 파일이 있는지 확인
    if [ ! -f "$DOCKERFILE_TEMPLATE" ]; then
        log "WARNING" "Dockerfile 템플릿 파일이 없습니다. 새로 생성합니다."
        
        # 템플릿 생성
        mkdir -p "$TEMPLATES_DIR"
        cat > "$DOCKERFILE_TEMPLATE" << EOF
FROM namugach/ubuntu-basic:24.04-kor-deno

# 빌드 시 사용할 인자들
ARG USERNAME=\${USERNAME}
ARG USER_UID=\${USER_UID}
ARG USER_GID=\${USER_GID}
ARG USER_PASSWORD=\${USER_PASSWORD}
ARG WORKDIR=\${WORKDIR}

# sudo 설치 및 기타 유틸리티
RUN apt-get update && apt-get install -y sudo git

# 사용자 그룹 및 사용자 생성
RUN groupadd -g \${USER_GID} \${USERNAME} || echo "Group already exists"
RUN useradd -m -d /home/\${USERNAME} -u \${USER_UID} -g \${USERNAME} \${USERNAME}

# 사용자에게 sudo 권한 부여 및 비밀번호 설정
RUN echo "\${USERNAME}:\${USER_PASSWORD}" | chpasswd && \\
    usermod -aG sudo \${USERNAME} && \\
    echo "\${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 작업 디렉토리 생성 및 소유권 설정
RUN mkdir -p /home/\${USERNAME}/\${WORKDIR} && \\
    chown -R \${USERNAME}:\${USERNAME} /home/\${USERNAME}

# SSH 디렉토리 생성
RUN mkdir -p /home/\${USERNAME}/.ssh && \\
    chmod 700 /home/\${USERNAME}/.ssh && \\
    chown -R \${USERNAME}:\${USERNAME} /home/\${USERNAME}/.ssh

# 한국어 로케일 설정 및 쉘 자동 변경 설정
RUN echo "export LANG=ko_KR.UTF-8" >> /home/\${USERNAME}/.bashrc && \\
    echo "export LC_ALL=ko_KR.UTF-8" >> /home/\${USERNAME}/.bashrc && \\
    chown \${USERNAME}:\${USERNAME} /home/\${USERNAME}/.bashrc && \\
    chown \${USERNAME}:\${USERNAME} /home/\${USERNAME}/.profile

# 볼륨 마운트 시 권한 문제 해결을 위한 스크립트 추가
RUN echo '#!/bin/bash\\nif [ -d "\$HOME/\${WORKDIR}" ] && [ "\$(stat -c %u "\$HOME/\${WORKDIR}")" != "\$(id -u)" ]; then\\n  sudo chown -R \$(id -u):\$(id -g) "\$HOME/\${WORKDIR}"\\nfi\\nexec "\$@"' > /usr/local/bin/entrypoint.sh && \\
    chmod +x /usr/local/bin/entrypoint.sh

# Git 안전 디렉토리 설정
USER \${USERNAME}
RUN git config --global --add safe.directory "*"
USER root

# 기본 작업 디렉토리 설정
WORKDIR /home/\${USERNAME}/\${WORKDIR}

# 사용자로 전환
USER \${USERNAME}

# 기본 쉘 설정 - 엔트리포인트 스크립트 추가
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
EOF
        log "SUCCESS" "Dockerfile 템플릿 파일이 생성되었습니다."
    fi
}

# Docker 이미지 빌드 함수
build_docker_image() {
    log "INFO" "Docker 이미지 빌드 중: $IMAGE_NAME"
    
    # 치환된 Dockerfile 생성 (임시 파일)
    local temp_dockerfile="$PROJECT_ROOT/.dockerfile.tmp"
    process_template "$DOCKERFILE_TEMPLATE" "$temp_dockerfile"
    
    # 이미지 빌드
    if docker build \
      --build-arg USERNAME="$USERNAME" \
      --build-arg USER_UID="$USER_UID" \
      --build-arg USER_GID="$USER_GID" \
      --build-arg USER_PASSWORD="$USER_PASSWORD" \
      --build-arg WORKDIR="$WORKDIR" \
      -t "$IMAGE_NAME" \
      -f "$temp_dockerfile" "$PROJECT_ROOT"; then
        
        log "SUCCESS" "Docker 이미지가 성공적으로 빌드되었습니다!"
        rm -f "$temp_dockerfile"
        return 0
    else
        log "ERROR" "Docker 이미지 빌드 중 오류가 발생했습니다."
        rm -f "$temp_dockerfile"
        return 1
    fi
}

# 컨테이너 시작 및 접속 함수
ask_start_container() {
    echo -e "\n${YELLOW}컨테이너를 시작할까요? (y/n):${NC}"
    read -p "선택 [Y/n]: " start_container
    start_container=${start_container:-y}
    
    if [[ $start_container == "y" || $start_container == "Y" ]]; then
        log "INFO" "컨테이너 시작 중..."
        
        # docker-compose를 사용하여 컨테이너 시작
        if $DOCKER_COMPOSE_CMD -f "$PROJECT_ROOT/docker-compose.yml" up -d; then
            log "SUCCESS" "컨테이너가 성공적으로 시작되었습니다!"
            
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
        else
            log "ERROR" "컨테이너 시작 중 오류가 발생했습니다."
        fi
    else
        log "INFO" "컨테이너 시작을 건너뜁니다."
        echo -e "\n${BLUE}나중에 컨테이너를 시작하려면:${NC} ./docker-tools.sh start"
    fi
}

# 메인 함수
install_main() {
    log "INFO" "설치 시작..."
    
    # 사용자 입력 받기
    get_user_input
    
    # 템플릿 파일 생성
    create_dockerfile
    
    # Docker 이미지 빌드
    if build_docker_image; then
        # Docker Compose 파일 생성
        create_docker_compose
        
        # 컨테이너 시작 및 접속 여부 물어보기
        ask_start_container
        
        log "SUCCESS" "설치가 완료되었습니다!"
    else
        log "ERROR" "설치에 실패했습니다."
        exit 1
    fi
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_main "$@"
fi 