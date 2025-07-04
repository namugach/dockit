# Bash completion for dockit command
# Bash에서 dockit 명령어 자동완성

# 공통 스크립트 로드
# Load common script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 설치된 위치와 현재 위치 모두 시도
# Try both installed and current locations
if [ -f "$SCRIPT_DIR/completion-common.sh" ]; then
    source "$SCRIPT_DIR/completion-common.sh"
elif [ -f "/etc/bash_completion.d/completion-common.sh" ]; then
    source "/etc/bash_completion.d/completion-common.sh"
else
    echo "Warning: Could not find completion-common.sh" >&2
    exit 1
fi

# Bash용 메시지 가져오기 함수
# Get message function for Bash
dockit_get_message() {
    _dockit_get_message "$1" "false"
}

# Bash 자동완성 함수
# Bash completion function
_dockit_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # 사용 가능한 명령어 목록
    # List of available commands
    local commands="init start build up stop down connect status help version migrate setup run ps list ls image base"
    
    # 첫 번째 인자만 자동완성 처리
    # Only handle completion for the first argument
    if [ "$COMP_CWORD" -eq 1 ]; then
        # 자동완성 항목 생성
        # Generate completion items
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        
        # 심플 모드
        # Simple mode
        return 0
        
        # 아래 코드는 현재 사용하지 않음 - 중복 출력 문제 해결을 위해
        # The code below is currently not used - to solve duplicate output issues
        if [ "${#COMPREPLY[@]}" -gt 1 ]; then
            echo "" >&2
            for cmd in "${COMPREPLY[@]}"; do
                local desc=""
                case $cmd in
                    init) desc="$(dockit_get_message MSG_COMPLETION_INIT)" ;;
                    start) desc="$(dockit_get_message MSG_COMPLETION_START)" ;;
                    build) desc="$(dockit_get_message MSG_COMPLETION_BUILD)" ;;
                    up) desc="$(dockit_get_message MSG_COMPLETION_UP)" ;;
                    stop) desc="$(dockit_get_message MSG_COMPLETION_STOP)" ;;
                    down) desc="$(dockit_get_message MSG_COMPLETION_DOWN)" ;;
                    connect) desc="$(dockit_get_message MSG_COMPLETION_CONNECT)" ;;
                    status) desc="$(dockit_get_message MSG_COMPLETION_STATUS)" ;;
                    help) desc="$(dockit_get_message MSG_COMPLETION_HELP)" ;;
                    version) desc="$(dockit_get_message MSG_COMPLETION_VERSION)" ;;
                    migrate) desc="$(dockit_get_message MSG_COMPLETION_MIGRATE)" ;;
                    setup) desc="$(dockit_get_message MSG_COMPLETION_SETUP)" ;;
                    run) desc="$(dockit_get_message MSG_COMPLETION_RUN)" ;;
                    ps) desc="$(dockit_get_message MSG_COMPLETION_PS)" ;;
                    list) desc="$(dockit_get_message MSG_COMPLETION_LIST)" ;;
                    ls) desc="$(dockit_get_message MSG_COMPLETION_LIST)" ;;
                    image) desc="$(dockit_get_message MSG_COMPLETION_IMAGE)" ;;
                    base) desc="$(dockit_get_message MSG_COMPLETION_BASE)" ;;
                esac
                
                if [ -n "$desc" ]; then
                    printf "\033[90m%-15s # %s\033[0m\n" "$cmd" "$desc" >&2
                fi
            done
            echo "" >&2
        fi
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "start" ]; then
        # start 명령어의 두 번째 인자 자동완성
        # Second argument completion for start command
        COMPREPLY=( $(compgen -W "this all" -- ${cur}) )
        return 0
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "stop" ]; then
        # stop 명령어의 두 번째 인자 자동완성
        # Second argument completion for stop command
        COMPREPLY=( $(compgen -W "this all" -- ${cur}) )
        return 0
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "up" ]; then
        # up 명령어의 두 번째 인자 자동완성
        # Second argument completion for up command
        COMPREPLY=( $(compgen -W "this all" -- ${cur}) )
        return 0
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "down" ]; then
        # down 명령어의 두 번째 인자 자동완성
        # Second argument completion for down command
        COMPREPLY=( $(compgen -W "this all" -- ${cur}) )
        return 0
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "connect" ]; then
        # connect 명령어의 두 번째 인자 자동완성
        # Second argument completion for connect command
        COMPREPLY=( $(compgen -W "this" -- ${cur}) )
        return 0
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "build" ]; then
        # build 명령어의 두 번째 인자 자동완성
        # Second argument completion for build command
        COMPREPLY=( $(compgen -W "this all --no-cache" -- ${cur}) )
        return 0
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "image" ]; then
        # image 명령어의 두 번째 인자 자동완성
        # Second argument completion for image command
        COMPREPLY=( $(compgen -W "list ls remove prune clean" -- ${cur}) )
        return 0
    elif [ "$COMP_CWORD" -eq 2 ] && [ "$prev" = "base" ]; then
        # base 명령어의 두 번째 인자 자동완성
        # Second argument completion for base command
        COMPREPLY=( $(compgen -W "list ls set add remove rm validate check reset" -- ${cur}) )
        return 0
    fi
}

# 자동완성 등록
# Register completion
complete -F _dockit_completion dockit
