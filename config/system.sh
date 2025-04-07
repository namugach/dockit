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
# 2. LANG 환경 변수에서 감지 (시스템 로케일)
# 3. settings.env 파일 설정 (persistent 설정)
# 4. 기본값 (ko)

# 디버그 모드에서 초기 상태 출력
if [ "$DEBUG" = "true" ]; then
    echo "===== 초기 언어 설정 상태 ====="
    echo "환경 변수 LANGUAGE: ${LANGUAGE:-없음}"
    echo "시스템 로케일 LANG: ${LANG:-없음}"
    if [ -f "$SCRIPT_DIR/settings.env" ]; then
        echo "설정 파일 언어: $(grep LANGUAGE= $SCRIPT_DIR/settings.env | cut -d= -f2)"
    else
        echo "설정 파일 언어: 파일 없음"
    fi
    echo "================================="
fi

# 1. 먼저 환경 변수가 있는지 확인
if [ -n "$LANGUAGE" ]; then
    DETECTED_LANGUAGE="$LANGUAGE"
    LANGUAGE_SOURCE="환경 변수 LANGUAGE"
# 2. LANG 환경 변수에서 감지
elif [[ -n "$LANG" && "$LANG" == en_* ]]; then
    DETECTED_LANGUAGE="en"
    LANGUAGE_SOURCE="시스템 로케일 LANG"
elif [[ -n "$LANG" && "$LANG" == ko_* ]]; then
    DETECTED_LANGUAGE="ko"
    LANGUAGE_SOURCE="시스템 로케일 LANG"
else
    # 3&4. settings.env 파일이나 기본값은 나중에 처리
    DETECTED_LANGUAGE=""
    LANGUAGE_SOURCE=""
fi

# 기본 설정 파일 로드
if [ -f "$SCRIPT_DIR/settings.env" ]; then
    # 설정 파일의 내용 백업
    SETTINGS_CONTENT=$(cat "$SCRIPT_DIR/settings.env")
    
    # 설정 파일에서 LANGUAGE 값을 추출
    SETTINGS_LANGUAGE=$(echo "$SETTINGS_CONTENT" | grep "^LANGUAGE=" | cut -d= -f2)
    
    # 설정 파일 로드
    set -a
    source "$SCRIPT_DIR/settings.env"
    set +a
    
    # 디버그 모드에서 설정 파일 로드 후 상태 출력
    if [ "$DEBUG" = "true" ]; then
        echo "===== 설정 파일 로드 후 상태 ====="
        echo "로드된 LANGUAGE 값: $LANGUAGE"
        echo "설정 파일의 LANGUAGE 값: $SETTINGS_LANGUAGE"
        echo "==================================="
    fi
    
    # 사용자가 환경 변수나 LANG으로 언어를 지정하지 않았다면
    # settings.env의 값 사용
    if [ -z "$DETECTED_LANGUAGE" ] && [ -n "$SETTINGS_LANGUAGE" ]; then
        DETECTED_LANGUAGE="$SETTINGS_LANGUAGE"
        LANGUAGE_SOURCE="설정 파일"
        
        if [ "$DEBUG" = "true" ]; then
            echo "설정 파일에서 언어 설정 로드: $DETECTED_LANGUAGE"
        fi
    fi
else
    echo "설정 파일이 없습니다: $SCRIPT_DIR/settings.env"
    exit 1
fi

# 최종 LANGUAGE 값 설정
if [ -n "$DETECTED_LANGUAGE" ]; then
    LANGUAGE="$DETECTED_LANGUAGE"
    
    if [ "$DEBUG" = "true" ]; then
        echo "최종 언어 설정: $LANGUAGE (출처: $LANGUAGE_SOURCE)"
    fi
fi

# 기본값 설정
TIMEZONE="${TIMEZONE:-Asia/Seoul}"
DEFAULT_PASSWORD="${DEFAULT_PASSWORD:-1234}"
DEFAULT_WORKDIR="${DEFAULT_WORKDIR:-work/project}"
DEBUG="${DEBUG:-false}"

# 메시지 파일 로드
if [ -f "$SCRIPT_DIR/messages/load.sh" ]; then
    if [ "$DEBUG" = "true" ]; then
        echo "통합 메시지 로딩 시스템 사용: $SCRIPT_DIR/messages/load.sh"
    fi
    source "$SCRIPT_DIR/messages/load.sh"
    load_messages "$LANGUAGE"
else
    if [ "$DEBUG" = "true" ]; then
        echo "기존 메시지 로딩 방식 사용"
    fi
    # 기존 방식으로 메시지 파일 로드
    if [ -f "$SCRIPT_DIR/messages/${LANGUAGE}.sh" ]; then
        if [ "$DEBUG" = "true" ]; then
            echo "메시지 파일 로드: $SCRIPT_DIR/messages/${LANGUAGE}.sh"
        fi
        source "$SCRIPT_DIR/messages/${LANGUAGE}.sh"
    else
        echo "언어 파일을 찾을 수 없습니다: $LANGUAGE. 영어로 대체합니다."
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
            echo "메시지를 찾을 수 없음: $message_key"
        fi
    fi
}

# 베이스 이미지 설정
if [ -n "$CUSTOM_BASE_IMAGE" ]; then
    # 사용자 지정 이미지 사용
    BASE_IMAGE="$CUSTOM_BASE_IMAGE"
else
    # 자동 언어별 이미지 선택
    if [ "$LANGUAGE" = "ko" ]; then
        BASE_IMAGE="namugach/ubuntu-basic:24.04-kor-deno"
        LOCALE_SETTING="ko_KR.UTF-8"
    elif [ "$LANGUAGE" = "en" ]; then
        BASE_IMAGE="ubuntu:24.04"
        LOCALE_SETTING="en_US.UTF-8"
    else
        BASE_IMAGE="ubuntu:24.04"
        LOCALE_SETTING="en_US.UTF-8"
    fi
fi

# 기존 템플릿 경로 재정의 (Dockerfile 사용)
DOCKERFILE_TEMPLATE="$TEMPLATES_DIR/Dockerfile"

# 디버그 정보 출력
if [ "$DEBUG" = "true" ]; then
    echo "===== 시스템 설정 정보 ====="
    echo "언어: $LANGUAGE"
    echo "베이스 이미지: $BASE_IMAGE"
    echo "로케일: $LOCALE_SETTING"
    echo "시간대: $TIMEZONE"
    echo "작업 디렉토리: $DEFAULT_WORKDIR"
    echo "템플릿 디렉토리: $TEMPLATES_DIR"
    echo "Dockerfile 템플릿: $DOCKERFILE_TEMPLATE"
    echo "=========================="
fi

# 템플릿 처리 함수 (기존 템플릿 처리 함수를 오버라이드)
process_template_with_base_image() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        echo "템플릿 파일을 찾을 수 없습니다: $template_file"
        return 1
    fi
    
    echo "템플릿 처리 중: $template_file -> $output_file"
    
    # 템플릿 파일 읽기
    local template_content=$(<"$template_file")
    
    # 첫 줄의 FROM 이미지를 BASE_IMAGE로 교체
    local processed_content=$(echo "$template_content" | sed "1s|^FROM .*|FROM $BASE_IMAGE|")
    
    # 파일에 저장
    echo "$processed_content" > "$output_file"
    
    if [ $? -eq 0 ]; then
        echo "파일이 생성되었습니다: $output_file"
        return 0
    else
        echo "파일 생성에 실패했습니다: $output_file"
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