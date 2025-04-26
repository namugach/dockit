#!/bin/bash

# Test script for list module
# list 모듈 테스트 스크립트

# Set script dir and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "$SCRIPT_DIR")" && pwd)"

# Source common utility functions
source "$PROJECT_ROOT/src/utils/utils.sh"

# Modules directory
MODULES_DIR="$PROJECT_ROOT/src/modules"

# Load common module
source "$MODULES_DIR/common.sh"

# Set test directory
TEST_DIR="$PROJECT_ROOT/test/tmp_list_test"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "===== List Module Test ====="
echo "Test directory: $TEST_DIR"

# Test function: Show output of list command
test_list_command() {
    echo "Testing list command..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker is not installed or not in PATH"
        return 1
    fi
    
    # Source list module
    source "$MODULES_DIR/list.sh"
    
    # Run list command
    list_main
    
    echo "Basic list command test completed"
    return 0
}

# Test function: Test with running container
test_with_running_container() {
    echo "Testing with a running test container..."
    
    # Create a test container with dockit label
    local container_name="dockit-list-test"
    
    # Clean up any previous test container
    docker rm -f "$container_name" &>/dev/null
    
    # Run a test container with the dockit label
    docker run -d --name "$container_name" --label "com.dockit=true" --label "com.dockit.project=list-test" alpine sleep 300
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create test container"
        return 1
    fi
    
    echo "Test container created: $container_name"
    
    # Source list module
    source "$MODULES_DIR/list.sh"
    
    # Run list command
    list_main
    
    # Clean up test container
    docker rm -f "$container_name" &>/dev/null
    
    echo "Test with running container completed"
    return 0
}

# Test function: Test with both running and stopped containers
test_mixed_containers() {
    echo "Testing with both running and stopped containers..."
    
    # Create test containers
    local container1="dockit-list-test-running"
    local container2="dockit-list-test-stopped"
    
    # Clean up any previous test containers
    docker rm -f "$container1" "$container2" &>/dev/null
    
    # Run a test container with the dockit label
    docker run -d --name "$container1" --label "com.dockit=true" --label "com.dockit.project=list-test1" alpine sleep 300
    
    # Create a stopped container
    docker run --name "$container2" --label "com.dockit=true" --label "com.dockit.project=list-test2" alpine echo "This will stop" && docker stop "$container2"
    
    echo "Test containers created: $container1 (running), $container2 (stopped)"
    
    # Source list module
    source "$MODULES_DIR/list.sh"
    
    # Run list command
    list_main
    
    # Clean up test containers
    docker rm -f "$container1" "$container2" &>/dev/null
    
    echo "Test with mixed containers completed"
    return 0
}

# Run tests
run_tests() {
    test_list_command
    echo ""
    test_with_running_container
    echo ""
    test_mixed_containers
    echo ""
    
    echo "All tests completed"
}

# Clean up
cleanup() {
    echo "Cleaning up test environment..."
    cd "$PROJECT_ROOT"
    rm -rf "$TEST_DIR"
    docker rm -f dockit-list-test dockit-list-test-running dockit-list-test-stopped &>/dev/null
    echo "Test cleanup completed"
}

# Run tests
run_tests

# Clean up after tests
cleanup

echo "===== List Module Test Completed ====="
exit 0 