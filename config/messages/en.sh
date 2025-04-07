#!/bin/bash

# English message definitions

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
MSG_INSTALL_CANCELLED="Installation has been cancelled."
MSG_INVALID_CHOICE="Invalid choice. Installation has been cancelled."

# install module messages
MSG_INSTALL_START="Starting installation..."
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
MSG_CHECK_IMAGE="3. Check if image exists (installation required if not)"
MSG_CONNECT_CONTAINER_NOW="Would you like to connect to the container now?"
MSG_CONNECTING_CONTAINER="Connecting to container..."
MSG_SKIPPING_CONNECT="Skipping container connection."
MSG_CONNECT_LATER="To connect to the container later:"
MSG_START_LATER="To start the container later:"

# down module messages
MSG_DOWN_START="Starting container removal module..."
MSG_COMPOSE_NOT_FOUND="Docker Compose file not found."
MSG_CONTAINER_STOPPED="Container has been removed successfully."
MSG_CONTAINER_STOP_FAILED="Failed to remove container."

# stop module messages
MSG_STOP_START="Starting container stop module..."
MSG_CONTAINER_NOT_FOUND="No container to remove."

# connect module messages
MSG_CONNECT_START="Starting container connection module..."
MSG_CONTAINER_NOT_RUNNING="Container is not running."
MSG_START_CONTAINER_FIRST="You need to start the container first: ./dockit.sh start"
MSG_CONNECTED="Successfully connected to container."
MSG_CONNECT_FAILED="Failed to connect to container."

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

# start module messages
MSG_START_START="Starting container start module..."
MSG_CONTAINER_ALREADY_RUNNING="Container is already running."

# General messages
MSG_GOODBYE="Exiting Docker environment"

# Status messages
MSG_CONTAINER_RUNNING="Container is running"
MSG_CONTAINER_NOT_EXIST="Container does not exist"
MSG_IMAGE_EXIST="Docker image exists"
MSG_IMAGE_NOT_EXIST="Docker image does not exist"

# Command related messages
MSG_START_CONTAINER="Starting container"
MSG_STOP_CONTAINER="Stopping container"
MSG_DOWN_CONTAINER="Removing container completely"
MSG_CONNECT_CONTAINER="Connecting to container"
MSG_CHECKING_STATUS="Checking status"
MSG_INSTALLING="Performing installation"
MSG_CMD_SUCCESS="Command executed successfully"
MSG_CMD_FAILED="Command execution failed"

# Question messages
MSG_CONFIRM_STOP="Do you want to stop the running container? (y/n): "
MSG_CONFIRM_DOWN="Do you want to completely remove the container? (y/n): "
MSG_CONFIRM_START="Do you want to start a new container? (y/n): "
MSG_CONFIRM_INSTALL="Do you want to proceed with installation? (y/n): "

# Help messages
MSG_HELP_USAGE="Usage: dockit.sh [command]"
MSG_HELP_COMMANDS="Available commands:"
MSG_HELP_INSTALL="  install  - Install Docker development environment"
MSG_HELP_START="  start    - Start container"
MSG_HELP_STOP="  stop     - Stop container (preserves state)"
MSG_HELP_DOWN="  down     - Remove container completely"
MSG_HELP_CONNECT="  connect  - Connect to container"
MSG_HELP_STATUS="  status   - Check container status"
MSG_HELP_HELP="  help     - Display help"

# Help additional messages
MSG_TITLE="Docker Development Environment Tool"
MSG_EXAMPLES_HEADER="Examples"
MSG_EXAMPLE_INSTALL="  ./dockit.sh install    # Initial setup and configuration"
MSG_EXAMPLE_START="  ./dockit.sh start      # Start container"
MSG_EXAMPLE_STOP="  ./dockit.sh stop       # Stop container (preserves state)"
MSG_EXAMPLE_DOWN="  ./dockit.sh down       # Remove container completely"
MSG_EXAMPLE_CONNECT="  ./dockit.sh connect    # Connect to container"

MSG_DIRECT_MODULES_HEADER="Direct Module Execution"
MSG_DIRECT_MODULES_DESC="  Each module can be executed directly:"
MSG_EXAMPLE_MODULE_INSTALL="  ./src/modules/install.sh    # Run install module directly"
MSG_EXAMPLE_MODULE_CONNECT="  ./src/modules/connect.sh    # Run connect module directly"

MSG_CONFIG_FILES_HEADER="Configuration Files"
MSG_CONFIG_FILE_ENV="  .dockit/.env                # User settings file"
MSG_CONFIG_FILE_COMPOSE="  .dockit/docker-compose.yml  # Docker Compose configuration file"
MSG_CONFIG_FILE_LOG="  .dockit/dockit.log          # Log file"
MSG_CONFIG_FILE_SETTINGS="  config/settings.env         # Language and default settings file" 