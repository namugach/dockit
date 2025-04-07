#!/bin/bash

# dockit - Docker 개발 환경 관리 도구
# 모듈식 구조로 Docker 컨테이너 관리를 간소화합니다.

# 스크립트 경로 설정
SCRIPT_DIR=$(readlink -f "$(dirname "$0")")
export DOCKIT_ROOT="$SCRIPT_DIR"
export MODULES_DIR="$SCRIPT_DIR/src/modules"
export TEMPLATES_DIR="$SCRIPT_DIR/src/templates"
export CONFIG_DIR="$SCRIPT_DIR/config"

# 시스템 설정 파일 로드 (존재하는 경우)
if [ -f "$CONFIG_DIR/system.sh" ]; then
    # 디버깅을 위한 설정 표시
    if [ "$DEBUG" = "true" ]; then
        echo "시스템 설정 파일 로드: $CONFIG_DIR/system.sh"
    fi
    
    # 설정 파일 로드
    source "$CONFIG_DIR/system.sh"
fi

# 디버깅을 위한 경로 표시
if [ "$DEBUG" = "true" ]; then
    echo "MODULES_DIR=$MODULES_DIR"
    echo "TEMPLATES_DIR=$TEMPLATES_DIR"
    echo "CONFIG_DIR=$CONFIG_DIR"
fi

# 공통 모듈 로드
source "$MODULES_DIR/common.sh"

# 현재 디렉토리를 기억
ORIGINAL_PWD=$(pwd)

# 사용법 출력 함수
usage() {
    "$MODULES_DIR/help.sh"
    exit 0
}

# 인자 검사
if [ $# -lt 1 ]; then
    # 인자가 없으면 자동으로 help 실행
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

# 원래 디렉토리로 복귀
cd "$ORIGINAL_PWD"

exit 0