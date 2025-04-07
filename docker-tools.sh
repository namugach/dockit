#!/bin/bash

# Docker 개발 환경 도구 - 메인 스크립트
# 버전: 1.0.0

# 기본 변수 설정
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
MODULES_DIR="$SCRIPT_DIR/modules"
VERSION="1.0.0"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 로그 초기화
touch "$SCRIPT_DIR/docker-tools.log"

# 모듈 실행 권한 확인 및 부여
check_modules_executable() {
    for module in "$MODULES_DIR"/*.sh; do
        if [ -f "$module" ] && [ ! -x "$module" ]; then
            chmod +x "$module"
        fi
    done
}

# 명령 처리
process_command() {
    local command="$1"
    shift
    
    if [ -z "$command" ]; then
        # 명령이 없으면 help 실행
        "$MODULES_DIR/help.sh"
        return 0
    fi
    
    case "$command" in
        install|start|stop|connect|status|help)
            # 모듈 파일 경로
            local module_file="$MODULES_DIR/$command.sh"
            
            # 모듈 존재 확인
            if [ -f "$module_file" ]; then
                # 모듈 실행
                "$module_file" "$@"
                return $?
            else
                echo -e "${RED}오류: 모듈을 찾을 수 없습니다: $module_file${NC}"
                return 1
            fi
            ;;
        version)
            # 버전 정보 표시
            echo -e "${GREEN}Docker 개발 환경 도구 버전 $VERSION${NC}"
            return 0
            ;;
        *)
            # 알 수 없는 명령
            echo -e "${RED}오류: 알 수 없는 명령입니다: $command${NC}"
            "$MODULES_DIR/help.sh"
            return 1
            ;;
    esac
}

# 메인 함수
main() {
    # 모듈 실행 권한 확인
    check_modules_executable
    
    # 명령 처리
    process_command "$@"
    return $?
}

# 스크립트 실행
main "$@"
exit $? 