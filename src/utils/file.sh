#!/bin/bash

# 파일 및 디렉토리 관련 유틸리티 함수들
# File and directory utility functions

# 파일 존재 확인 함수
# Check if file exists
check_file_exists() {
    [ -f "$1" ]
}

# 디렉토리 존재 확인 함수
# Check if directory exists
check_dir_exists() {
    [ -d "$1" ]
}

# 디렉토리 생성 함수
# Create directory if it doesn't exist
create_dir_if_not_exists() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        return $?
    fi
    return 0
}

# 권한 확인 함수
# Check write permission
check_write_permission() {
    [ -w "$1" ]
}

# 심볼릭 링크 확인 함수
# Check if path is a symbolic link
check_symlink() {
    [ -L "$1" ]
}

# 실행 권한 확인 함수
# Check execute permission
check_execute_permission() {
    [ -x "$1" ]
}

# 파일 백업 함수
# Backup file with timestamp
backup_file() {
    local file="$1"
    local backup_dir="${2:-$(dirname "$file")}"
    local timestamp=$(date "+%Y%m%d_%H%M%S")
    local filename=$(basename "$file")
    local backup_file="${backup_dir}/${filename}.${timestamp}.bak"
    
    create_dir_if_not_exists "$backup_dir"
    
    if check_file_exists "$file"; then
        cp "$file" "$backup_file"
        return $?
    else
        return 1
    fi
}

# 디렉토리 백업 함수
# Backup directory with timestamp
backup_directory() {
    local dir="$1"
    local backup_parent="${2:-$(dirname "$dir")}"
    local timestamp=$(date "+%Y%m%d_%H%M%S")
    local dirname=$(basename "$dir")
    local backup_dir="${backup_parent}/${dirname}.${timestamp}.bak"
    
    if check_dir_exists "$dir"; then
        cp -r "$dir" "$backup_dir"
        return $?
    else
        return 1
    fi
}

# 파일 내용 검색 함수 
# Search content in file
search_in_file() {
    local pattern="$1"
    local file="$2"
    
    if check_file_exists "$file"; then
        grep -q "$pattern" "$file"
        return $?
    else
        return 1
    fi
}

# 파일에 행 추가 함수
# Add line to file if it doesn't exist
add_line_to_file() {
    local line="$1"
    local file="$2"
    
    create_dir_if_not_exists "$(dirname "$file")"
    
    if ! check_file_exists "$file"; then
        echo "$line" > "$file"
        return $?
    elif ! search_in_file "^$line$" "$file"; then
        echo "$line" >> "$file"
        return $?
    fi
    
    return 0
}

# 파일 확장자 가져오기
# Get file extension
get_file_extension() {
    local filename="$1"
    echo "${filename##*.}"
}

# 파일 이름(확장자 제외) 가져오기
# Get filename without extension
get_filename_without_extension() {
    local filename="$(basename "$1")"
    local ext="$(get_file_extension "$filename")"
    echo "${filename%.$ext}"
} 