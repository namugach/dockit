#!/bin/bash

# 시스템 설정 및 로직 처리 파일

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# 다른 디렉토리 경로 설정 (재정의 하지 않고 추가만 함)
CONFIG_DIR="$SCRIPT_DIR"
if [ -z "$MODULES_DIR" ]; then
    MODULES_DIR="$ROOT_DIR/src/modules"
fi
if [ -z "$TEMPLATES_DIR" ]; then
    TEMPLATES_DIR="$ROOT_DIR/src/templates"
fi

# 언어 설정 - 우선순위:
# 1. 환경 변수 LANGUAGE (사용자가 명시적으로 지정)
#    - local: 시스템 로케일 사용
#    - ko/en: 지정된 언어 사용
# 2. LANG 환경 변수에서 감지 (시스템 로케일)
# 3. settings.env 파일 설정 (persistent 설정)
# 4. 기본값 (local)

# 디버그 모드에서 초기 상태 출력
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

# 1. 먼저 환경 변수가 있는지 확인
if [ -n "$LANGUAGE" ]; then
    if [ "$LANGUAGE" = "local" ]; then
        # local인 경우 시스템 로케일 사용
        if [[ -n "$LANG" && "$LANG" == ko_* ]]; then
            DETECTED_LANGUAGE="ko"
        elif [[ -n "$LANG" && "$LANG" == en_* ]]; then
            DETECTED_LANGUAGE="en"
        else
            DETECTED_LANGUAGE="en"  # 기본값
        fi
        LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_FROM_SYS"
    else
        # 명시적으로 지정된 언어 사용
        DETECTED_LANGUAGE="$LANGUAGE"
        LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_FROM_ENV"
    fi
# 2. LANG 환경 변수에서 감지
elif [[ -n "$LANG" && "$LANG" == ko_* ]]; then
    DETECTED_LANGUAGE="ko"
    LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_FROM_SYS"
elif [[ -n "$LANG" && "$LANG" == en_* ]]; then
    DETECTED_LANGUAGE="en"
    LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_FROM_SYS"
else
    # 3&4. settings.env 파일이나 기본값은 나중에 처리
    DETECTED_LANGUAGE=""
    LANGUAGE_SOURCE=""
fi

# 3. settings.env 파일에서 설정 확인
if [ -z "$DETECTED_LANGUAGE" ] && [ -f "$SCRIPT_DIR/settings.env" ]; then
    CONFIG_LANGUAGE=$(grep LANGUAGE= "$SCRIPT_DIR/settings.env" | cut -d= -f2)
    if [ -n "$CONFIG_LANGUAGE" ]; then
        if [ "$CONFIG_LANGUAGE" = "local" ]; then
            # local인 경우 시스템 로케일 사용
            if [[ -n "$LANG" && "$LANG" == ko_* ]]; then
                DETECTED_LANGUAGE="ko"
            elif [[ -n "$LANG" && "$LANG" == en_* ]]; then
                DETECTED_LANGUAGE="en"
            else
                DETECTED_LANGUAGE="en"  # 기본값
            fi
            LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_FROM_SYS"
        else
            DETECTED_LANGUAGE="$CONFIG_LANGUAGE"
            LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_FROM_CONFIG"
        fi
    fi
fi

# 4. 기본값 설정 (local)
if [ -z "$DETECTED_LANGUAGE" ]; then
    if [[ -n "$LANG" && "$LANG" == ko_* ]]; then
        DETECTED_LANGUAGE="ko"
    elif [[ -n "$LANG" && "$LANG" == en_* ]]; then
        DETECTED_LANGUAGE="en"
    else
        DETECTED_LANGUAGE="en"  # 기본값
    fi
    LANGUAGE_SOURCE="$MSG_SYSTEM_LANG_DEFAULT"
fi

# 최종 언어 설정
LANGUAGE="$DETECTED_LANGUAGE"

# 디버그 모드에서 최종 언어 설정 출력
if [ "$DEBUG" = "true" ]; then
    echo "$MSG_SYSTEM_DEBUG_FINAL_LANG"
    printf "$MSG_SYSTEM_DEBUG_SELECTED_LANG\n" "$LANGUAGE"
    printf "$MSG_SYSTEM_DEBUG_LANG_SOURCE\n" "$LANGUAGE_SOURCE"
    echo "$MSG_SYSTEM_DEBUG_END"
