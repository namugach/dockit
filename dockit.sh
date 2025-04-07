#!/bin/bash

# dockit - Docker 개발 환경 관리 도구
# 모듈식 구조로 Docker 컨테이너 관리를 간소화합니다.

# 스크립트 경로 설정
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
MODULES_DIR="$SCRIPT_DIR/modules"

# 공통 모듈 로드
source "$MODULES_DIR/common.sh"

# 사용법 출력 함수
usage() {
    "$MODULES_DIR/help.sh"
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
        "$MODULES_DIR/install.sh" "$@"
        ;;
    start)
        # 컨테이너 시작
        "$MODULES_DIR/start.sh" "$@"
        ;;
    stop)
        # 컨테이너 정지
        "$MODULES_DIR/stop.sh" "$@"
        ;;
    connect)
        # 컨테이너 접속
        "$MODULES_DIR/connect.sh" "$@"
        ;;
    status)
        # 컨테이너 상태 확인
        "$MODULES_DIR/status.sh" "$@"
        ;;
    help)
        # 도움말 표시
        "$MODULES_DIR/help.sh" "$@"
        ;;
    *)
        # 알 수 없는 명령
        echo "알 수 없는 명령: $COMMAND"
        usage
        ;;
esac

exit 0 