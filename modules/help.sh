#!/bin/bash

# help 모듈 - 도움말 표시

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 도움말 표시 함수
show_help() {
    echo -e "\n${BLUE}===== Docker 개발 환경 도구 =====${NC}"
    echo -e "${GREEN}간편한 Docker 개발 환경 관리 도구${NC}"
    
    echo -e "\n${YELLOW}사용법:${NC}"
    echo -e "  ${BLUE}./docker-tools.sh${NC} ${GREEN}<명령>${NC} [옵션...]"
    
    echo -e "\n${YELLOW}사용 가능한 명령:${NC}"
    echo -e "  ${GREEN}install${NC}    Docker 개발 환경 설치 및 설정"
    echo -e "  ${GREEN}start${NC}      컨테이너 시작"
    echo -e "  ${GREEN}stop${NC}       컨테이너 정지"
    echo -e "  ${GREEN}connect${NC}    실행 중인 컨테이너에 접속"
    echo -e "  ${GREEN}status${NC}     컨테이너 상태 확인"
    echo -e "  ${GREEN}help${NC}       이 도움말 표시"
    
    echo -e "\n${YELLOW}예제:${NC}"
    echo -e "  ${BLUE}./docker-tools.sh install${NC}    # 초기 설치 및 설정"
    echo -e "  ${BLUE}./docker-tools.sh start${NC}      # 컨테이너 시작"
    echo -e "  ${BLUE}./docker-tools.sh connect${NC}    # 컨테이너 접속"
    
    echo -e "\n${YELLOW}직접 모듈 실행:${NC}"
    echo -e "  각 모듈은 직접 실행할 수도 있습니다:"
    echo -e "  ${BLUE}./modules/install.sh${NC}    # install 모듈 직접 실행"
    echo -e "  ${BLUE}./modules/connect.sh${NC}    # connect 모듈 직접 실행"
    
    echo -e "\n${YELLOW}설정 파일:${NC}"
    echo -e "  ${BLUE}.env${NC}    # 사용자 설정이 저장되는 파일"
    
    echo -e "\n${BLUE}=================================${NC}"
}

# 메인 함수
help_main() {
    show_help
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    help_main "$@"
fi 