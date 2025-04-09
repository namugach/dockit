#!/bin/bash

# help 모듈 - 도움말 표시
# help module - Display help information

# 공통 모듈 로드
# Load common module
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 메시지 시스템 로드
# Load message system
if [ -f "$PROJECT_ROOT/config/messages/load.sh" ]; then
    source "$PROJECT_ROOT/config/messages/load.sh"
    load_messages
fi

# 도움말 출력 함수
# Function to display help
show_help() {
    cat << EOF

===== $MSG_TITLE =====
$MSG_WELCOME

$MSG_HELP_USAGE

$MSG_HELP_COMMANDS
$MSG_HELP_INIT
$MSG_HELP_START
$MSG_HELP_STOP
$MSG_HELP_DOWN
$MSG_HELP_CONNECT
$MSG_HELP_STATUS
$MSG_HELP_HELP

$MSG_EXAMPLES_HEADER:
$MSG_EXAMPLE_INIT
$MSG_EXAMPLE_START
$MSG_EXAMPLE_STOP
$MSG_EXAMPLE_DOWN
$MSG_EXAMPLE_CONNECT

$MSG_DIRECT_MODULES_HEADER:
$MSG_DIRECT_MODULES_DESC
$MSG_EXAMPLE_MODULE_INIT
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
# Main function
help_main() {
    show_help
}

# 직접 실행 시
# When executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    help_main "$@"
fi 