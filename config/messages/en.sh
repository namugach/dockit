#!/bin/bash

# 영어 메시지 정의
# English message definitions

# 공통 메시지
# Common messages
MSG_WELCOME="Docker Development Environment Setup"
MSG_INPUT_DEFAULT="(Press Enter to use the default value in parentheses)"
MSG_CURRENT_SETTINGS="The following default values will be used:"
MSG_USERNAME="Username"
MSG_USER_UID="User UID"
MSG_USER_GID="User GID"
MSG_PASSWORD="Password"
MSG_WORKDIR="Working Directory"
MSG_IMAGE_NAME="Image Name"
MSG_CONTAINER_NAME="Container Name"
MSG_SELECT_OPTION="Select an option:"
MSG_USE_DEFAULT="Continue with default values"
MSG_MODIFY_VALUES="Modify each value"
MSG_CANCEL="Cancel"
MSG_SELECT_CHOICE="Choice"
MSG_INPUT_USERNAME="Username"
MSG_INPUT_UID="User UID"
MSG_INPUT_GID="User GID"
MSG_INPUT_PASSWORD="User Password"
MSG_INPUT_WORKDIR="Working Directory Name"
MSG_INPUT_IMAGE_NAME="Image Name"
MSG_INPUT_CONTAINER_NAME="Container Name"
MSG_FINAL_SETTINGS="Final Settings:"
MSG_INIT_CANCELLED="Initialization has been cancelled."
MSG_INVALID_CHOICE="Invalid choice. Initialization has been cancelled."

# 공통 메시지
# Common Messages
MSG_COMMON_LOADING_CONFIG="Loading configuration file: %s"
MSG_COMMON_CONFIG_NOT_FOUND="Configuration file not found. Using default values."
MSG_COMMON_BASE_IMAGE_NOT_SET="BASE_IMAGE is not set. Using default image."
MSG_COMMON_USING_BASE_IMAGE="Using base image: %s"
MSG_COMMON_CONTAINER_RUNNING="Container is running: %s"
MSG_COMMON_CONTAINER_STOPPED="Container is stopped: %s"
MSG_COMMON_CONTAINER_NOT_FOUND="Container does not exist: %s"
MSG_COMMON_COMPOSE_NOT_FOUND="docker-compose.yml file not found"
MSG_COMMON_RUN_INIT_FIRST="Please run init command first: ./dockit.sh init"
MSG_COMMON_DIRECT_EXECUTE_ERROR="This script cannot be executed directly. Please use it through dockit.sh"

# init 모듈 메시지
# init module messages
MSG_INIT_START="Starting initialization..."
MSG_CREATING_DOCKIT_DIR="Creating .dockit directory..."
MSG_DOCKIT_DIR_CREATED=".dockit directory has been created."
MSG_OLD_LOG_FOUND="Found old version log file, removing..."
MSG_OLD_LOG_REMOVED="Old version log file has been removed."
MSG_MOVING_ENV="Moving existing .env file to new location..."
MSG_ENV_MOVED=".env file has been moved."
MSG_MOVING_COMPOSE="Moving existing docker-compose.yml file to new location..."
MSG_COMPOSE_MOVED="docker-compose.yml file has been moved."
MSG_MOVING_LOG="Moving existing log file to new location..."
MSG_LOG_MOVED="Log file has been moved."
MSG_CREATING_DOCKERFILE="Creating Dockerfile template..."
MSG_DOCKERFILE_CREATED="Dockerfile template has been created."
MSG_DOCKERFILE_FAILED="Failed to create Dockerfile template."
MSG_BUILDING_IMAGE="Building Docker image:"
MSG_BASE_IMAGE_NOT_SET="BASE_IMAGE is not set. Using default image."
MSG_USING_BASE_IMAGE="Using base image:"
MSG_MULTILANG_SETTINGS="Using multilingual settings system:"
MSG_PROCESSING_TEMPLATE="Processing template using default method..."
MSG_IMAGE_BUILT="Docker image has been built successfully:"
MSG_IMAGE_BUILD_FAILED="Failed to build Docker image."
MSG_CREATING_COMPOSE="Creating Docker Compose file..."
MSG_COMPOSE_CREATED="Docker Compose file has been created."
MSG_COMPOSE_FAILED="Failed to create Docker Compose file."
MSG_START_CONTAINER_NOW="Would you like to start the container now?"
MSG_STARTING_CONTAINER="Starting container..."
MSG_CONTAINER_STARTED="Container has been started successfully!"
MSG_CONTAINER_START_FAILED="Failed to start container."
MSG_CHECK_DOCKER="1. Check if Docker service is running"
MSG_CHECK_PORTS="2. Check for port conflicts"
MSG_CHECK_IMAGE="3. Check if image exists (initialization required if not)"
MSG_CONNECT_CONTAINER_NOW="Would you like to connect to the container now?"
MSG_CONNECTING_CONTAINER="Connecting to container..."
MSG_SKIPPING_CONNECT="Skipping container connection."
MSG_CONNECT_LATER="To connect to the container later:"
MSG_START_LATER="To start the container later:"

