# Bash completion for dockit command
# Bash에서 dockit 명령어 자동완성

# 메시지를 가져오는 함수
# Function to get messages
_dockit_get_message() {
    local message_key="$1"
    local debug=false  # 디버깅을 켜려면 true로 설정
    
    # 디버그 출력 함수
    _debug() {
        if [ "$debug" = "true" ]; then
            echo "DEBUG: $1" >&2
        fi
    }
    
    # 메시지 파일 로드 시도
    # Try to load message file
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local install_dir="$HOME/.local/share/dockit"
    local dev_dir="$script_dir/.."
    
    # 설치된 경로와 개발 경로 모두 시도
    local msg_locations=("$install_dir/config/messages" "$dev_dir/config/messages")
    local message_file=""
    local lang_file=""
    
    _debug "Checking for message files..."
    
    # 영어 메시지 파일 찾기
    for loc in "${msg_locations[@]}"; do
        if [ -f "$loc/en.sh" ]; then
            message_file="$loc/en.sh"
            _debug "Found English message file: $message_file"
            break
        fi
    done
    
    # 영어 메시지 파일을 찾지 못했으면 종료
    if [ -z "$message_file" ]; then
        _debug "ERROR: English message file not found"
        echo "$message_key"
        return 1
    fi
    
    # 언어 설정 확인
    # Check language settings
    for loc in "${msg_locations[@]}"; do
        if [ -f "$loc/../settings.env" ]; then
            _debug "Found settings.env file: $loc/../settings.env"
            source "$loc/../settings.env"
            _debug "LANGUAGE from settings: $LANGUAGE"
            
            if [ -n "$LANGUAGE" ] && [ -f "$loc/${LANGUAGE}.sh" ]; then
                lang_file="$loc/${LANGUAGE}.sh"
                _debug "Using language file from settings: $lang_file"
                break
            fi
        fi
    done
    
    # 시스템 환경에서 언어 확인
    # Check language from system environment
    if [ -z "$lang_file" ]; then
        local sys_lang="${LANGUAGE:-${LANG:-en}}"
        sys_lang="${sys_lang%%.*}"
        sys_lang="${sys_lang%%_*}"
        _debug "System language: $sys_lang"
        
        for loc in "${msg_locations[@]}"; do
            if [ -f "$loc/${sys_lang}.sh" ]; then
                lang_file="$loc/${sys_lang}.sh"
                _debug "Using language file from system environment: $lang_file"
                break
            else
                _debug "Language file for $sys_lang not found in $loc"
            fi
        done
    fi
    
    # 언어 파일이 없으면 영어 사용
    # Use English if no language file found
    if [ -z "$lang_file" ]; then
        lang_file="$message_file"
        _debug "No language file found, using default: $lang_file"
    fi
    
    # 메시지 파일 존재 확인
    if [ ! -f "$lang_file" ]; then
        _debug "ERROR: Language file does not exist: $lang_file"
        echo "$message_key"
        return 1
    fi
    
    # 메시지 파일 로드
    # Load message file
    _debug "Loading message file: $lang_file"
    source "$lang_file"
    
    # 메시지 키가 있는지 확인
    # Check if message key exists
    local msg_val=""
    eval "msg_val=\${$message_key}"
    
    if [ -n "$msg_val" ]; then
        _debug "Message key found: $message_key = $msg_val"
        echo "$msg_val"
        return 0
    else
        _debug "Message key not found: $message_key"
    fi
    
    # 메시지 키가 없으면 키 자체를 반환
    # Return the key itself if message not found
    _debug "Returning key as fallback: $message_key"
    echo "$message_key"
}

_dockit_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # 명령어 정의 (다국어 설명 포함)
    local cmd_init="init:$(_dockit_get_message MSG_COMPLETION_INIT)"
    local cmd_start="start:$(_dockit_get_message MSG_COMPLETION_START)"
    local cmd_stop="stop:$(_dockit_get_message MSG_COMPLETION_STOP)"
    local cmd_down="down:$(_dockit_get_message MSG_COMPLETION_DOWN)"
    local cmd_connect="connect:$(_dockit_get_message MSG_COMPLETION_CONNECT)"
    local cmd_status="status:$(_dockit_get_message MSG_COMPLETION_STATUS)"
    local cmd_help="help:$(_dockit_get_message MSG_COMPLETION_HELP)"
    local cmd_version="version:$(_dockit_get_message MSG_COMPLETION_VERSION)"
    
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
                init) desc="$(_dockit_get_message MSG_COMPLETION_INIT)" ;;
                start) desc="$(_dockit_get_message MSG_COMPLETION_START)" ;;
                stop) desc="$(_dockit_get_message MSG_COMPLETION_STOP)" ;;
                down) desc="$(_dockit_get_message MSG_COMPLETION_DOWN)" ;;
                connect) desc="$(_dockit_get_message MSG_COMPLETION_CONNECT)" ;;
                status) desc="$(_dockit_get_message MSG_COMPLETION_STATUS)" ;;
                help) desc="$(_dockit_get_message MSG_COMPLETION_HELP)" ;;
                version) desc="$(_dockit_get_message MSG_COMPLETION_VERSION)" ;;
            esac
            COMPREPLY[$i]="$cmd -- $desc"
        done
    fi
}
complete -F _dockit_completion dockit