fi

# 기본값 설정
TIMEZONE=${TIMEZONE:-UTC}
DEFAULT_PASSWORD=${DEFAULT_PASSWORD:-1234}
DEFAULT_WORKDIR=${DEFAULT_WORKDIR:-work/project}
DEBUG=${DEBUG:-false}

# 메시지 파일 로드
if [ -f "$SCRIPT_DIR/messages/load.sh" ]; then
    if [ "$DEBUG" = "true" ]; then
        printf "$MSG_SYSTEM_DEBUG_INTEGRATED_MSG\n" "$SCRIPT_DIR/messages/load.sh"
    fi
    source "$SCRIPT_DIR/messages/load.sh"
    load_messages "$LANGUAGE"
else
    if [ "$DEBUG" = "true" ]; then
        echo "$MSG_SYSTEM_DEBUG_LEGACY_MSG"
    fi
    # 기존 방식으로 메시지 파일 로드
    if [ -f "$SCRIPT_DIR/messages/${LANGUAGE}.sh" ]; then
        if [ "$DEBUG" = "true" ]; then
            printf "$MSG_SYSTEM_DEBUG_LOAD_MSG_FILE\n" "$SCRIPT_DIR/messages/${LANGUAGE}.sh"
        fi
        source "$SCRIPT_DIR/messages/${LANGUAGE}.sh"
    else
        printf "$MSG_SYSTEM_LANG_FILE_NOT_FOUND\n" "$LANGUAGE"
        source "$SCRIPT_DIR/messages/en.sh"
    fi
fi

# 메시지 출력 함수
print_message() {
    # 통합 메시지 시스템 사용 시
    if type get_message &>/dev/null; then
        get_message "$1"
    else
        # 기존 방식
        local message_key="$1"
        if [ -n "${!message_key}" ]; then
            echo "${!message_key}"
        else
            printf "$MSG_SYSTEM_MSG_NOT_FOUND\n" "$message_key"
        fi
    fi
}

# 언어별 기본 설정
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

# 베이스 이미지 설정
if [ -n "$CUSTOM_BASE_IMAGE" ]; then
    # 사용자 지정 이미지 사용
    BASE_IMAGE="$CUSTOM_BASE_IMAGE"
else
    # 자동 언어별 이미지 선택
    IFS='|' read -r BASE_IMAGE LOCALE_SETTING TIMEZONE <<< "$(get_language_settings "$LANGUAGE")"
fi

# 기존 템플릿 경로 재정의 (Dockerfile 사용)
DOCKERFILE_TEMPLATE="$TEMPLATES_DIR/Dockerfile"

# 디버그 정보 출력
if [ "$DEBUG" = "true" ]; then
    echo "$MSG_SYSTEM_DEBUG_SYS_INFO"
    printf "$MSG_SYSTEM_DEBUG_LANG\n" "$LANGUAGE"
    printf "$MSG_SYSTEM_DEBUG_BASE_IMG\n" "$BASE_IMAGE"
    printf "$MSG_SYSTEM_DEBUG_LOCALE\n" "$LOCALE_SETTING"
    printf "$MSG_SYSTEM_DEBUG_TIMEZONE\n" "$TIMEZONE"
    printf "$MSG_SYSTEM_DEBUG_WORKDIR\n" "$DEFAULT_WORKDIR"
    printf "$MSG_SYSTEM_DEBUG_TEMPLATE_DIR\n" "$TEMPLATES_DIR"
    printf "$MSG_SYSTEM_DEBUG_DOCKERFILE\n" "$DOCKERFILE_TEMPLATE"
    echo "$MSG_SYSTEM_DEBUG_INFO_END"
fi

# 템플릿 처리 함수 (기존 템플릿 처리 함수를 오버라이드)
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

# 설정 내보내기
export BASE_IMAGE
export LOCALE_SETTING
export DEFAULT_PASSWORD
export DEFAULT_WORKDIR
export LANGUAGE
export TIMEZONE
export ROOT_DIR
export DOCKERFILE_TEMPLATE 