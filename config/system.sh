#!/bin/bash

# System configuration file
# 시스템 설정 파일

# Set script directory
# 스크립트 디렉토리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# 다른 디렉토리 경로 설정 (재정의 하지 않고 추가만 함)
# Set other directory paths (only add, don't override)
CONFIG_DIR="$SCRIPT_DIR"
if [ -z "$MODULES_DIR" ]; then
    MODULES_DIR="$ROOT_DIR/src/modules"
fi
if [ -z "$TEMPLATES_DIR" ]; then
    TEMPLATES_DIR="$ROOT_DIR/src/templates"
fi

# Load common functions
# 공통 함수 로드
source "$SCRIPT_DIR/../src/modules/common.sh"

# 언어 설정 - 우선순위:
# Language settings - Priority:
# 1. 환경 변수 LANGUAGE (사용자가 명시적으로 지정)
# 1. LANGUAGE environment variable (explicitly specified by user)
#    - local: 시스템 로케일 사용
#    - local: Use system locale
#    - ko/en: 지정된 언어 사용
#    - ko/en: Use specified language
# 2. LANG 환경 변수에서 감지 (시스템 로케일)
# 2. Detect from LANG environment variable (system locale)
# 3. settings.env 파일 설정 (persistent 설정)
# 3. settings.env file settings (persistent settings)
# 4. 기본값 (local)
# 4. Default value (local)

# 디버그 모드에서 초기 상태 출력
# Output initial state in debug mode
if [ "$DEBUG" = "true" ]; then
    echo "$MSG_SYSTEM_DEBUG_INITIAL_LANG"
    printf "$MSG_SYSTEM_DEBUG_LANG_VAR\n" "${LANGUAGE:-없음}"
    printf "$MSG_SYSTEM_DEBUG_SYS_LANG\n" "${LANG:-없음}"
    if [ -f "$SCRIPT_DIR/settings.env" ]; then
        printf "$MSG_SYSTEM_DEBUG_CONFIG_LANG\n" "$(grep LANGUAGE= $SCRIPT_DIR/settings.env | cut -d= -f2)"
    else
        echo "$MSG_SYSTEM_DEBUG_NO_CONFIG"
    fi
    echo "$MSG_SYSTEM_DEBUG_END"
fi

# System locale detection function
# 시스템 로케일 감지 함수
detect_system_locale() {
    # Check if running in WSL environment
    # WSL 환경에서 실행 중인지 확인
    if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
        # Set Korean as default for WSL
        # WSL에서는 한국어를 기본값으로 설정
        echo "ko"
        return
    fi
    
    # 1. Check LC_ALL
    # 1. LC_ALL 확인
    if [[ -n "$LC_ALL" && "$LC_ALL" == ko_* ]]; then
        echo "ko"
        return
    fi
    
    # 2. Check LC_MESSAGES
    # 2. LC_MESSAGES 확인
    if [[ -n "$LC_MESSAGES" && "$LC_MESSAGES" == ko_* ]]; then
        echo "ko"
        return
    fi
    
    # 3. Check LANG
    # 3. LANG 확인
    if [[ -n "$LANG" && "$LANG" == ko_* ]]; then
        echo "ko"
        return
    fi
    
    # 4. Default to English
    # 4. 기본값은 영어
    echo "en"
}

# 1. First check environment variables
# 1. 먼저 환경 변수 확인
if [ -n "$LANGUAGE" ]; then
    if [ "$LANGUAGE" = "local" ]; then
        # Use system locale if LANGUAGE=local
        # LANGUAGE=local인 경우 시스템 로케일 사용
        DETECTED_LANGUAGE=$(detect_system_locale)
        LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_FROM_SYS"
    else
        # Use explicitly specified language
        # 명시적으로 지정된 언어 사용
        DETECTED_LANGUAGE="$LANGUAGE"
        LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_FROM_ENV"
    fi
# 2. Detect from LANG environment variable
# 2. LANG 환경 변수에서 감지
else
    DETECTED_LANGUAGE=$(detect_system_locale)
    LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_FROM_SYS"
fi

# 3. Check settings in settings.env file
# 3. settings.env 파일에서 설정 확인
if [ -z "$DETECTED_LANGUAGE" ] && [ -f "$SCRIPT_DIR/settings.env" ]; then
    CONFIG_LANGUAGE=$(grep LANGUAGE= "$SCRIPT_DIR/settings.env" | cut -d= -f2)
    if [ -n "$CONFIG_LANGUAGE" ]; then
        if [ "$CONFIG_LANGUAGE" = "local" ]; then
            # Use system locale if LANGUAGE=local
            # LANGUAGE=local인 경우 시스템 로케일 사용
            DETECTED_LANGUAGE=$(detect_system_locale)
            LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_FROM_SYS"
        else
            DETECTED_LANGUAGE="$CONFIG_LANGUAGE"
            LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_FROM_CONFIG"
        fi
    fi
fi

# 4. Set default value (local)
# 4. 기본값 설정 (local)
if [ -z "$DETECTED_LANGUAGE" ]; then
    DETECTED_LANGUAGE=$(detect_system_locale)
    LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_DEFAULT"
fi

# Set final language
# 최종 언어 설정
LANGUAGE="$DETECTED_LANGUAGE"

# Output final language settings in debug mode
# 디버그 모드에서 최종 언어 설정 출력
if [ "$DEBUG" = "true" ]; then
    echo "$MSG_SYSTEM_DEBUG_FINAL_LANG"
    printf "$MSG_SYSTEM_DEBUG_SELECTED_LANG\n" "$LANGUAGE"
    printf "$MSG_SYSTEM_DEBUG_LANG_SOURCE\n" "$LANGUAGE_SOURCE"
    echo "$MSG_SYSTEM_DEBUG_END"
fi

# Set default values
# 기본값 설정
TIMEZONE=${TIMEZONE:-UTC}
DEFAULT_PASSWORD=${DEFAULT_PASSWORD:-1234}
DEFAULT_WORKDIR=${DEFAULT_WORKDIR:-work/project}
DEBUG=${DEBUG:-false}

# Load message file
# 메시지 파일 로드
if [ -f "$SCRIPT_DIR/load.sh" ]; then
    if [ "$DEBUG" = "true" ]; then
        printf "$MSG_SYSTEM_DEBUG_INTEGRATED_MSG\n" "$SCRIPT_DIR/load.sh"
    fi
    source "$SCRIPT_DIR/load.sh"
    load_messages "$LANGUAGE"
else
    if [ "$DEBUG" = "true" ]; then
        echo "$MSG_SYSTEM_DEBUG_LEGACY_MSG"
    fi
    # 기존 방식으로 메시지 파일 로드
    # Load message file in legacy way
    if [ -f "$SCRIPT_DIR/${LANGUAGE}.sh" ]; then
        if [ "$DEBUG" = "true" ]; then
            printf "$MSG_SYSTEM_DEBUG_LOAD_MSG_FILE\n" "$SCRIPT_DIR/${LANGUAGE}.sh"
        fi
        source "$SCRIPT_DIR/${LANGUAGE}.sh"
    else
        printf "$MSG_SYSTEM_LANG_FILE_NOT_FOUND\n" "$LANGUAGE"
        source "$SCRIPT_DIR/en.sh"
    fi
fi

# 메시지 출력 함수
# Function to print messages
print_message() {
    # 통합 메시지 시스템 사용 시
    # When using integrated message system
    if type get_message &>/dev/null; then
        get_message "$1"
    else
        # 기존 방식
        # Legacy way
        local message_key="$1"
        if [ -n "${!message_key}" ]; then
            echo "${!message_key}"
        else
            printf "$MSG_SYSTEM_MSG_NOT_FOUND\n" "$message_key"
        fi
    fi
}

# 언어별 기본 설정
# Default settings by language
get_language_settings() {
    local lang="$1"
    case "$lang" in
        "ko")
            echo "namugach/ubuntu-basic:24.04-kor-deno|ko_KR.UTF-8|Asia/Seoul"
            ;;
        "en"|*)
            echo "ubuntu:24.04|en_US.UTF-8|UTC"
            ;;
    esac
}

# Set base image based on language
# 언어에 따른 베이스 이미지 설정
if [ "$LANGUAGE" = "ko" ]; then
    BASE_IMAGE=${CUSTOM_BASE_IMAGE:-namugach/ubuntu-basic:24.04-kor-deno}
    LOCALE_SETTING="ko_KR.UTF-8"
    TIMEZONE="Asia/Seoul"
else
    BASE_IMAGE=${CUSTOM_BASE_IMAGE:-ubuntu:24.04}
    LOCALE_SETTING="en_US.UTF-8"
    TIMEZONE="UTC"
fi

# 기존 템플릿 경로 재정의 (Dockerfile 사용)
# Override existing template path (use Dockerfile)
DOCKERFILE_TEMPLATE="$TEMPLATES_DIR/Dockerfile"

# Export variables
# 변수 내보내기
export LANGUAGE
export BASE_IMAGE
export LOCALE_SETTING
export TIMEZONE
export DEFAULT_PASSWORD
export DEFAULT_WORKDIR
export DEBUG

# Output system configuration in debug mode
# 디버그 모드에서 시스템 설정 출력
if [ "$DEBUG" = "true" ]; then
    echo "$MSG_SYSTEM_DEBUG_SYS_INFO"
    printf "$MSG_SYSTEM_DEBUG_LANG\n" "$LANGUAGE"
    printf "$MSG_SYSTEM_DEBUG_BASE_IMAGE\n" "$BASE_IMAGE"
    printf "$MSG_SYSTEM_DEBUG_LOCALE\n" "$LOCALE_SETTING"
    printf "$MSG_SYSTEM_DEBUG_TIMEZONE\n" "$TIMEZONE"
    printf "$MSG_SYSTEM_DEBUG_WORKDIR\n" "$DEFAULT_WORKDIR"
    printf "$MSG_SYSTEM_DEBUG_TEMPLATE_DIR\n" "$TEMPLATES_DIR"
    printf "$MSG_SYSTEM_DEBUG_DOCKERFILE\n" "$DOCKERFILE_TEMPLATE"
    echo "$MSG_SYSTEM_DEBUG_END"
fi

# 템플릿 처리 함수 (기존 템플릿 처리 함수를 오버라이드)
# Template processing function (override existing template processing function)
process_template_with_base_image() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        printf "$MSG_SYSTEM_TEMPLATE_NOT_FOUND\n" "$template_file"
        return 1
    fi
    
    printf "$MSG_SYSTEM_TEMPLATE_PROCESSING\n" "$template_file" "$output_file"
    
    # 템플릿 파일 읽기
    local template_content=$(<"$template_file")
    
    # 첫 줄의 FROM 이미지를 BASE_IMAGE로 교체
    local processed_content=$(echo "$template_content" | sed "1s|^FROM .*|FROM $BASE_IMAGE|")
    
    # 파일에 저장
    echo "$processed_content" > "$output_file"
    
    if [ $? -eq 0 ]; then
        printf "$MSG_SYSTEM_FILE_CREATED\n" "$output_file"
        return 0
    else
        printf "$MSG_SYSTEM_FILE_CREATE_FAILED\n" "$output_file"
        return 1
    fi
} 