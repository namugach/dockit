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
    local commands="init start stop down connect status help version migrate"
    
    if [[ ${cur} == * ]] ; then
        # 자동완성 항목 생성
        # Generate completion items
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        
        # 설명 추가
        # Add descriptions
        local i
        for i in ${!COMPREPLY[@]}; do
            local cmd=${COMPREPLY[$i]}
            local desc=""
            
            # 각 명령어에 대한 설명 가져오기
            # Get description for each command
            case $cmd in
                init) desc="$(dockit_get_message MSG_COMPLETION_INIT)" ;;
                start) desc="$(dockit_get_message MSG_COMPLETION_START)" ;;
                stop) desc="$(dockit_get_message MSG_COMPLETION_STOP)" ;;
                down) desc="$(dockit_get_message MSG_COMPLETION_DOWN)" ;;
                connect) desc="$(dockit_get_message MSG_COMPLETION_CONNECT)" ;;
                status) desc="$(dockit_get_message MSG_COMPLETION_STATUS)" ;;
                help) desc="$(dockit_get_message MSG_COMPLETION_HELP)" ;;
                version) desc="$(dockit_get_message MSG_COMPLETION_VERSION)" ;;
                migrate) desc="$(dockit_get_message MSG_COMPLETION_MIGRATE)" ;;
            esac
            
            # 설명 포함한 자동완성 항목
            # Completion item with description
            COMPREPLY[$i]="$cmd -- $desc"
        done
    fi
}

# 자동완성 등록
# Register completion
complete -F _dockit_completion dockit
