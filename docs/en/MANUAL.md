# Dockit User Manual

This document explains the detailed usage of Dockit.

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Commands](#commands)
    - [init](#init---initialization)
    - [start](#start---start-container)
    - [build](#build---build-docker-image)
    - [up](#up---start-container-in-background)
    - [stop](#stop---stop-container)
    - [down](#down---remove-container)
    - [connect](#connect---connect-to-container)
    - [status](#status---check-status)
    - [migrate](#migrate---upgrade-version)
    - [setup](#setup---complete-environment-setup)
    - [run](#run---automated-run)
    - [join](#join---automated-run-and-connect)
    - [ps](#ps---list-containers)
    - [help](#help---display-help)
4. [Configuration File](#configuration-file)
5. [Troubleshooting](#troubleshooting)

## Introduction

Dockit is a modular shell script tool for quickly setting up and managing development environments using Docker. It provides a consistent development environment through Docker containers and helps configure the same environment across different operating systems.

The main goals of Dockit are:
- Reduce the complexity of setting up development environments
- Provide a consistent development environment
- Improve the portability of development setups
- Configure standardized environments for team work

## Installation

### Requirements

- Docker must be installed
- Bash shell environment is required

### Installation Method

To install Dockit, run the following commands:

```bash
# Clone the repository
git clone https://github.com/namugach/dockit.git
cd dockit

# Run the installation script
./bin/install.sh
```

This command installs Dockit to your system and adds the necessary paths to your shell environment.
After installation, you can use the `dockit` command from any directory.

### Uninstallation

To remove Dockit from your system:

```bash
./bin/uninstall.sh
```

## Commands

Dockit provides the following commands:

### init - Initialization

Initialize and configure the Docker development environment.

```bash
dockit init
```

This command performs the following tasks:
- Creates the `.dockit_project` directory
- Collects user configuration information
- Builds a Docker image
- Creates a docker-compose.yml file

During initialization, you can configure the following information:
- Username
- UID/GID
- Password
- Working directory
- Image name
- Container name

### Start Command

The `start` command allows you to start containers. If a container doesn't exist, it will offer to create and start it automatically.

Usage:
```bash
dockit start [options]
```

Options:
- (no arguments): Shows a list of available containers
- `number`: Starts the container with the specified number from the list
- `"this"`: Starts the container for the current project directory
- `"all"`: Starts all dockit containers

**Auto-creation Feature:**
When a container doesn't exist, the command will ask:
- "Container doesn't exist. Do you want to create and start the container? (Y/n)"
- If you choose 'Y', it will automatically run `dockit up` to create and start the container
- If you choose 'n', the operation will be cancelled

Examples:
```bash
dockit start           # Shows container list
dockit start 1         # Starts container number 1 (creates if doesn't exist)
dockit start 1 2 3     # Starts containers number 1, 2, and 3
dockit start this      # Starts container for current project (creates if doesn't exist)
dockit start all       # Starts all dockit containers
```

### build - Build Docker Image

Build a Docker image for the development environment.

```bash
dockit build [options]
```

#### Options:
- `--no-cache`: Forces a rebuild of the image without using Docker cache.

#### Usage Examples:
```bash
dockit build              # Normal build (uses cache)
dockit build --no-cache   # Force rebuild without cache
```

This command performs the following tasks:
- Builds image using `.dockit_project/Dockerfile`
- Reflects any changes made to the Dockerfile by the user
- Resolves Docker caching issues with the `--no-cache` option
- Performs UID conflict detection and automatic user handling

#### User Dockerfile Customization:
You can directly modify the `.dockit_project/Dockerfile` created after `dockit init`:
- Install additional packages
- Set environment variables
- Add custom configurations
- Reflect changes with `dockit build`

#### Automatic UID Conflict Handling:
When a user with the same UID already exists in the base image:
- Automatically detects existing users
- Applies the configured password to that user
- Automatically grants sudo privileges
- Provides a smooth working environment without file permission issues

### Up Command

Start containers in background without connection prompt.

Usage:
```bash
dockit up [options]
```

Options:
- (no arguments): Shows a list of available containers
- `number`: Starts the container with the specified number from the list
- `"this"`: Starts the container for the current project directory
- `"all"`: Starts all dockit containers

This command performs the following tasks:
- Starts containers using Docker Compose in detached mode
- Does not ask for container connection
- Shows the container status information
- Useful for automated scripts or when you don't need to connect immediately

Examples:
```bash
dockit up             # Shows container list
dockit up 1           # Starts container number 1
dockit up 1 2 3       # Starts containers number 1, 2, and 3
dockit up this        # Starts container for current project
dockit up all         # Starts all dockit containers
```

### Stop Command

The `stop` command allows you to stop running containers. This preserves the container state.

Usage:
```bash
dockit stop [options]
```

Options:
- (no arguments): Shows a list of available containers
- `number`: Stops the container with the specified number from the list
- `"this"`: Stops the container for the current project directory
- `"all"`: Stops all dockit containers

Examples:
```bash
dockit stop           # Shows container list
dockit stop 1         # Stops container number 1
dockit stop 1 2 3     # Stops containers number 1, 2, and 3
dockit stop this      # Stops container for current project
dockit stop all       # Stops all dockit containers
```

### Down Command

Completely remove containers.

Usage:
```bash
dockit down [options]
```

Options:
- (no arguments): Shows a list of available containers
- `number`: Removes the container with the specified number from the list
- `"this"`: Removes the container for the current project directory
- `"all"`: Removes all dockit containers

This command stops and removes containers. Be careful as all data stored in the containers will be deleted.

Examples:
```bash
dockit down           # Shows container list
dockit down 1         # Removes container number 1
dockit down 1 2 3     # Removes containers number 1, 2, and 3
dockit down this      # Removes container for current project
dockit down all       # Removes all dockit containers
```

### Connect Command

Connect to a container with automatic creation and start capabilities.

Usage:
```bash
dockit connect [options]
```

Options:
- (no arguments): Shows usage information
- `number`: Connects to the container with the specified number from the list
- `"this"`: Connects to the container for the current project directory

**Auto-creation and Auto-start Features:**

1. **When container doesn't exist:**
   - "Container doesn't exist. Do you want to create, start and connect to the container? (Y/n)"
   - If you choose 'Y', it will automatically run `dockit up` to create and start the container, then connect
   - If you choose 'n', the operation will be cancelled

2. **When container is stopped:**
   - "Container is stopped. Do you want to start and connect to the container? (Y/n)"
   - If you choose 'Y', it will start the container and then connect
   - If you choose 'n', the operation will be cancelled

3. **When container is running:**
   - Connects immediately to the container

Examples:
```bash
dockit connect         # Shows usage information
dockit connect 1       # Connects to container number 1 (creates/starts if needed)
dockit connect this    # Connects to current project container (creates/starts if needed)
```

This command provides a seamless workflow where you can connect to any container with a single command, regardless of its current state.

### status - Check Status

Check the current status of the container.

```bash
dockit status
```

This command displays the following information:

- **Project Configuration**:
  - Dockit Version
  - Image Name
  - Container Name

- **Host User Configuration**:
  - Username
  - User UID
  - User GID
  - Working Directory

- **Container User Information**:
  - Container Username
  - Container User UID
  - Container User GID

- **Container Status** (if container exists):
  - Container ID
  - Running State
  - Creation Time
  - Image Information
  - IP Address (if running)
  - Port Information (if running)

The host user configuration and container user information are always shown separately, which is particularly useful for diagnosing permission issues. Even if the container has not been created yet, you can still check the host configuration.

### migrate - Upgrade Version

Upgrade Dockit to a newer version while preserving user settings.

```bash
dockit migrate
```

This command performs the following tasks:
- Creates a backup of the current configuration
- Initializes the environment for the new version
- Migrates user settings to the new version
- Preserves custom configuration

The migration process is designed to be safe and includes automatic rollback in case of failure.

### setup - Complete Environment Setup

Run initialization, build, start, and connect in one go.

```bash
dockit setup
```

This command provides a streamlined process by sequentially performing these tasks:
- Initializes the Docker development environment (equivalent to `init`)
- Builds the Docker image (equivalent to `build`)
- Starts the container (equivalent to `up`)
- Connects to the container (equivalent to `connect`)

At each step, you will be prompted to confirm whether you want to proceed, allowing you to stop at any point in the process. This is ideal for those who want to set up their entire environment with a single command while maintaining control over each step.

### run - Automated Run

Automatically run initialization, build, and start in one command.

```bash
dockit run
```

This command performs the following tasks without user confirmation prompts:
- Initializes the Docker development environment (equivalent to `init`)
- Builds the Docker image (equivalent to `build`)
- Starts the container in background (equivalent to `up`)

Unlike the `setup` command which prompts for confirmation at each step, the `run` command executes all operations automatically in sequence. This is ideal for scripts or situations where you want to perform all operations without interruption.

### join - Automated Run and Connect

Automatically run initialization, build, start and connect to container in one command.

```bash
dockit join
```

This command performs the following tasks:
- Initializes the Docker development environment (equivalent to `init`)
- Builds the Docker image (equivalent to `build`)
- Starts the container (equivalent to `up`)
- Connects to the container immediately (equivalent to `connect`)

The `join` command combines the functionality of both `run` and `connect` commands, providing a complete end-to-end workflow from initialization to interactive shell. This is perfect for when you want to start working in your development environment with a single command.

### ps - List Containers

List all dockit containers (running and stopped).

```bash
dockit ps
```

This command displays the following information for all containers created with dockit:
- Container ID (12 characters)
- Image name
- Container name (displayed in simplified form)
- Creation date and time
- Status (running or stopped, color-coded)
- IP address (for running containers)
- Exposed ports (for running containers)

Container names are displayed in a simplified form for better readability:
- The 'dockit-' prefix is removed
- The meaningful last part of the directory path is shown instead of the full path
  - Example: 'dockit-home-hgs-dockit-test-temp-b' → 'temp-b'

This feature is particularly useful when managing multiple dockit environments, making it easy to identify and check the status of containers created from different projects at a glance.

### help - Display Help

Display help information.

```bash
dockit help
```

## Configuration File

Dockit stores all settings in the `.dockit_project/.env` file. This file is created during the initialization process and includes the following information:

```
# Docker Tools Configuration File
# Auto-generated: [date]

# Container Settings
IMAGE_NAME="[image name]"
CONTAINER_NAME="[container name]"

# User Settings
USERNAME="[username]"
USER_UID="[UID]"
USER_GID="[GID]"
USER_PASSWORD="[password]"
WORKDIR="[working directory]"
```

This file can be manually edited as needed.

## Troubleshooting

### Initialization Issues

**Problem**: Initialization fails
**Solution**: 
- Check if Docker is running
- Check if you have the necessary permissions
- Delete the `.dockit_project` directory and try again

### Container Start Issues

**Problem**: Container does not start
**Solution**:
- Check for port conflicts
- Check if Docker service is running
- Check if the Docker image exists

### Container Connection Issues

**Problem**: Cannot connect to the container
**Solution**:
- Check if the container is running
- Check if the container name is correct
- Check if Docker commands can be executed

### Container Username Issues

**Problem**: The configured username (USERNAME) is different from the container's internal username
**Solution**:
- **From v1.2.0, this is automatically handled.** When UID conflict is detected, the password is automatically set for the existing container user.
- The container user information displayed by the `dockit status` command might be different if the base image already has a user with the same UID/GID.
- **What matters is whether the UID and GID match.** File system permissions are determined by UID/GID, not by names.
- **Sudo access**: You can use sudo commands with the password set for the existing user (e.g., ubuntu).
- If you encounter file permission issues, check with `dockit status` to verify that the container user's UID/GID matches your host system's user UID/GID.

### UID Conflict and Password Issues

**Problem**: Password setting fails when a user with the same UID already exists in the base image
**Solution**:
- **From v1.2.0, this is automatically resolved.** The Dockerfile automatically detects UID conflicts and sets passwords for existing users.
- If changes are not reflected due to Docker caching, use `dockit build --no-cache`.
- Manual verification: You can check the user account status by examining the `/etc/shadow` file inside the container. 