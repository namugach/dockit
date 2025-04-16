#!/bin/bash

# Debug script for checking configuration information
# 설정 정보 확인을 위한 디버그 스크립트

# Setup script paths and directories
# 스크립트 경로 및 디렉토리 설정
setup_paths() {
    SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    PROJECT_ROOT=$(dirname "$(dirname "$SCRIPT_DIR")")
    CONFIG_DIR="$PROJECT_ROOT/config"
}

# Load system configuration file
# 시스템 설정 파일 로드
load_system_config() {
    if [ -f "$CONFIG_DIR/system.sh" ]; then
        source "$CONFIG_DIR/system.sh"
        printf "$MSG_SYSTEM_DEBUG_LOAD_FROM_CONFIG\n" "$CONFIG_DIR/system.sh"
    else
        printf "$MSG_SYSTEM_FILE_CREATE_FAILED\n" "$CONFIG_DIR/system.sh"
        exit 1
    fi
}

# Print current system configuration
# 현재 시스템 설정 정보 출력
print_system_config() {
    echo "$MSG_SYSTEM_DEBUG_SYS_INFO"
    printf "$MSG_SYSTEM_DEBUG_LANG\n" "$LANGUAGE"
    printf "$MSG_SYSTEM_DEBUG_BASE_IMG\n" "$BASE_IMAGE"
    printf "$MSG_SYSTEM_DEBUG_LOCALE\n" "$LOCALE_SETTING"
    printf "$MSG_SYSTEM_DEBUG_WORKDIR\n" "$DEFAULT_WORKDIR"
    printf "$MSG_SYSTEM_DEBUG_PASSWORD\n" "$DEFAULT_PASSWORD"
    printf "$MSG_SYSTEM_DEBUG_TIMEZONE\n" "$TIMEZONE"
    echo "$MSG_SYSTEM_DEBUG_INFO_END"
}

# Test message output functionality
# 메시지 출력 기능 테스트
test_messages() {
    echo "$MSG_SYSTEM_DEBUG_MSG_TEST"
    printf "$MSG_SYSTEM_DEBUG_WELCOME\n" "$MSG_WELCOME"
    printf "$MSG_SYSTEM_DEBUG_HELP\n" "$MSG_HELP_USAGE"
    printf "$MSG_SYSTEM_DEBUG_CONTAINER\n" "$MSG_CONTAINER_RUNNING"
    printf "$MSG_SYSTEM_DEBUG_CONFIRM\n" "$MSG_CONFIRM_STOP"
    echo "$MSG_SYSTEM_DEBUG_INFO_END"
}

# Test Dockerfile template path
# Dockerfile 템플릿 경로 테스트
test_dockerfile_template() {
    echo "$MSG_SYSTEM_DEBUG_TEMPLATE_TEST"
    printf "$MSG_SYSTEM_DEBUG_TEMPLATE_PATH\n" "$DOCKERFILE_TEMPLATE"
    if [ -f "$DOCKERFILE_TEMPLATE" ]; then
        printf "$MSG_SYSTEM_FILE_CREATED\n" "$DOCKERFILE_TEMPLATE"
    else
        printf "$MSG_SYSTEM_FILE_CREATE_FAILED\n" "$DOCKERFILE_TEMPLATE"
    fi
    echo "$MSG_SYSTEM_DEBUG_INFO_END"
}

# Main execution function
# 메인 실행 함수
main() {
    setup_paths
    load_system_config
    print_system_config
    test_messages
    test_dockerfile_template
    echo "$MSG_SYSTEM_DEBUG_COMPLETE"
}

# Execute main function
# 메인 함수 실행
main