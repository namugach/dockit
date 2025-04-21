#!/bin/bash

# Test script for build.sh module
# build.sh 모듈에 대한 테스트 스크립트

# Set error handling
# 오류 처리 설정
set -e

# Get script directory
# 스크립트 디렉토리 획득
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "$SCRIPT_DIR")" && pwd)"

# Source the common module
# 공통 모듈 로드
source "$PROJECT_ROOT/src/modules/common.sh"

# Source build module for testing
# 테스트를 위한 build 모듈 로드
source "$PROJECT_ROOT/src/modules/build.sh"

# Mock functions
# 모의 함수
docker() {
    if [[ "$1" == "build" ]]; then
        echo "Mock: Docker build called with arguments: $@"
        return 0
    else
        command docker "$@"
    fi
}

# Define test directory
# 테스트 디렉토리 정의
TEST_DIR="$SCRIPT_DIR/test_build"

# Create test environment
# 테스트 환경 생성
setup() {
    echo "Setting up test environment..."
    
    # Create test directory
    # 테스트 디렉토리 생성
    mkdir -p "$TEST_DIR/.dockit_project"
    
    # Create mock Dockerfile
    # 모의 Dockerfile 생성
    echo "FROM ubuntu:24.04" > "$TEST_DIR/.dockit_project/Dockerfile"
    
    # Create mock .env file
    # 모의 .env 파일 생성
    cat > "$TEST_DIR/.dockit_project/.env" << EOF
USERNAME="testuser"
USER_UID="1000"
USER_GID="1000"
USER_PASSWORD="testpass"
WORKDIR="testwork"
BASE_IMAGE="ubuntu:24.04"
IMAGE_NAME="test-image"
CONTAINER_NAME="test-container"
EOF

    # Change to test directory
    # 테스트 디렉토리로 이동
    cd "$TEST_DIR"
    
    echo "Test environment setup complete."
}

# Clean up test environment
# 테스트 환경 정리
teardown() {
    echo "Cleaning up test environment..."
    
    # Return to original directory
    # 원래 디렉토리로 돌아가기
    cd "$SCRIPT_DIR"
    
    # Remove test directory
    # 테스트 디렉토리 삭제
    rm -rf "$TEST_DIR"
    
    echo "Test environment cleanup complete."
}

# Test check_base_image function
# check_base_image 함수 테스트
test_check_base_image() {
    echo "Testing check_base_image function..."
    
    # Test with BASE_IMAGE set
    # BASE_IMAGE가 설정된 경우 테스트
    BASE_IMAGE="ubuntu:24.04"
    check_base_image
    
    # Test with BASE_IMAGE not set
    # BASE_IMAGE가 설정되지 않은 경우 테스트
    unset BASE_IMAGE
    check_base_image
    
    echo "check_base_image test passed."
}

# Test build_docker_image function
# build_docker_image 함수 테스트
test_build_docker_image() {
    echo "Testing build_docker_image function..."
    
    # Set variables for testing
    # 테스트용 변수 설정
    BASE_IMAGE="ubuntu:24.04"
    IMAGE_NAME="test-image"
    
    # Call function
    # 함수 호출
    build_docker_image
    
    echo "build_docker_image test passed."
}

# Test build_image_if_confirmed function with auto-response
# 자동응답으로 build_image_if_confirmed 함수 테스트
test_build_image_if_confirmed() {
    echo "Testing build_image_if_confirmed function..."
    
    # Mock read command to auto-respond
    # 자동 응답을 위한 모의 read 명령
    read() {
        if [[ "$*" == *"$MSG_SELECT_CHOICE"* ]]; then
            # Auto-respond 'y' to build image
            # 이미지 빌드에 'y' 자동 응답
            REPLY="y"
        fi
    }
    
    # Call function
    # 함수 호출
    build_image_if_confirmed
    
    # Restore original read command
    # 원래 read 명령 복원
    unset -f read
    
    echo "build_image_if_confirmed test passed."
}

# Test build_main function with auto-response
# 자동응답으로 build_main 함수 테스트
test_build_main() {
    echo "Testing build_main function..."
    
    # Mock read command to auto-respond
    # 자동 응답을 위한 모의 read 명령
    read() {
        if [[ "$*" == *"$MSG_SELECT_CHOICE"* ]]; then
            # Auto-respond 'y' to build image
            # 이미지 빌드에 'y' 자동 응답
            REPLY="y"
        fi
    }
    
    # Mock trap to prevent exit
    # 종료 방지를 위한 모의 trap
    trap() {
        echo "Mock: Trap called with arguments: $@"
    }
    
    # Call function
    # 함수 호출
    build_main
    
    # Restore original functions
    # 원래 함수 복원
    unset -f read
    unset -f trap
    
    echo "build_main test passed."
}

# Run tests
# 테스트 실행
run_tests() {
    echo "Running build.sh module tests..."
    
    # Setup test environment
    # 테스트 환경 설정
    setup
    
    # Run tests
    # 테스트 실행
    test_check_base_image
    test_build_docker_image
    test_build_image_if_confirmed
    test_build_main
    
    # Teardown test environment
    # 테스트 환경 정리
    teardown
    
    echo "All tests passed successfully!"
}

# Run tests if script is executed directly
# 스크립트가 직접 실행되면 테스트 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi 