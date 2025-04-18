#!/bin/bash

# 언어 메타데이터 / Language Metadata
LANG_CODE="en"
LANG_NAME="English"
LANG_LOCALE="en_US.UTF-8"
LANG_TIMEZONE="UTC"
LANG_DIRECTION="ltr"
LANG_VERSION="1.0"
LANG_AUTHOR="Dockit Team"

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
MSG_COMMON_NOT_INITIALIZED="Initialization required. Please run init command: \n\ndockit init"
MSG_COMMON_RUN_INIT_FIRST="Run init command first: dockit init"
MSG_COMMON_REQUIRED_FILES_MISSING="Required configuration files are missing."

# init 모듈 메시지
# init module messages
MSG_INIT_START="Starting initialization..."
MSG_CREATING_DOCKIT_DIR="Creating .dockit_project directory..."
MSG_DOCKIT_DIR_CREATED=".dockit_project directory has been created."
MSG_ERROR_CREATING_DOCKIT_DIR="Error creating .dockit_project directory!"
MSG_LEGACY_ENV_MOVED="Legacy .env file moved to .dockit_project directory."
MSG_LEGACY_COMPOSE_MOVED="Legacy docker-compose.yml file moved to .dockit_project directory."
MSG_GIT_REPO_DETECTED="Git repository detected."
MSG_ADDING_TO_GITIGNORE="Adding .dockit_project/ to .gitignore file."
MSG_CREATING_GITIGNORE="Creating .gitignore file with .dockit_project/ entry."
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
MSG_CONTAINER_STOPPED_INFO="Container has been stopped. To start again: dockit start"

# connect 모듈 메시지
# connect module messages
MSG_CONNECT_START="Running connect module..."
MSG_CONTAINER_NOT_RUNNING="Container is not running."
MSG_START_CONTAINER_FIRST="You need to start the container first:"
MSG_WANT_START_CONTAINER="Do you want to start the container now?"
MSG_START_CANCELLED="Container start cancelled."
MSG_CONNECTED="Successfully connected to container."
MSG_CONNECT_FAILED="Failed to connect to container."

# status 모듈 메시지
# status module messages
MSG_STATUS_START="Running status check module..."
MSG_CONTAINER_STATUS="Container status:"
MSG_CONTAINER_ID="Container ID"
MSG_CONTAINER_STATE="State"
MSG_CONTAINER_CREATED="Created"
MSG_CONTAINER_IMAGE="Image"
MSG_CONTAINER_IP="IP Address"
MSG_CONTAINER_PORTS="Ports"
MSG_STATUS_COMPLETE="Status check complete."
MSG_STATUS_PROJECT_CONFIG="Project Dockit Configuration:"
MSG_STATUS_VERSION="Dockit Version"
MSG_STATUS_IMAGE_NAME="Image Name"
MSG_STATUS_CONTAINER_NAME="Container Name"
MSG_STATUS_USERNAME="Username"
MSG_STATUS_USER_UID="User UID"
MSG_STATUS_USER_GID="User GID"
MSG_STATUS_WORKDIR="Working Directory"

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
MSG_HELP_USAGE="Usage: dockit [command]"
MSG_HELP_COMMANDS="Available commands:"
MSG_HELP_INIT="  init     - Initialize Docker development environment"
MSG_HELP_START="  start    - Start container"
MSG_HELP_STOP="  stop     - Stop container (preserves state)"
MSG_HELP_DOWN="  down     - Remove container completely"
MSG_HELP_CONNECT="  connect  - Connect to container"
MSG_HELP_STATUS="  status   - Check container status"
MSG_HELP_MIGRATE="  migrate  - Upgrade to a newer version"
MSG_HELP_HELP="  help     - Display this help"
MSG_HELP_VERSION="  version  - Display version information"

