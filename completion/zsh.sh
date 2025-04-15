#compdef dockit

# ZSH completion for dockit command
# ZSH에서 dockit 명령어 자동완성

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
    local script_dir="${0:A:h}"
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
    
    # 메시지 키가 있는지 확인 (ZSH 방식)
    if [ -n "${(P)message_key}" ]; then
        local msg_val="${(P)message_key}"
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

_dockit() {
    local -a commands
    commands=(
        "init:$(_dockit_get_message MSG_COMPLETION_INIT)"
        "start:$(_dockit_get_message MSG_COMPLETION_START)"
        "stop:$(_dockit_get_message MSG_COMPLETION_STOP)"
        "down:$(_dockit_get_message MSG_COMPLETION_DOWN)"
        "status:$(_dockit_get_message MSG_COMPLETION_STATUS)"
        "connect:$(_dockit_get_message MSG_COMPLETION_CONNECT)"
        "help:$(_dockit_get_message MSG_COMPLETION_HELP)"
        "version:$(_dockit_get_message MSG_COMPLETION_VERSION)"
    )
    _describe 'command' commands
}

# Ensure the completion system is initialized
# 자동완성 시스템이 초기화되었는지 확인
(( $+functions[compdef] )) || autoload -Uz compinit && compinit

# Register the completion function
# 자동완성 함수 등록
compdef _dockit dockit
