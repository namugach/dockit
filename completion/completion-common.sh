#!/bin/bash

# Common functions for shell completion
# 쉘 자동완성을 위한 공통 함수

# 디버그 모드 설정
# Set debug mode
_DOCKIT_DEBUG=false

# 디버그 메시지 출력 함수
# Debug message output function
_dockit_debug() {
    if [ "$_DOCKIT_DEBUG" = "true" ]; then
        echo "DEBUG: $1" >&2
    fi
}

# 메시지 파일 경로 찾기
# Find message file paths
_dockit_find_message_files() {
    _dockit_debug "Finding message files..."
    
    # 스크립트 디렉토리 결정
    # Determine script directory
    local script_dir=""
    if [ -n "$ZSH_VERSION" ]; then
        # ZSH에서 경로 확인
        script_dir="${0:A:h}"
    else
        # Bash에서 경로 확인
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi
    
    local install_dir="$HOME/.local/share/dockit"
    local dev_dir="$script_dir/.."
    
    # 설치된 경로와 개발 경로 모두 확인
    # Check both installed path and development path
    local msg_locations=("$install_dir/config/messages" "$dev_dir/config/messages")
    local en_message_file=""
    
    # 영어 메시지 파일 찾기 (기본 메시지 파일)
    # Find English message file (default message file)
    for loc in "${msg_locations[@]}"; do
        if [ -f "$loc/en.sh" ]; then
            en_message_file="$loc/en.sh"
            _dockit_debug "Found English message file: $en_message_file"
            break
        fi
    done
    
    echo "$en_message_file"
}

# 설정 파일에서 언어 설정 가져오기
# Get language setting from settings file
_dockit_get_language_from_settings() {
    local en_message_file="$1"
    local msg_dir="$(dirname "$en_message_file")"
    
    _dockit_debug "Checking for language in settings.env"
    
    if [ -f "$msg_dir/../settings.env" ]; then
        _dockit_debug "Found settings.env file: $msg_dir/../settings.env"
        source "$msg_dir/../settings.env"
        _dockit_debug "LANGUAGE from settings: $LANGUAGE"
        
        if [ -n "$LANGUAGE" ] && [ -f "$msg_dir/${LANGUAGE}.sh" ]; then
            _dockit_debug "Using language from settings: $LANGUAGE"
            echo "$msg_dir/${LANGUAGE}.sh"
            return 0
        fi
    fi
    
    # 설정 파일에서 언어를 찾지 못함
    # Language not found in settings
    return 1
}

# 시스템 환경에서 언어 설정 가져오기
# Get language setting from system environment
_dockit_get_language_from_system() {
    local en_message_file="$1"
    local msg_dir="$(dirname "$en_message_file")"
    
    _dockit_debug "Checking for language in system environment"
    
    local sys_lang="${LANGUAGE:-${LANG:-en}}"
    sys_lang="${sys_lang%%.*}"  # 인코딩 제거
    sys_lang="${sys_lang%%_*}"  # 지역 제거
    
    _dockit_debug "System language: $sys_lang"
    
    if [ -f "$msg_dir/${sys_lang}.sh" ]; then
        _dockit_debug "Using language from system: $sys_lang"
        echo "$msg_dir/${sys_lang}.sh"
        return 0
    fi
    
    # 시스템 환경에서 언어를 찾지 못함
    # Language not found in system environment
    return 1
}

# 메시지 파일에서 메시지 키 값 가져오기
# Get message key value from message file
_dockit_get_message_value() {
    local message_file="$1"
    local message_key="$2"
    local use_zsh="$3"  # ZSH용 변수 확장 사용 여부
    
    # 메시지 파일 로드
    # Load message file
    _dockit_debug "Loading message file: $message_file"
    source "$message_file"
    
    if [ "$use_zsh" = "true" ]; then
        # ZSH 스타일 변수 확장
        # ZSH style variable expansion
        if [ -n "${(P)message_key}" ]; then
            local msg_val="${(P)message_key}"
            _dockit_debug "Message found (ZSH): $message_key = $msg_val"
            echo "$msg_val"
            return 0
        fi
    else
        # Bash 스타일 변수 확장
        # Bash style variable expansion
        local msg_val=""
        eval "msg_val=\${$message_key}"
        
        if [ -n "$msg_val" ]; then
            _dockit_debug "Message found (Bash): $message_key = $msg_val"
            echo "$msg_val"
            return 0
        fi
    fi
    
    # 메시지 키를 찾지 못함
    # Message key not found
    _dockit_debug "Message key not found: $message_key"
    return 1
}

# 메시지 가져오기 메인 함수
# Main function to get message
_dockit_get_message() {
    local message_key="$1"
    local use_zsh="$2"  # ZSH 모드 여부
    
    # 영어 메시지 파일 찾기
    # Find English message file
    local en_message_file=$(_dockit_find_message_files)
    
    # 메시지 파일을 찾지 못하면 키 그대로 반환
    # Return key as is if message file not found
    if [ -z "$en_message_file" ]; then
        _dockit_debug "ERROR: English message file not found"
        echo "$message_key"
        return 1
    fi
    
    # 언어 설정에서 메시지 파일 결정
    # Determine message file from language settings
    local lang_file=""
    
    # 설정 파일에서 언어 확인
    # Check language from settings
    lang_file=$(_dockit_get_language_from_settings "$en_message_file")
    
    # 설정 파일에서 찾지 못하면 시스템 환경 확인
    # Check system environment if not found in settings
    if [ -z "$lang_file" ]; then
        lang_file=$(_dockit_get_language_from_system "$en_message_file")
    fi
    
    # 언어 파일을 찾지 못하면 영어 사용
    # Use English if language file not found
    if [ -z "$lang_file" ]; then
        _dockit_debug "No language file found, using default: $en_message_file"
        lang_file="$en_message_file"
    fi
    
    # 메시지 파일 존재 확인
    # Check if message file exists
    if [ ! -f "$lang_file" ]; then
        _dockit_debug "ERROR: Language file does not exist: $lang_file"
        echo "$message_key"
        return 1
    fi
    
    # 메시지 값 가져오기
    # Get message value
    local msg_val=$(_dockit_get_message_value "$lang_file" "$message_key" "$use_zsh")
    
    if [ -n "$msg_val" ]; then
        echo "$msg_val"
        return 0
    fi
    
    # 기본 영어 메시지 시도
    # Try default English message
    if [ "$lang_file" != "$en_message_file" ]; then
        _dockit_debug "Trying English message as fallback"
        msg_val=$(_dockit_get_message_value "$en_message_file" "$message_key" "$use_zsh")
        
        if [ -n "$msg_val" ]; then
            echo "$msg_val"
            return 0
        fi
    fi
    
    # 메시지를 찾지 못하면 키 그대로 반환
    # Return key as is if message not found
    _dockit_debug "Returning key as fallback: $message_key"
    echo "$message_key"
} 