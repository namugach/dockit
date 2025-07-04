#compdef dockit

# ZSH completion for dockit command
# ZSH에서 dockit 명령어 자동완성

# 공통 스크립트 로드
# Load common script
SCRIPT_DIR="${0:A:h}"

# 설치된 위치와 현재 위치 모두 시도
# Try both installed and current locations
if [ -f "$SCRIPT_DIR/completion-common.sh" ]; then
    source "$SCRIPT_DIR/completion-common.sh"
elif [ -f "${HOME}/.local/share/zsh/site-functions/completion-common.sh" ]; then
    source "${HOME}/.local/share/zsh/site-functions/completion-common.sh"
else
    echo "Warning: Could not find completion-common.sh" >&2
    return 1
fi

# ZSH용 메시지 가져오기 함수
# Get message function for ZSH
dockit_get_message() {
    _dockit_get_message "$1" "true"
}

# ZSH 자동완성 함수
# ZSH completion function
_dockit() {
    local -a commands
    local -a start_options
    local -a stop_options
    
    # 특별한 하위 명령어 자동완성 처리
    # Handle special subcommand completion
    if (( CURRENT == 3 )); then
        case ${words[2]} in
            start)
                start_options=(
                    "this:$(dockit_get_message MSG_START_USAGE_THIS)"
                    "all:$(dockit_get_message MSG_START_USAGE_ALL)"
                )
                _describe 'start_option' start_options
                return 0
                ;;
            stop)
                stop_options=(
                    "this:$(dockit_get_message MSG_STOP_USAGE_THIS)"
                    "all:$(dockit_get_message MSG_STOP_USAGE_ALL)"
                )
                _describe 'stop_option' stop_options
                return 0
                ;;
            up)
                up_options=(
                    "this:$(dockit_get_message MSG_UP_USAGE_THIS)"
                    "all:$(dockit_get_message MSG_UP_USAGE_ALL)"
                )
                _describe 'up_option' up_options
                return 0
                ;;
            down)
                down_options=(
                    "this:$(dockit_get_message MSG_DOWN_USAGE_THIS)"
                    "all:$(dockit_get_message MSG_DOWN_USAGE_ALL)"
                )
                _describe 'down_option' down_options
                return 0
                ;;
            connect)
                connect_options=(
                    "this:$(dockit_get_message MSG_CONNECT_USAGE_THIS)"
                )
                _describe 'connect_option' connect_options
                return 0
                ;;
            build)
                build_options=(
                    "this:$(dockit_get_message MSG_BUILD_USAGE_THIS)"
                    "all:$(dockit_get_message MSG_BUILD_USAGE_ALL)"
                    "--no-cache:$(dockit_get_message MSG_BUILD_OPTION_NO_CACHE)"
                )
                _describe 'build_option' build_options
                return 0
                ;;
            image)
                image_options=(
                    "list:$(dockit_get_message MSG_IMAGE_COMPLETION_LIST)"
                    "ls:$(dockit_get_message MSG_IMAGE_COMPLETION_LIST)"
                    "remove:$(dockit_get_message MSG_IMAGE_COMPLETION_REMOVE)"
                    "prune:$(dockit_get_message MSG_IMAGE_COMPLETION_PRUNE)"
                    "clean:$(dockit_get_message MSG_IMAGE_COMPLETION_CLEAN)"
                )
                _describe 'image_option' image_options
                return 0
                ;;
            base)
                base_options=(
                    "list:$(dockit_get_message MSG_BASE_COMPLETION_LIST)"
                    "ls:$(dockit_get_message MSG_BASE_COMPLETION_LIST)"
                    "set:$(dockit_get_message MSG_BASE_COMPLETION_SET)"
                    "add:$(dockit_get_message MSG_BASE_COMPLETION_ADD)"
                    "remove:$(dockit_get_message MSG_BASE_COMPLETION_REMOVE)"
                    "rm:$(dockit_get_message MSG_BASE_COMPLETION_REMOVE)"
                    "validate:$(dockit_get_message MSG_BASE_COMPLETION_VALIDATE)"
                    "check:$(dockit_get_message MSG_BASE_COMPLETION_VALIDATE)"
                    "reset:$(dockit_get_message MSG_BASE_COMPLETION_RESET)"
                )
                _describe 'base_option' base_options
                return 0
                ;;
        esac
        return 0
    fi
    
    # 첫 번째 인자만 자동완성 처리 (두 번째 단어 입력 중일 때만)
    # Only handle completion for the first argument (only when entering the second word)
    if (( CURRENT > 2 )); then
        return 0
    fi
    
    # 사용 가능한 명령어와 설명 정의
    # Define available commands and descriptions
    commands=(
        "init:$(dockit_get_message MSG_COMPLETION_INIT)"
        "start:$(dockit_get_message MSG_COMPLETION_START)"
        "build:$(dockit_get_message MSG_COMPLETION_BUILD)"
        "up:$(dockit_get_message MSG_COMPLETION_UP)"
        "stop:$(dockit_get_message MSG_COMPLETION_STOP)"
        "down:$(dockit_get_message MSG_COMPLETION_DOWN)"
        "connect:$(dockit_get_message MSG_COMPLETION_CONNECT)"
        "status:$(dockit_get_message MSG_COMPLETION_STATUS)"
        "help:$(dockit_get_message MSG_COMPLETION_HELP)"
        "version:$(dockit_get_message MSG_COMPLETION_VERSION)"
        "migrate:$(dockit_get_message MSG_COMPLETION_MIGRATE)"
        "setup:$(dockit_get_message MSG_COMPLETION_SETUP)"
        "run:$(dockit_get_message MSG_COMPLETION_RUN)"
        "ps:$(dockit_get_message MSG_COMPLETION_PS)"
        "list:$(dockit_get_message MSG_COMPLETION_LIST)"
        "ls:$(dockit_get_message MSG_COMPLETION_LIST)"
        "image:$(dockit_get_message MSG_COMPLETION_IMAGE)"
        "base:$(dockit_get_message MSG_COMPLETION_BASE)"
    )
    
    # 자동완성 설명 표시
    # Display completion descriptions
    _describe 'command' commands
}

# 자동완성 시스템 초기화 확인
# Ensure the completion system is initialized
(( $+functions[compdef] )) || autoload -Uz compinit && compinit

# 자동완성 함수 등록
# Register the completion function
compdef _dockit dockit
