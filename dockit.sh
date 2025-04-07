#!/bin/bash

# dockit - Docker 개발 환경 관리 도구
# 모듈식 구조로 Docker 컨테이너 관리를 간소화합니다.

# 스크립트 경로 설정
SCRIPT_DIR=$(readlink -f "$(dirname "$0")")
export DOCKIT_ROOT="$SCRIPT_DIR"
export MODULES_DIR="$SCRIPT_DIR/src/modules"
export TEMPLATES_DIR="$SCRIPT_DIR/src/templates"

# 디버깅을 위한 로그 출력 제거
# echo "MODULES_DIR=$MODULES_DIR"

# 공통 모듈 로드
source "$MODULES_DIR/common.sh"

# 현재 디렉토리를 기억
ORIGINAL_PWD=$(pwd)

# 사용법 출력 함수
usage() {
    echo "사용법: $0 [install|start|stop|connect|status|help]"
    exit 1
}

# 인자 검사
if [ $# -lt 1 ]; then
    usage
fi

# 명령 인식
COMMAND="$1"
shift # 첫 번째 인자 제거

# 명령 처리
case "$COMMAND" in
    install)
        # 설치 및 초기 설정 실행
        "$SCRIPT_DIR/src/modules/install.sh" "$@"
        ;;
    start)
        # 컨테이너 시작
        "$SCRIPT_DIR/src/modules/start.sh" "$@"
        ;;
    stop)
        # 컨테이너 정지
        "$SCRIPT_DIR/src/modules/stop.sh" "$@"
        ;;
    connect)
        # 컨테이너 접속
        "$SCRIPT_DIR/src/modules/connect.sh" "$@"
        ;;
    status)
        # 컨테이너 상태 확인
        "$SCRIPT_DIR/src/modules/status.sh" "$@"
        ;;
    help)
        # 도움말 표시
        "$SCRIPT_DIR/src/modules/help.sh" "$@"
        ;;
    *)
        # 알 수 없는 명령
        echo "알 수 없는 명령: $COMMAND"
        usage
        ;;
esac

# 원래 디렉토리로 복귀
cd "$ORIGINAL_PWD"

exit 0