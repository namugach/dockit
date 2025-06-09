#!/bin/bash

# dockit reset script
# uninstall 후 install을 자동으로 실행하여 깨끗하게 다시 설치합니다.

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# 언어 설정 백업
if [ -f "$HOME/.dockit/config/settings.env" ]; then
    CURRENT_LANGUAGE=$(grep "LANGUAGE=" "$HOME/.dockit/config/settings.env" | cut -d'"' -f2)
    echo "현재 언어 설정: $CURRENT_LANGUAGE"
else
    CURRENT_LANGUAGE="ko"  # 기본값으로 한국어 설정
fi

echo -e "\n[1/4] 기존 dockit 제거 중..."
# uninstall.sh에 자동으로 'y'를 입력하여 확인 없이 진행
echo "y" | ./uninstall.sh

echo -e "\n[2/4] 남은 설치 파일 정리 중..."
rm -rf ~/.dockit 2>/dev/null || echo "남은 파일이 없습니다."

echo -e "\n[3/4] dockit 다시 설치 중..."
# 언어 선택 자동화: 미리 언어 번호를 입력하여 자동 선택
if [ "$CURRENT_LANGUAGE" = "ko" ]; then
    # 한국어 선택 (옵션 2)
    echo "2" | ./install.sh
else
    # 영어 선택 (옵션 1)
    echo "1" | ./install.sh
fi

echo -e "\n[4/4] 리셋 완료!"
echo "dockit이 성공적으로 재설치되었습니다."
echo -e "\n테스트를 위해 새 쉘을 열거나 다음 명령어를 실행하세요:"
echo "source ~/.bashrc"

exit 0 