# 도움말 추가 메시지
# Help additional messages
MSG_TITLE="Docker Development Environment Tool"
MSG_EXAMPLES_HEADER="Examples"
MSG_EXAMPLE_INIT="  dockit init      # Initial setup and configuration"
MSG_EXAMPLE_START="  dockit start    # Start container"
MSG_EXAMPLE_STOP="  dockit stop     # Stop container (preserves state)"
MSG_EXAMPLE_DOWN="  dockit down     # Remove container completely"
MSG_EXAMPLE_CONNECT="  dockit connect  # Connect to container"
MSG_EXAMPLE_MIGRATE="  dockit migrate  # Upgrade to the latest version"

MSG_CONFIG_FILES_HEADER="Configuration Files"
MSG_CONFIG_FILE_ENV="  .dockit_project/.env                # User settings file"
MSG_CONFIG_FILE_COMPOSE="  .dockit_project/docker-compose.yml  # Docker Compose configuration file"
MSG_CONFIG_FILE_LOG="  .dockit_project/dockit.log          # Log file"
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

# install module messages
MSG_INSTALL_START="Starting dockit installation..."
MSG_INSTALL_CHECKING_DEPENDENCIES="Checking dependencies..."
MSG_INSTALL_DOCKER_MISSING="Docker is not installed. Please install Docker first."
MSG_INSTALL_COMPOSE_MISSING="Docker Compose is not installed. Please install Docker Compose first."
MSG_INSTALL_TOOL_MISSING="%s is not installed. Please install %s first."
MSG_INSTALL_DEPENDENCIES_OK="All dependencies are satisfied."
MSG_INSTALL_CHECKING_EXISTING="Checking existing installation..."
MSG_INSTALL_ALREADY_INSTALLED="dockit is already installed."
MSG_INSTALL_REINSTALL="Do you want to reinstall? [y/N]"
MSG_INSTALL_CANCELLED="Installation cancelled."
MSG_INSTALL_DIR_EXISTS="Project directory already exists: %s"
MSG_INSTALL_OVERWRITE="Do you want to overwrite? [y/N]"
MSG_INSTALL_CHECKING_PERMISSIONS="Checking permissions..."
MSG_INSTALL_NO_PERMISSION="No write permission for: %s"
MSG_INSTALL_USE_SUDO="Please run with sudo or check directory permissions."
MSG_INSTALL_CREATING_DIRS="Creating directories..."
MSG_INSTALL_INSTALLING_FILES="Installing project files..."
MSG_INSTALL_PATH="Installation path: %s"
MSG_INSTALL_INSTALLING_COMPLETION="Installing completion scripts..."
MSG_INSTALL_ADDING_PATH="Adding installation directory to PATH."
MSG_INSTALL_COMPLETED="Installation completed!"
MSG_INSTALL_CMD_AVAILABLE="The 'dockit' command is now available."
MSG_INSTALL_HELP_TIP="Try 'dockit help' for usage information."
MSG_INSTALL_FAILED="Installation failed."
MSG_INSTALL_SHELL_RESTART="Start a new shell or run 'source ~/.bashrc' or 'source ~/.zshrc'."
MSG_INSTALL_CHECK_DOCKER="Check if Docker is running."
MSG_INSTALL_CHECK_PORTS="Check if ports 80, 443 are available."
MSG_INSTALL_CHECK_IMAGE="Check if the image exists."
MSG_INSTALL_COMPLETE="Installation completed successfully."
MSG_INSTALL_FAILED="Installation failed."

# Completion related messages
MSG_INSTALL_GLOBAL_COMPLETION="System-wide completion installed"
MSG_INSTALL_COMPLETION_HELP="* Use TAB key for command completion"
MSG_INSTALL_COMPLETION_ENABLE="To enable command completion, reload your shell with:"
MSG_INSTALL_BASH_RELOAD="For Bash shell:"
MSG_INSTALL_ZSH_RELOAD="For Zsh shell:"
MSG_INSTALL_ZSH_COMPLETION_ADDED="Zsh completion settings added"
MSG_INSTALL_ZSH_COMPLETION_ACTIVATE="Enable autocompletion"
MSG_INSTALL_ZSH_COMPLETION_ADD_PATH="Add dockit completion path"
MSG_INSTALL_ZSH_COMPLETION_LOAD="Load dockit completion directly"

