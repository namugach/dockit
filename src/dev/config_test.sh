#!/bin/bash

# 설정 디버그 스크립트 
# config 시스템이 제대로 작동하는지 테스트

# 스크립트 경로 설정
SCRIPT_DIR=$(readlink -f "$(dirname "$0")")
PROJECT_ROOT=$(dirname "$(dirname "$SCRIPT_DIR")")
export DOCKIT_ROOT="$PROJECT_ROOT"
export CONFIG_DIR="$PROJECT_ROOT/config"

echo "===== 설정 시스템 테스트 ====="

# 설정 파일이 존재하는지 확인
if [ -f "$CONFIG_DIR/settings.env" ]; then
    echo "✅ settings.env 파일이 존재합니다"
else
    echo "❌ settings.env 파일이 존재하지 않습니다"
fi

if [ -f "$CONFIG_DIR/system.sh" ]; then
    echo "✅ system.sh 파일이 존재합니다"
else
    echo "❌ system.sh 파일이 존재하지 않습니다"
fi

# 한국어 메시지 파일 확인
if [ -f "$CONFIG_DIR/messages/ko.sh" ]; then
    echo "✅ 한국어 메시지 파일이 존재합니다"
else
    echo "❌ 한국어 메시지 파일이 존재하지 않습니다"
fi

# 영어 메시지 파일 확인
if [ -f "$CONFIG_DIR/messages/en.sh" ]; then
    echo "✅ 영어 메시지 파일이 존재합니다"
else
    echo "❌ 영어 메시지 파일이 존재하지 않습니다"
fi

echo
echo "설정 파일 로드 테스트..."
echo

# 설정 파일 로드
if [ -f "$CONFIG_DIR/system.sh" ]; then
    # DEBUG 모드 활성화
    export DEBUG=true
    source "$CONFIG_DIR/system.sh"
    
    echo
    echo "설정된 변수:"
    echo "- LANGUAGE: $LANGUAGE"
    echo "- BASE_IMAGE: $BASE_IMAGE"
    echo "- LOCALE_SETTING: $LOCALE_SETTING"
    
    # 메시지 출력 테스트
    echo
    echo "메시지 출력 테스트:"
    echo "- 환영 메시지: $(print_message MSG_WELCOME)"
    echo "- 컨테이너 시작 메시지: $(print_message MSG_START_CONTAINER)"
    
    # 템플릿 처리 테스트
    echo
    echo "템플릿 처리 테스트:"
    if [ -f "$DOCKERFILE_TEMPLATE" ]; then
        echo "✅ Dockerfile 템플릿이 존재합니다: $DOCKERFILE_TEMPLATE"
        echo "템플릿 처리 함수 테스트..."
        
        # 임시 파일로 템플릿 처리 테스트
        TEMP_DOCKERFILE="/tmp/Dockerfile.test"
        if process_template_with_base_image "$DOCKERFILE_TEMPLATE" "$TEMP_DOCKERFILE"; then
            echo "✅ 템플릿 처리 성공!"
            echo
            echo "처리된 Dockerfile 첫 10줄:"
            head -n 10 "$TEMP_DOCKERFILE"
        else
            echo "❌ 템플릿 처리 실패!"
        fi
    else
        echo "❌ Dockerfile 템플릿이 존재하지 않습니다"
    fi
else
    echo "system.sh 파일을 로드할 수 없습니다"
fi

echo
echo "===== 테스트 완료 =====" 