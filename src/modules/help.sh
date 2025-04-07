#!/bin/bash

# help 모듈 - 도움말 표시

# 공통 모듈 로드
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source "$SCRIPT_DIR/common.sh"

# 설정 시스템 로드 (존재하는 경우)
if [ -f "$PROJECT_ROOT/config/system.sh" ]; then
    source "$PROJECT_ROOT/config/system.sh"
fi

# 기본 메시지 파일 로드 (메시지 시스템이 없는 경우)
if ! type print_message &>/dev/null; then
    # 기본적으로 한국어 메시지 사용
    if [ -f "$PROJECT_ROOT/config/messages/ko.sh" ]; then
        source "$PROJECT_ROOT/config/messages/ko.sh"
    elif [ -f "$PROJECT_ROOT/config/messages/en.sh" ]; then
        source "$PROJECT_ROOT/config/messages/en.sh"
    fi
fi

# 도움말 출력 함수
show_help() {
    cat << EOF

===== $MSG_TITLE =====
$MSG_WELCOME

$MSG_HELP_USAGE

$MSG_HELP_COMMANDS
$MSG_HELP_INSTALL
$MSG_HELP_START
$MSG_HELP_STOP
$MSG_HELP_DOWN
$MSG_HELP_CONNECT
$MSG_HELP_STATUS
$MSG_HELP_HELP

$MSG_EXAMPLES_HEADER:
$MSG_EXAMPLE_INSTALL
$MSG_EXAMPLE_START
$MSG_EXAMPLE_STOP
$MSG_EXAMPLE_DOWN
$MSG_EXAMPLE_CONNECT

$MSG_DIRECT_MODULES_HEADER:
$MSG_DIRECT_MODULES_DESC
$MSG_EXAMPLE_MODULE_INSTALL
$MSG_EXAMPLE_MODULE_CONNECT

$MSG_CONFIG_FILES_HEADER:
$MSG_CONFIG_FILE_ENV
$MSG_CONFIG_FILE_COMPOSE
$MSG_CONFIG_FILE_LOG
$MSG_CONFIG_FILE_SETTINGS

=================================
EOF
}

# 메인 함수
help_main() {
    show_help
}

# 직접 실행 시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    help_main "$@"
fi 