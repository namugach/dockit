#!/bin/bash

# 기본 상수 정의 (개발자 관리용 - 사용자는 settings.env로 오버라이드)
# Default constants definition (for developer management - users override via settings.env)

# 베이스 이미지 설정 로드
# Load base image configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_IMAGE=$(cat "$SCRIPT_DIR/base_image" 2>/dev/null || echo "ubuntu:24.04")

# 언어별 로케일 매핑
# Locale mapping by language
declare -A DEFAULT_LOCALES
DEFAULT_LOCALES["ko"]="ko_KR.UTF-8"
DEFAULT_LOCALES["en"]="en_US.UTF-8"

# 언어별 타임존 매핑
# Timezone mapping by language
declare -A DEFAULT_TIMEZONES
DEFAULT_TIMEZONES["ko"]="Asia/Seoul"
DEFAULT_TIMEZONES["en"]="UTC"

# 기본 비밀번호
# Default password
DEFAULT_PASSWORD="1234"

# 기본 작업 디렉토리
# Default working directory
DEFAULT_WORKDIR="work/project"

# 기본 디버그 모드 설정
# Default debug mode setting
DEFAULT_DEBUG="false"

# 내보내기 - 다른 스크립트에서 사용할 수 있도록
# Export - so other scripts can use these values
export DEFAULT_IMAGE
export DEFAULT_LOCALES
export DEFAULT_TIMEZONES
export DEFAULT_PASSWORD
export DEFAULT_WORKDIR
export DEFAULT_DEBUG 