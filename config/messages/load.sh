#!/bin/bash

# 메시지 로딩 시스템
# LANGUAGE 환경 변수에 따라 해당 언어의 메시지 파일을 로드합니다.

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 함수: 메시지 로드
load_messages() {
    # LANGUAGE가 설정되어 있지 않으면 기본값 ko 사용
    local lang="${LANGUAGE:-ko}"
    local message_file="$SCRIPT_DIR/${lang}.sh"
    
    # 디버그 모드라면 로딩 정보 출력
    if [ "$DEBUG" = "true" ]; then
        printf "$MSG_SYSTEM_DEBUG_LOAD_MSG_FILE\n" "$message_file"
    fi
    
    # 해당 언어 메시지 파일 로드
    if [ -f "$message_file" ]; then
        source "$message_file"
        export CURRENT_LANGUAGE="$lang"
        return 0
    else
        printf "$MSG_SYSTEM_LANG_FILE_NOT_FOUND\n" "$lang"
        return 1
    fi
}

# 메시지 출력 함수
get_message() {
    local message_key="$1"
    if [ -n "${!message_key}" ]; then
        echo "${!message_key}"
    else
        printf "$MSG_SYSTEM_MSG_NOT_FOUND\n" "$message_key"
    fi
}

# 직접 실행 시 메시지 로드
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    load_messages
fi 