#!/bin/bash

# 메인 유틸리티 로더
# Main utility loader

# 유틸리티 파일들이 있는 디렉토리
# Directory containing utility files
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 유틸리티 파일들
# Utility files
UTIL_LOG="${UTILS_DIR}/log.sh"
UTIL_FILE="${UTILS_DIR}/file.sh"
UTIL_SYSTEM="${UTILS_DIR}/system.sh"

# 로드된 유틸리티 추적
# Track loaded utilities
LOADED_UTILS=""

# 유틸리티 로드 함수
# Utility loading function
load_utility() {
    local util_file="$1"
    local util_name="$(basename "$util_file" .sh)"
    
    # 이미 로드되었는지 확인
    # Check if already loaded
    if [[ "$LOADED_UTILS" == *"$util_name"* ]]; then
        # 이미 로드된 경우 무시
        # Already loaded, ignore
        return 0
    fi
    
    # 파일 존재 확인
    # Check if file exists
    if [ ! -f "$util_file" ]; then
        echo "Error: Utility file not found: $util_file" >&2
        return 1
    fi
    
    # 유틸리티 로드
    # Load utility
    source "$util_file"
    
    # 로드된 유틸리티 목록에 추가
    # Add to loaded utilities list
    LOADED_UTILS="$LOADED_UTILS $util_name"
    
    return 0
}

# 모든 유틸리티 로드
# Load all utilities
load_all_utils() {
    load_utility "$UTIL_LOG"
    load_utility "$UTIL_FILE"
    load_utility "$UTIL_SYSTEM"
}

# 로깅 유틸리티만 로드
# Load only logging utility
load_log_utils() {
    load_utility "$UTIL_LOG"
}

# 파일 유틸리티만 로드
# Load only file utility
load_file_utils() {
    load_utility "$UTIL_FILE"
}

# 시스템 유틸리티만 로드
# Load only system utility
load_system_utils() {
    load_utility "$UTIL_SYSTEM"
}

# 기본적으로 모든 유틸리티 로드
# Load all utilities by default
load_all_utils 