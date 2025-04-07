#!/bin/bash

# 시스템 설정 및 로직 처리 파일

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# 다른 디렉토리 경로 설정 (재정의 하지 않고 추가만 함)
CONFIG_DIR="$SCRIPT_DIR"
if [ -z "$MODULES_DIR" ]; then
    MODULES_DIR="$ROOT_DIR/src/modules"
fi
if [ -z "$TEMPLATES_DIR" ]; then
    TEMPLATES_DIR="$ROOT_DIR/src/templates"
fi

# 기본 설정 파일 로드
if [ -f "$SCRIPT_DIR/settings.env" ]; then
    set -a
    source "$SCRIPT_DIR/settings.env"
    set +a
else
    echo "설정 파일이 없습니다: $SCRIPT_DIR/settings.env"
    exit 1
fi

# 기본값 설정
LANGUAGE="${LANGUAGE:-ko}"
TIMEZONE="${TIMEZONE:-Asia/Seoul}"
DEFAULT_PASSWORD="${DEFAULT_PASSWORD:-1234}"
DEFAULT_WORKDIR="${DEFAULT_WORKDIR:-work/project}"
DEBUG="${DEBUG:-false}"

# 메시지 파일 로드
if [ -f "$SCRIPT_DIR/messages/${LANGUAGE}.sh" ]; then
    source "$SCRIPT_DIR/messages/${LANGUAGE}.sh"
else
    echo "언어 파일을 찾을 수 없습니다: $LANGUAGE. 영어로 대체합니다."
    source "$SCRIPT_DIR/messages/en.sh"
fi

# 베이스 이미지 설정
if [ -n "$CUSTOM_BASE_IMAGE" ]; then
    # 사용자 지정 이미지 사용
    BASE_IMAGE="$CUSTOM_BASE_IMAGE"
else
    # 자동 언어별 이미지 선택
    if [ "$LANGUAGE" = "ko" ]; then
        BASE_IMAGE="namugach/ubuntu-basic:24.04-kor-deno"
        LOCALE_SETTING="ko_KR.UTF-8"
    elif [ "$LANGUAGE" = "en" ]; then
        BASE_IMAGE="ubuntu:24.04"
        LOCALE_SETTING="en_US.UTF-8"
    else
        BASE_IMAGE="ubuntu:24.04"
        LOCALE_SETTING="en_US.UTF-8"
    fi
fi

# 기존 템플릿 경로 재정의 (Dockerfile 사용)
DOCKERFILE_TEMPLATE="$TEMPLATES_DIR/Dockerfile"

# 디버그 정보 출력
if [ "$DEBUG" = "true" ]; then
    echo "===== 시스템 설정 정보 ====="
    echo "언어: $LANGUAGE"
    echo "베이스 이미지: $BASE_IMAGE"
    echo "로케일: $LOCALE_SETTING"
    echo "시간대: $TIMEZONE"
    echo "작업 디렉토리: $DEFAULT_WORKDIR"
    echo "템플릿 디렉토리: $TEMPLATES_DIR"
    echo "Dockerfile 템플릿: $DOCKERFILE_TEMPLATE"
    echo "=========================="
fi

# 메시지 출력 함수
print_message() {
    local msg_var="$1"
    if [ -n "${!msg_var}" ]; then
        echo "${!msg_var}"
    else
        echo "메시지가 정의되지 않았습니다: $msg_var"
    fi
}

# 템플릿 처리 함수 (기존 템플릿 처리 함수를 오버라이드)
process_template_with_base_image() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        echo "템플릿 파일을 찾을 수 없습니다: $template_file"
        return 1
    fi
    
    echo "템플릿 처리 중: $template_file -> $output_file"
    
    # 템플릿 파일 읽기
    local template_content=$(<"$template_file")
    
    # 첫 줄의 FROM 이미지를 BASE_IMAGE로 교체
    local processed_content=$(echo "$template_content" | sed "1s|^FROM .*|FROM $BASE_IMAGE|")
    
    # 파일에 저장
    echo "$processed_content" > "$output_file"
    
    if [ $? -eq 0 ]; then
        echo "파일이 생성되었습니다: $output_file"
        return 0
    else
        echo "파일 생성에 실패했습니다: $output_file"
        return 1
    fi
}

# 설정 내보내기
export BASE_IMAGE
export LOCALE_SETTING
export DEFAULT_PASSWORD
export DEFAULT_WORKDIR
export LANGUAGE
export TIMEZONE
export ROOT_DIR
export DOCKERFILE_TEMPLATE 