# down 모듈 메시지
# down module messages
MSG_DOWN_START="Starting container removal module..."
MSG_COMPOSE_NOT_FOUND="Docker Compose file not found."
MSG_CONTAINER_STOPPED="Container has been removed successfully."
MSG_CONTAINER_STOP_FAILED="Failed to remove container."

# stop 모듈 메시지
# stop module messages
MSG_STOP_START="Container stop module running..."
MSG_CONTAINER_NOT_FOUND="No container to stop."
MSG_CONTAINER_STOPPED="Container has been successfully stopped."
MSG_CONTAINER_STOP_FAILED="Failed to stop container."
MSG_CONTAINER_STOPPED_INFO="Container has been stopped. To start again: ./dockit.sh start"

# connect 모듈 메시지
# connect module messages
MSG_CONNECT_START="Starting container connection module..."
MSG_CONTAINER_NOT_RUNNING="Container is not running."
MSG_START_CONTAINER_FIRST="You need to start the container first: ./dockit.sh start"
MSG_CONNECTED="Successfully connected to container."
MSG_CONNECT_FAILED="Failed to connect to container."

# status 모듈 메시지
# status module messages
MSG_STATUS_START="Starting status check module..."
MSG_CONTAINER_STATUS="Container Status:"
MSG_CONTAINER_ID="Container ID"
MSG_CONTAINER_STATE="State"
MSG_CONTAINER_CREATED="Created"
MSG_CONTAINER_IMAGE="Image"
MSG_CONTAINER_IP="IP Address"
MSG_CONTAINER_PORTS="Ports"
MSG_STATUS_COMPLETE="Status check completed."

# start 모듈 메시지
# start module messages
MSG_START_START="Starting container start module..."
MSG_CONTAINER_ALREADY_RUNNING="Container is already running."

# 일반 메시지
# General messages
MSG_GOODBYE="Exiting Docker environment"

# 상태 메시지
# Status messages
MSG_CONTAINER_RUNNING="Container is running"
MSG_CONTAINER_NOT_EXIST="Container does not exist"
MSG_IMAGE_EXIST="Docker image exists"
MSG_IMAGE_NOT_EXIST="Docker image does not exist"

# 명령어 관련 메시지
# Command related messages
MSG_START_CONTAINER="Starting container"
MSG_STOP_CONTAINER="Stopping container"
MSG_DOWN_CONTAINER="Removing container completely"
MSG_CONNECT_CONTAINER="Connecting to container"
MSG_CHECKING_STATUS="Checking status"
MSG_INITIALIZING="Performing initialization"
MSG_CMD_SUCCESS="Command executed successfully"
MSG_CMD_FAILED="Command execution failed"

# 질문 메시지
# Question messages
MSG_CONFIRM_STOP="Do you want to stop the running container? (y/n): "
MSG_CONFIRM_DOWN="Do you want to completely remove the container? (y/n): "
MSG_CONFIRM_START="Do you want to start a new container? (y/n): "
MSG_CONFIRM_INIT="Do you want to proceed with initialization? (y/n): "

# 도움말 메시지
# Help messages
MSG_HELP_USAGE="Usage: dockit.sh [command]"
MSG_HELP_COMMANDS="Available commands:"
MSG_HELP_INIT="  init     - Initialize Docker development environment"
MSG_HELP_START="  start    - Start container"
MSG_HELP_STOP="  stop     - Stop container (preserves state)"
MSG_HELP_DOWN="  down     - Remove container completely"
MSG_HELP_CONNECT="  connect  - Connect to container"
MSG_HELP_STATUS="  status   - Check container status"
MSG_HELP_HELP="  help     - Display help"

# 도움말 추가 메시지
# Help additional messages
MSG_TITLE="Docker Development Environment Tool"
MSG_EXAMPLES_HEADER="Examples"
MSG_EXAMPLE_INIT="  ./dockit.sh init      # Initial setup and configuration"
MSG_EXAMPLE_START="  ./dockit.sh start    # Start container"
MSG_EXAMPLE_STOP="  ./dockit.sh stop     # Stop container (preserves state)"
MSG_EXAMPLE_DOWN="  ./dockit.sh down     # Remove container completely"
MSG_EXAMPLE_CONNECT="  ./dockit.sh connect  # Connect to container"

MSG_DIRECT_MODULES_HEADER="Direct Module Execution"
MSG_DIRECT_MODULES_DESC="  Each module can be executed directly:"
MSG_EXAMPLE_MODULE_INIT="  ./src/modules/init.sh    # Run init module directly"
MSG_EXAMPLE_MODULE_CONNECT="  ./src/modules/connect.sh    # Run connect module directly"

