#!/bin/bash

# 메시지 로딩 시스템
# 언어에 따라 적절한 메시지 파일을 로드합니다.

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 함수: 메시지 로드
load_messages() {
    local lang="${1:-$LANGUAGE}"
    
    # 언어가 지정되지 않은 경우 기본값 (한국어)
    if [ -z "$lang" ]; then
        lang="ko"
    fi
    
    # 디버그 모드라면 로딩 정보 출력
    if [ "$DEBUG" = "true" ]; then
        echo "메시지 파일 로드 중: $lang"
    fi
    
    # 해당 언어 메시지 파일 로드
    if [ -f "$SCRIPT_DIR/${lang}.sh" ]; then
        source "$SCRIPT_DIR/${lang}.sh"
        export CURRENT_LANGUAGE="$lang"
        return 0
    else
        # 파일이 없으면 영어로 폴백
        if [ "$lang" != "en" ] && [ -f "$SCRIPT_DIR/en.sh" ]; then
            echo "경고: 언어 '$lang'에 대한 메시지 파일을 찾을 수 없습니다. 영어를 사용합니다."
            source "$SCRIPT_DIR/en.sh"
            export CURRENT_LANGUAGE="en"
            return 1
        elif [ -f "$SCRIPT_DIR/ko.sh" ]; then
            echo "경고: 영어 메시지 파일을 찾을 수 없습니다. 한국어를 사용합니다."
            source "$SCRIPT_DIR/ko.sh"
            export CURRENT_LANGUAGE="ko"
            return 1
        else
            echo "오류: 메시지 파일을 찾을 수 없습니다."
            return 2
        fi
    fi
}

# 메시지 출력 함수
get_message() {
    local message_key="$1"
    if [ -n "${!message_key}" ]; then
        echo "${!message_key}"
    else
        echo "메시지를 찾을 수 없음: $message_key"
    fi
}

# 직접 실행 시 메시지 로드
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    load_messages "$1"
fi 