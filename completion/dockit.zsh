#compdef dockit

# ZSH completion for dockit command
# ZSH에서 dockit 명령어 자동완성

# 메시지를 가져오는 함수
# Function to get messages
_dockit_get_message() {
    local message_key="$1"
    local default_text="$2"
    
    # 메시지 파일 로드 시도
    # Try to load message file
    local script_dir="${0:A:h}"
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
        if [ -n "${(P)message_key}" ]; then
            echo "${(P)message_key}"
            return 0
        fi
    fi
    
    # 메시지 키가 없으면 기본 텍스트 반환
    # Return default text if message key not found
    echo "$default_text"
}

_dockit() {
    local -a commands
    commands=(
        "init:$(_dockit_get_message MSG_COMPLETION_INIT 'Initialize dockit project')"
        "start:$(_dockit_get_message MSG_COMPLETION_START 'Start container')"
        "stop:$(_dockit_get_message MSG_COMPLETION_STOP 'Stop container')"
        "down:$(_dockit_get_message MSG_COMPLETION_DOWN 'Remove container completely')"
        "status:$(_dockit_get_message MSG_COMPLETION_STATUS 'Check container status')"
        "connect:$(_dockit_get_message MSG_COMPLETION_CONNECT 'Connect to container')"
        "help:$(_dockit_get_message MSG_COMPLETION_HELP 'Display help information')"
        "version:$(_dockit_get_message MSG_COMPLETION_VERSION 'Display version information')"
    )
    _describe 'command' commands
}

# Ensure the completion system is initialized
# 자동완성 시스템이 초기화되었는지 확인
(( $+functions[compdef] )) || autoload -Uz compinit && compinit

# Register the completion function
# 자동완성 함수 등록
compdef _dockit dockit
