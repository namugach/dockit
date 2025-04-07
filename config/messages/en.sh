#!/bin/bash

# English message file

# General messages
MSG_WELCOME="Docker Development Environment Setup"
MSG_GOODBYE="Exiting Docker environment"

# Status messages
MSG_CONTAINER_RUNNING="Container is running"
MSG_CONTAINER_STOPPED="Container is stopped"
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