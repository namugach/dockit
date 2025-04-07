#!/bin/bash

# 설정 디버그 스크립트 
# config 시스템이 제대로 작동하는지 테스트

# 스크립트 경로 설정
SCRIPT_DIR=$(readlink -f "$(dirname "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$SCRIPT_DIR")")
export DOCKIT_ROOT="$PROJECT_ROOT"
export CONFIG_DIR="$PROJECT_ROOT/config"

echo "$MSG_SYSTEM_DEBUG_SYS_INFO"

# 설정 파일이 존재하는지 확인
if [ -f "$CONFIG_DIR/settings.env" ]; then
    printf "$MSG_SYSTEM_FILE_CREATED\n" "settings.env"
else
    printf "$MSG_SYSTEM_FILE_CREATE_FAILED\n" "settings.env"
fi

if [ -f "$CONFIG_DIR/system.sh" ]; then
    printf "$MSG_SYSTEM_FILE_CREATED\n" "system.sh"
else
    printf "$MSG_SYSTEM_FILE_CREATE_FAILED\n" "system.sh"
fi

# 한국어 메시지 파일 확인
if [ -f "$CONFIG_DIR/messages/ko.sh" ]; then
    printf "$MSG_SYSTEM_FILE_CREATED\n" "ko.sh"
else
    printf "$MSG_SYSTEM_FILE_CREATE_FAILED\n" "ko.sh"
fi

# 영어 메시지 파일 확인
if [ -f "$CONFIG_DIR/messages/en.sh" ]; then
    printf "$MSG_SYSTEM_FILE_CREATED\n" "en.sh"
else
    printf "$MSG_SYSTEM_FILE_CREATE_FAILED\n" "en.sh"
fi

echo
printf "$MSG_SYSTEM_DEBUG_LOAD_FROM_CONFIG\n" "설정 파일"
echo

# 설정 파일 로드
if [ -f "$CONFIG_DIR/system.sh" ]; then
    # DEBUG 모드 활성화
    export DEBUG=true
    source "$CONFIG_DIR/system.sh"
    
    echo
    printf "$MSG_SYSTEM_DEBUG_SYS_INFO\n"
    printf "$MSG_SYSTEM_DEBUG_LANG\n" "$LANGUAGE"
    printf "$MSG_SYSTEM_DEBUG_BASE_IMG\n" "$BASE_IMAGE"
    printf "$MSG_SYSTEM_DEBUG_LOCALE\n" "$LOCALE_SETTING"
    
    # 메시지 출력 테스트
    echo
    printf "$MSG_SYSTEM_DEBUG_MSG_TEST\n"
    printf "$MSG_SYSTEM_DEBUG_WELCOME\n" "$(print_message MSG_WELCOME)"
    printf "$MSG_SYSTEM_DEBUG_START\n" "$(print_message MSG_START_CONTAINER)"
    
    # 템플릿 처리 테스트
    echo
    printf "$MSG_SYSTEM_DEBUG_TEMPLATE_TEST\n"
    if [ -f "$DOCKERFILE_TEMPLATE" ]; then
        printf "$MSG_SYSTEM_FILE_CREATED\n" "$DOCKERFILE_TEMPLATE"
        printf "$MSG_SYSTEM_DEBUG_TEMPLATE_PROCESS\n"
        
        # 임시 파일로 템플릿 처리 테스트
        TEMP_DOCKERFILE="/tmp/Dockerfile.test"
        if process_template_with_base_image "$DOCKERFILE_TEMPLATE" "$TEMP_DOCKERFILE"; then
            printf "$MSG_SYSTEM_DEBUG_TEMPLATE_SUCCESS\n"
            echo
            printf "$MSG_SYSTEM_DEBUG_TEMPLATE_PREVIEW\n"
            head -n 10 "$TEMP_DOCKERFILE"
        else
            printf "$MSG_SYSTEM_DEBUG_TEMPLATE_FAILED\n"
        fi
    else
        printf "$MSG_SYSTEM_FILE_CREATE_FAILED\n" "$DOCKERFILE_TEMPLATE"
    fi
else
    printf "$MSG_SYSTEM_FILE_CREATE_FAILED\n" "system.sh"
fi

echo
echo "$MSG_SYSTEM_DEBUG_INFO_END" 