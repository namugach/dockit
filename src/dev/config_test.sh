#!/bin/bash

# 설정 디버그 스크립트 
# Configuration debug script

# 스크립트 경로 설정
# Set script paths
setup_paths() {
    SCRIPT_DIR=$(readlink -f "$(dirname "$0")")
    PROJECT_ROOT=$(dirname "$(dirname "$SCRIPT_DIR")")
    export DOCKIT_ROOT="$PROJECT_ROOT"
    export CONFIG_DIR="$PROJECT_ROOT/config"
}

# 설정 파일 존재 여부 확인
# Check if configuration files exist
check_config_files() {
    echo "$MSG_SYSTEM_DEBUG_SYS_INFO"

    local files=("settings.env" "system.sh" "messages/ko.sh" "messages/en.sh")
    
    for file in "${files[@]}"; do
        if [ -f "$CONFIG_DIR/$file" ]; then
            printf "$MSG_SYSTEM_FILE_CREATED\n" "$file"
        else
            printf "$MSG_SYSTEM_FILE_CREATE_FAILED\n" "$file"
        fi
    done
}

# 시스템 설정 정보 출력
# Print system configuration info
print_system_info() {
    printf "$MSG_SYSTEM_DEBUG_SYS_INFO\n"
    printf "$MSG_SYSTEM_DEBUG_LANG\n" "$LANGUAGE"
    printf "$MSG_SYSTEM_DEBUG_BASE_IMG\n" "$BASE_IMAGE"
    printf "$MSG_SYSTEM_DEBUG_LOCALE\n" "$LOCALE_SETTING"
}

# 메시지 출력 테스트
# Test message printing
test_messages() {
    printf "$MSG_SYSTEM_DEBUG_MSG_TEST\n"
    printf "$MSG_SYSTEM_DEBUG_WELCOME\n" "$(print_message MSG_WELCOME)"
    printf "$MSG_SYSTEM_DEBUG_START\n" "$(print_message MSG_START_CONTAINER)"
}

# Dockerfile 템플릿 테스트
# Test Dockerfile template
test_dockerfile_template() {
    printf "$MSG_SYSTEM_DEBUG_TEMPLATE_TEST\n"
    if [ -f "$DOCKERFILE_TEMPLATE" ]; then
        printf "$MSG_SYSTEM_FILE_CREATED\n" "$DOCKERFILE_TEMPLATE"
        printf "$MSG_SYSTEM_DEBUG_TEMPLATE_PROCESS\n"
        
        local TEMP_DOCKERFILE="/tmp/Dockerfile.test"
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
}

# 메인 실행 함수
# Main execution function
main() {
    setup_paths
    check_config_files

    echo
    printf "$MSG_SYSTEM_DEBUG_LOAD_FROM_CONFIG\n" "설정 파일"
    echo

    if [ -f "$CONFIG_DIR/system.sh" ]; then
        export DEBUG=true
        source "$CONFIG_DIR/system.sh"
        
        echo
        print_system_info
        
        echo
        test_messages
        
        echo
        test_dockerfile_template
    else
        printf "$MSG_SYSTEM_FILE_CREATE_FAILED\n" "system.sh"
    fi

    echo
    echo "$MSG_SYSTEM_DEBUG_INFO_END"
}

# 스크립트 실행
# Execute script
main