# Additional messages for init.sh
MSG_INIT_GETTING_USER_INPUT="Getting user input..."
MSG_CONFIG_SAVED="Configuration has been saved."
MSG_INIT_VERSION_HEADER="Dockit v%s"
MSG_INIT_VERSION_SEPARATOR="====================="
MSG_INIT_COMPLETE="Initialization completed successfully."
MSG_TEMPLATE_GENERATED="Generated: %s"

# Uninstall module messages
MSG_UNINSTALL_START="Starting dockit uninstallation..."
MSG_UNINSTALL_CONFIRM="Do you want to uninstall dockit? This will remove all program files and configurations."
MSG_UNINSTALL_CANCELLED="Uninstallation cancelled."
MSG_UNINSTALL_REMOVING_SCRIPT="Removing dockit script..."
MSG_UNINSTALL_SCRIPT_REMOVED="dockit script removed successfully."
MSG_UNINSTALL_SCRIPT_NOT_FOUND="dockit script not found in"
MSG_UNINSTALL_REMOVING_FILES="Removing project files..."
MSG_UNINSTALL_FILES_REMOVED="Project files removed successfully."
MSG_UNINSTALL_DIR_NOT_FOUND="Project directory not found:"
MSG_UNINSTALL_REMOVE_FAILED="Failed to completely remove project directory:"
MSG_UNINSTALL_REMOVING_COMPLETION="Removing completion scripts..."
MSG_UNINSTALL_BASH_REMOVED="Bash completion script removed."
MSG_UNINSTALL_ZSH_REMOVED="Zsh completion script removed."
MSG_UNINSTALL_REMOVING_COMPLETION_CONFIG="Removing shell completion configurations..."
MSG_UNINSTALL_REMOVED_BASH_COMPLETION="Removed Bash completion settings."
MSG_UNINSTALL_REMOVED_ZSH_COMPLETION="Removed Zsh completion settings."
MSG_UNINSTALL_REMOVED_GLOBAL_COMPLETION="Removed global completion script."
MSG_UNINSTALL_REMOVING_CONFIG="Removing configuration directory..."
MSG_UNINSTALL_CONFIG_REMOVED="Configuration directory removed successfully."
MSG_UNINSTALL_REMOVING_PATH="Removing dockit from PATH..."
MSG_UNINSTALL_REMOVED_BASHRC="Removed from .bashrc"
MSG_UNINSTALL_REMOVED_ZSHRC="Removed from .zshrc"
MSG_UNINSTALL_CLEANING_DIRS="Cleaning up installation directories..."
MSG_UNINSTALL_REMOVED_EMPTY_DIR="Removed empty directory:"
MSG_UNINSTALL_SUCCESSFUL="Uninstallation successful!"
MSG_UNINSTALL_INCOMPLETE="Uninstallation may be incomplete. Please check manually."
MSG_UNINSTALL_RESTART_SHELL="Please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"

# Completion command descriptions
MSG_COMPLETION_INIT="Initialize dockit project"
MSG_COMPLETION_START="Start container"
MSG_COMPLETION_STOP="Stop container"
MSG_COMPLETION_DOWN="Remove container completely"
MSG_COMPLETION_STATUS="Check container status"
MSG_COMPLETION_CONNECT="Connect to container"
MSG_COMPLETION_HELP="Display help information"
MSG_COMPLETION_VERSION="Display version information"
MSG_COMPLETION_MIGRATE="Migrate project to new version"

# Common module test messages
MSG_COMMON_TESTING_FUNCTION="Testing generate_container_name function..."
MSG_COMMON_CURRENT_DIR="Current directory"
MSG_COMMON_GENERATED_NAME="Generated name"
MSG_COMMON_TESTING_EXPLICIT="Testing with explicit path"

