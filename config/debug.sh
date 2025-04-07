#!/bin/bash

# 디버그 스크립트
# 설정 정보 확인용

# 현재 스크립트 경로 설정
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
DOCKIT_ROOT=$(dirname "$SCRIPT_DIR")

# 시스템 설정 파일 로드
if [ -f "$SCRIPT_DIR/system.sh" ]; then
    source "$SCRIPT_DIR/system.sh"
    echo "시스템 설정 파일 로드됨: $SCRIPT_DIR/system.sh"
else
    echo "오류: 시스템 설정 파일을 찾을 수 없습니다."
    exit 1
fi

# 현재 설정 정보 출력
echo "===== 현재 설정 정보 ====="
echo "언어: $LANGUAGE"
echo "BASE_IMAGE: $BASE_IMAGE"
echo "LOCALE_SETTING: $LOCALE_SETTING"
echo "DEFAULT_WORKDIR: $DEFAULT_WORKDIR"
echo "DEFAULT_PASSWORD: $DEFAULT_PASSWORD"
echo "TIMEZONE: $TIMEZONE"
echo "=========================="

# 메시지 출력 테스트
echo "===== 메시지 출력 테스트 ====="
echo "환영 메시지: $MSG_WELCOME"
echo "도움말 사용법: $MSG_HELP_USAGE"
echo "컨테이너 상태 메시지: $MSG_CONTAINER_RUNNING"
echo "확인 메시지: $MSG_CONFIRM_STOP"
echo "=========================="

# Dockerfile 템플릿 경로 테스트
TEMPLATE_PATH=$(get_dockerfile_template)
echo "===== Dockerfile 템플릿 ====="
echo "선택된 템플릿 경로: $TEMPLATE_PATH"
if [ -f "$TEMPLATE_PATH" ]; then
    echo "템플릿 파일이 존재합니다."
else
    echo "템플릿 파일이 존재하지 않습니다."
fi
echo "=========================="

echo "디버그 테스트 완료!" 