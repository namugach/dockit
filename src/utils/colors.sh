#!/bin/bash

# 색상 정의 유틸리티
# Color definitions utility

# 모든 dockit 스크립트에서 사용하는 색상을 중앙 집중 관리
# Centralized color management for all dockit scripts

# 기본 색상 정의
# Basic color definitions
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
GRAY="\033[1;30m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

# 추가 색상 (필요 시 확장 가능)
# Additional colors (expandable if needed)
# WHITE="\033[1;37m"
# BLACK="\033[0;30m"
# LIGHT_RED="\033[1;31m"
# LIGHT_GREEN="\033[1;32m"
# LIGHT_YELLOW="\033[1;33m"
# LIGHT_BLUE="\033[1;34m"
# LIGHT_PURPLE="\033[1;35m"
# LIGHT_CYAN="\033[1;36m"

# 색상 변수들을 export하여 하위 스크립트에서도 사용 가능하도록 함
# Export color variables for use in child scripts
export GREEN RED YELLOW BLUE PURPLE GRAY CYAN NC 