MSG_CONFIG_FILES_HEADER="Configuration Files"
MSG_CONFIG_FILE_ENV="  .dockit/.env                # User settings file"
MSG_CONFIG_FILE_COMPOSE="  .dockit/docker-compose.yml  # Docker Compose configuration file"
MSG_CONFIG_FILE_LOG="  .dockit/dockit.log          # Log file"
MSG_CONFIG_FILE_SETTINGS="  config/settings.env         # Language and default settings file"

# 시스템 메시지
# System Messages
MSG_SYSTEM_DEBUG_INITIAL_LANG="===== Initial Language Settings ====="
MSG_SYSTEM_DEBUG_LANG_VAR="Environment Variable LANGUAGE: %s"
MSG_SYSTEM_DEBUG_SYS_LANG="System Locale LANG: %s"
MSG_SYSTEM_DEBUG_CONFIG_LANG="Config File Language: %s"
MSG_SYSTEM_DEBUG_NO_CONFIG="Config File Language: No file"
MSG_SYSTEM_DEBUG_END="================================="
MSG_SYSTEM_LANG_FROM_ENV="Environment Variable LANGUAGE"
MSG_SYSTEM_LANG_FROM_SYS="System Locale LANG"
MSG_SYSTEM_LANG_FROM_CONFIG="Config File"
MSG_SYSTEM_DEBUG_AFTER_LOAD="===== Status After Loading Config ====="
MSG_SYSTEM_DEBUG_LOADED_LANG="Loaded LANGUAGE Value: %s"
MSG_SYSTEM_DEBUG_CONFIG_LANG_VALUE="Config File LANGUAGE Value: %s"
MSG_SYSTEM_DEBUG_LOAD_END="==================================="
MSG_SYSTEM_DEBUG_LOAD_FROM_CONFIG="Language setting loaded from config: %s"
MSG_SYSTEM_NO_CONFIG_FILE="Config file not found: %s"
MSG_SYSTEM_FINAL_LANG="Final Language Setting: %s (Source: %s)"
MSG_SYSTEM_DEBUG_INTEGRATED_MSG="Using Integrated Message Loading System: %s"
MSG_SYSTEM_DEBUG_LEGACY_MSG="Using Legacy Message Loading Method"
MSG_SYSTEM_DEBUG_LOAD_MSG_FILE="Loading Message File: %s"
MSG_SYSTEM_LANG_FILE_NOT_FOUND="Language file not found: %s. Falling back to English."
MSG_SYSTEM_MSG_NOT_FOUND="Message not found: %s"
MSG_SYSTEM_DEBUG_SYS_INFO="===== System Configuration Info ====="
MSG_SYSTEM_DEBUG_LANG="Language: %s"
MSG_SYSTEM_DEBUG_BASE_IMG="Base Image: %s"
MSG_SYSTEM_DEBUG_LOCALE="Locale: %s"
MSG_SYSTEM_DEBUG_TIMEZONE="Timezone: %s"
MSG_SYSTEM_DEBUG_WORKDIR="Work Directory: %s"
MSG_SYSTEM_DEBUG_TEMPLATE_DIR="Template Directory: %s"
MSG_SYSTEM_DEBUG_DOCKERFILE="Dockerfile Template: %s"
MSG_SYSTEM_DEBUG_INFO_END="=========================="
MSG_SYSTEM_TEMPLATE_NOT_FOUND="Template file not found: %s"
MSG_SYSTEM_TEMPLATE_PROCESSING="Processing Template: %s -> %s"
MSG_SYSTEM_FILE_CREATED="File created: %s"
MSG_SYSTEM_FILE_CREATE_FAILED="Failed to create file: %s"

# 디버그 테스트 메시지
# Debug Test Messages
MSG_SYSTEM_DEBUG_MSG_TEST="===== Message Output Test ====="
MSG_SYSTEM_DEBUG_WELCOME="Welcome Message: %s"
MSG_SYSTEM_DEBUG_HELP="Help Usage: %s"
MSG_SYSTEM_DEBUG_CONTAINER="Container Status Message: %s"
MSG_SYSTEM_DEBUG_CONFIRM="Confirmation Message: %s"
MSG_SYSTEM_DEBUG_TEMPLATE_TEST="===== Template Processing Test ====="
MSG_SYSTEM_DEBUG_TEMPLATE_PATH="Template Path: %s"
MSG_SYSTEM_DEBUG_TEMPLATE_PROCESS="Testing template processing function..."
MSG_SYSTEM_DEBUG_TEMPLATE_SUCCESS="Template processing successful!"
MSG_SYSTEM_DEBUG_TEMPLATE_FAILED="Template processing failed!"
MSG_SYSTEM_DEBUG_TEMPLATE_PREVIEW="First 10 lines of processed Dockerfile:"
MSG_SYSTEM_DEBUG_COMPLETE="Debug test completed!"
MSG_SYSTEM_DEBUG_PASSWORD="Default Password: %s" 