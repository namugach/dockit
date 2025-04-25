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
        "status:$(dockit_get_message MSG_COMPLETION_STATUS)"
        "connect:$(dockit_get_message MSG_COMPLETION_CONNECT)"
        "help:$(dockit_get_message MSG_COMPLETION_HELP)"
        "version:$(dockit_get_message MSG_COMPLETION_VERSION)"
        "migrate:$(dockit_get_message MSG_COMPLETION_MIGRATE)"
        "setup:$(dockit_get_message MSG_COMPLETION_SETUP)"
        "run:$(dockit_get_message MSG_COMPLETION_RUN)"
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
