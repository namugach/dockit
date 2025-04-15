# Bash completion for dockit command
# Bash에서 dockit 명령어 자동완성

# 메시지를 가져오는 함수
# Function to get messages
_dockit_get_message() {
    local message_key="$1"
    local default_text="$2"
    
    # 메시지 파일 로드 시도
    # Try to load message file
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    local message_file="$script_dir/../config/messages/en.sh"
    local lang_file=""
    
    # 언어 설정 확인
    # Check language settings
    if [ -f "$script_dir/../config/settings.env" ]; then
        source "$script_dir/../config/settings.env"
        if [ -n "$LANGUAGE" ] && [ -f "$script_dir/../config/messages/${LANGUAGE}.sh" ]; then
            lang_file="$script_dir/../config/messages/${LANGUAGE}.sh"
        fi
    fi
    
    # 시스템 환경에서 언어 확인
    # Check language from system environment
    if [ -z "$lang_file" ]; then
        local sys_lang="${LANGUAGE:-${LANG:-en}}"
        sys_lang="${sys_lang%%.*}"
        sys_lang="${sys_lang%%_*}"
        if [ -f "$script_dir/../config/messages/${sys_lang}.sh" ]; then
            lang_file="$script_dir/../config/messages/${sys_lang}.sh"
        fi
    fi
    
    # 언어 파일이 없으면 영어 사용
    # Use English if no language file found
    if [ -z "$lang_file" ]; then
        lang_file="$message_file"
    fi
    
    # 메시지 파일 로드
    # Load message file
    if [ -f "$lang_file" ]; then
        source "$lang_file"
        # 메시지 키가 있으면 사용, 없으면 기본 텍스트 사용
        # Use message key if exists, otherwise use default text
        if [ -n "${!message_key}" ]; then
            echo "${!message_key}"
            return 0
        fi
    fi
    
    # 메시지 키가 없으면 기본 텍스트 반환
    # Return default text if message key not found
    echo "$default_text"
}

_dockit_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # 명령어 정의 (다국어 설명 포함)
    local cmd_init="init:$(_dockit_get_message MSG_COMPLETION_INIT 'Initialize dockit project')"
    local cmd_start="start:$(_dockit_get_message MSG_COMPLETION_START 'Start container')"
    local cmd_stop="stop:$(_dockit_get_message MSG_COMPLETION_STOP 'Stop container')"
    local cmd_down="down:$(_dockit_get_message MSG_COMPLETION_DOWN 'Remove container completely')"
    local cmd_connect="connect:$(_dockit_get_message MSG_COMPLETION_CONNECT 'Connect to container')"
    local cmd_status="status:$(_dockit_get_message MSG_COMPLETION_STATUS 'Check container status')"
    local cmd_help="help:$(_dockit_get_message MSG_COMPLETION_HELP 'Display help information')"
    local cmd_version="version:$(_dockit_get_message MSG_COMPLETION_VERSION 'Display version information')"
    
    # 명령어 이름만 추출
    local commands="init start stop down connect status help version"
    
    if [[ ${cur} == * ]] ; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        # 설명을 표시하기 위한 코드
        local i
        for i in ${!COMPREPLY[@]}; do
            local cmd=${COMPREPLY[$i]}
            local desc=""
            case $cmd in
                init) desc="$(_dockit_get_message MSG_COMPLETION_INIT 'Initialize dockit project')" ;;
                start) desc="$(_dockit_get_message MSG_COMPLETION_START 'Start container')" ;;
                stop) desc="$(_dockit_get_message MSG_COMPLETION_STOP 'Stop container')" ;;
                down) desc="$(_dockit_get_message MSG_COMPLETION_DOWN 'Remove container completely')" ;;
                connect) desc="$(_dockit_get_message MSG_COMPLETION_CONNECT 'Connect to container')" ;;
                status) desc="$(_dockit_get_message MSG_COMPLETION_STATUS 'Check container status')" ;;
                help) desc="$(_dockit_get_message MSG_COMPLETION_HELP 'Display help information')" ;;
                version) desc="$(_dockit_get_message MSG_COMPLETION_VERSION 'Display version information')" ;;
            esac
            COMPREPLY[$i]="$cmd -- $desc"
        done
    fi
}
complete -F _dockit_completion dockit