# language setup messages
MSG_INSTALL_LANGUAGE_SETUP="Setting up language..."
MSG_INSTALL_LANGUAGE_AVAILABLE="Available languages:"
MSG_INSTALL_LANGUAGE_DEFAULT="default"
MSG_INSTALL_LANGUAGE_SELECT="Select language"
MSG_INSTALL_LANGUAGE_SELECTED="Selected language: %s (%s)"
MSG_INSTALL_LANGUAGE_INVALID="Invalid selection. Using default: %s (%s)"

# 버전 유효성 검사 메시지
# Version validation messages
MSG_VERSION_CHECK_HEADER="Checking version compatibility..."
MSG_VERSION_PROJECT_HIGHER="Warning: This project was created with a higher version of dockit (Project: %s, Current: %s)."
MSG_VERSION_DOWNLOAD_LATEST="Please download the latest version: https://github.com/namugach/dockit/archive/refs/heads/main.zip"
MSG_VERSION_PROJECT_LOWER="Warning: This project was created with an older version of dockit (Project: %s, Current: %s)."
MSG_VERSION_POSSIBLE_INCOMPATIBILITY="Compatibility issues may occur due to version differences."
MSG_VERSION_MIN_REQUIRED="This feature requires at least version %s (Current: %s)."
MSG_VERSION_FEATURE_UNAVAILABLE="This feature is not available in the current version."
MSG_VERSION_COMPARE_ERROR="Error occurred while comparing versions."

# Migration module messages

# Basic migration process messages
MSG_MIGRATE_START="Starting migration module."
MSG_MIGRATE_PROCESSING="Processing migration..."
MSG_MIGRATE_SUCCESS="Migration completed successfully. Current version: %s"
MSG_MIGRATE_FAILED="Migration failed: %s"
MSG_MIGRATE_PROCESS_STARTED="Starting migration process from %s to %s."
MSG_MIGRATE_PROCESS_COMPLETED="Migration process completed successfully."

# Version related messages
MSG_MIGRATE_CHECKING="Checking version information..."
MSG_MIGRATE_CURRENT_VER="Current version: %s"
MSG_MIGRATE_TARGET_VER="Target version: %s"
MSG_MIGRATE_UP_TO_DATE="Already up to date. No migration needed."
MSG_MIGRATE_DOWNGRADE_NOT_SUPPORTED="Current version is higher than target version. Downgrade not supported."
MSG_MIGRATE_NO_CURRENT_VERSION="Cannot determine current version. Migration aborted."
MSG_MIGRATE_NO_VERSION_FILE="Version file not found at %s."
MSG_MIGRATE_EMPTY_VERSION="Target version is empty."

# User interaction messages
MSG_MIGRATE_CONFIRM="Do you want to proceed with migration from version %s to version %s?"
MSG_MIGRATE_CANCELLED="Migration cancelled by user."

# Backup related messages
MSG_MIGRATE_BACKING_UP="Backing up existing settings..."
MSG_MIGRATE_BACKUP_CREATED="Backup created: %s"
MSG_MIGRATE_BACKUP_FAILED="Failed to create backup."
MSG_MIGRATE_NO_CONFIG="No existing config to backup."
MSG_MIGRATE_SAVED_CONFIG="Old settings saved at %s."
MSG_MIGRATE_NO_OLD_CONFIG="Cannot find old configuration."

# Rollback related messages
MSG_MIGRATE_ROLLBACK="Rolling back changes..."
MSG_MIGRATE_ROLLBACK_SUCCESS="Rollback completed successfully."
MSG_MIGRATE_ROLLBACK_FAILED="Rollback failed: %s"
MSG_MIGRATE_NO_BACKUP="No backup found for rollback."

