#!/bin/bash

# 텍스트 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 템플릿 파일 처리 함수
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        echo -e "${RED}템플릿 파일을 찾을 수 없습니다: $template_file${NC}"
        return 1
    fi
    
    # 템플릿 파일 읽기
    local template_content=$(<"$template_file")
    
    # 변수 치환
    local processed_content=$(echo "$template_content" | 
        sed -e "s|\${USERNAME}|$username|g" \
            -e "s|\${WORKDIR}|$workdir|g" \
            -e "s|\${IMAGE_NAME}|$image_name|g")
    
    # 파일에 저장
    echo "$processed_content" > "$output_file"
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}파일이 생성되었습니다: $output_file${NC}"
        return 0
    else
        echo -e "\n${RED}파일 생성에 실패했습니다: $output_file${NC}"
        return 1
    fi
}

# 템플릿 파일 경로
TEMPLATES_DIR="templates"
DOCKER_COMPOSE_TEMPLATE="$TEMPLATES_DIR/docker-compose.yml.template"
DOCKERFILE_TEMPLATE="$TEMPLATES_DIR/Dockerfile.template"

echo -e "${GREEN}Docker 이미지 설정 스크립트${NC}"

# 기본값 설정 - 현재 쉘의 사용자 이름 가져오기
default_username="$(whoami)"
default_uid="$(id -u)"
default_gid="$(id -g)"
default_password="1234"
default_workdir="work/project"
default_image="my-ubuntu"

# 기본값 표시
echo -e "\n${YELLOW}다음 기본값으로 설정됩니다:${NC}"
echo -e "사용자 이름: ${GREEN}$default_username${NC}"
echo -e "사용자 UID: ${GREEN}$default_uid${NC}"
echo -e "사용자 GID: ${GREEN}$default_gid${NC}"
echo -e "비밀번호: ${GREEN}$default_password${NC}"
echo -e "작업 디렉토리: ${GREEN}$default_workdir${NC}"
echo -e "이미지 이름: ${GREEN}$default_image${NC}"

# 사용자 선택 입력 받기
echo -e "\n${BLUE}선택하세요:${NC}"
echo -e "${GREEN}y${NC} - 기본값으로 계속 진행"
echo -e "${YELLOW}n${NC} - 각 값을 수정"
echo -e "${RED}c${NC} - 취소"
read -p "선택 [Y/n/c]: " choice
choice=${choice:-y}

# 선택에 따라 진행
case $choice in
  y|Y)
    # 기본값 사용
    username=$default_username
    uid=$default_uid
    gid=$default_gid
    password=$default_password
    workdir=$default_workdir
    image_name=$default_image
    ;;
  n|N)
    # 각 값을 사용자 입력으로 받기
    read -p "사용자 이름 ($default_username): " username
    username=${username:-$default_username}

    read -p "사용자 UID ($default_uid): " uid
    uid=${uid:-$default_uid}

    read -p "사용자 GID ($default_gid): " gid
    gid=${gid:-$default_gid}

    read -p "사용자 비밀번호 ($default_password): " password
    password=${password:-$default_password}

    read -p "작업 디렉토리 이름 ($default_workdir): " workdir
    workdir=${workdir:-$default_workdir}
    
    read -p "이미지 이름 ($default_image): " image_name
    image_name=${image_name:-$default_image}
    ;;
  c|C)
    # 취소
    echo -e "${RED}설치가 취소되었습니다.${NC}"
    exit 0
    ;;
  *)
    # 잘못된 입력
    echo -e "${RED}잘못된 선택입니다. 설치가 취소되었습니다.${NC}"
    exit 1
    ;;
esac

# 최종 설정 정보 확인
echo -e "\n${YELLOW}최종 설정 정보:${NC}"
echo -e "사용자 이름: ${GREEN}$username${NC}"
echo -e "사용자 UID: ${GREEN}$uid${NC}"
echo -e "사용자 GID: ${GREEN}$gid${NC}"
echo -e "비밀번호: ${GREEN}$password${NC}"
echo -e "작업 디렉토리: ${GREEN}$workdir${NC}"
echo -e "이미지 이름: ${GREEN}$image_name${NC}"

# Dockerfile 템플릿을 사용하여 빌드
echo -e "\n${YELLOW}도커 이미지 빌드 중...${NC}"
docker build \
  --build-arg USERNAME="$username" \
  --build-arg USER_UID="$uid" \
  --build-arg USER_GID="$gid" \
  --build-arg USER_PASSWORD="$password" \
  --build-arg WORKDIR="$workdir" \
  -t "$image_name" \
  -f "$DOCKERFILE_TEMPLATE" .

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}도커 이미지가 성공적으로 빌드되었습니다!${NC}"
    echo -e "${BLUE}이미지 실행 명령어:${NC} docker run -it --name my-container $image_name"
    
    # 볼륨 마운트 옵션 추가 안내
    echo -e "\n${YELLOW}추가 팁:${NC}"
    echo -e "호스트와 작업 디렉토리를 공유하려면 다음 명령어를 사용하세요:"
    echo -e "${BLUE}docker run -it -v \$(pwd):/home/$username/$workdir --name my-container $image_name${NC}"
    
    # Docker Compose 예제 파일 생성
    echo -e "\n${YELLOW}Docker Compose 예제 파일을 생성할까요? (y/n):${NC}"
    read -p "선택 [Y/n]: " create_compose
    create_compose=${create_compose:-y}
    
    if [[ $create_compose == "y" || $create_compose == "Y" ]]; then
        process_template "$DOCKER_COMPOSE_TEMPLATE" "docker-compose.yml"
        
        # Docker Compose 명령어 안내
        if [ $? -eq 0 ]; then
            echo -e "${BLUE}다음 명령어로 컨테이너를 실행할 수 있습니다: docker-compose up -d${NC}"
        fi
    fi
else
    echo -e "\n${RED}도커 이미지 빌드 중 오류가 발생했습니다.${NC}"
fi

echo -e "\n${GREEN}설치가 완료되었습니다!${NC}" 