# Settings related messages
MSG_MIGRATE_UPDATING_ENV="Updating environment variables..."
MSG_MIGRATE_SETTINGS_FAILED="Failed to migrate settings."
MSG_MIGRATE_NO_ENV="Cannot find old .env file."
MSG_MIGRATE_SAVE_FAILED="Failed to save old settings."

# Initialization related messages
MSG_MIGRATE_INIT_FAILED="Failed to initialize new environment."
MSG_MIGRATE_INIT_NOT_FOUND="Init module not found."
MSG_MIGRATE_BACKUP_INIT_FAILED="Failed to backup and initialize."
MSG_MIGRATE_DIR_STRUCTURE_FAILED="Failed to create migration directory structure."

# Migration logic related messages
MSG_MIGRATE_CHECKING_LOGIC="Checking version-specific migration logic from %s to %s."
MSG_MIGRATE_PATH_FOUND="Found direct migration path from %s to %s."
MSG_MIGRATE_NO_DIRECT_PATH="No direct migration path found, checking incremental migrations."
MSG_MIGRATE_LOGIC_COMPLETED="Version-specific migration completed."
MSG_MIGRATE_MIGRATING="Migrating from %s to %s..."
MSG_MIGRATE_PATH_MISSING="No migration path from %s to %s."
MSG_MIGRATE_PARTIALLY_REACHED="Migration only reached version %s, not target version %s."
MSG_MIGRATE_LOGIC_FAILED="Failed to execute version-specific migration logic."

# Migration steps related messages
MSG_MIGRATE_EXECUTING_STEPS="Executing migration steps from %s to %s."
MSG_MIGRATE_STEPS_COMPLETED="All migration steps completed successfully."
MSG_MIGRATE_STEPS_FAILED="Failed to execute migration steps."

# Script related messages
MSG_MIGRATE_SCRIPT_FOUND="Found migration script: %s"
MSG_MIGRATE_SCRIPT_SUCCESS="Migration script executed successfully."
MSG_MIGRATE_SCRIPT_FAILED="Failed to execute migration script."

# Version-specific failure messages
MSG_MIGRATE_MAJOR_FAILED="Failed to migrate major version."
MSG_MIGRATE_MINOR_FAILED="Failed to migrate minor version."
MSG_MIGRATE_PATCH_FAILED="Failed to migrate patch version."

# 설치 관련 새로운 메시지
MSG_INSTALL_CONFIRM_PROCEED="All preparations are complete. Proceed with installation? (Y/n)"
MSG_INSTALL_PATH_UPDATED="PATH settings have been updated."
MSG_INSTALL_DIRECT_PATH="Or you can run it directly by specifying the path:"
MSG_INSTALL_SCRIPT_SUCCESS="dockit script successfully installed: %s"
MSG_INSTALL_SCRIPT_FAILED="Failed to install dockit script!"
MSG_INSTALL_INITIALIZING="Starting dockit installation..."
MSG_INSTALL_FINDING_LANGUAGES="Finding available languages..."
MSG_INSTALL_LOCALE_SET="Locale will be set to: %s"
MSG_INSTALL_TIMEZONE_SET="Timezone will be set to: %s"
MSG_INSTALL_REMOVE_FAILED="Failed to remove old installation"
MSG_INSTALL_COPY_FAILED="Failed to copy project files"
MSG_INSTALL_DOCKER_NOT_INSTALLED="Docker not installed. Please install Docker first."
MSG_INSTALL_PERMISSION_DENIED="Permission denied. Please check your permissions."
MSG_INSTALL_RUN_WITH_SUDO="You may need to run with sudo or check directory permissions."
MSG_INSTALL_SETTINGS_COPIED="Settings file copied: settings.env"
MSG_INSTALL_DEFAULT_SETTINGS_CREATED="Default settings file created: settings.env"
MSG_INSTALL_MESSAGES_COPIED="Message files copied"
MSG_INSTALL_MESSAGES_DIR_NOT_FOUND="Message directory not found: %s"
MSG_INSTALL_SCRIPT_NOT_FOUND="dockit script not found or not executable: %s" 