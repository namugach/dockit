# Dockit User Manual

This document explains the detailed usage of Dockit.

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [New Major Features](#new-major-features)
    - [Real-time Docker Status Synchronization](#real-time-docker-status-synchronization)
    - [Image Reuse Functionality](#image-reuse-functionality)
    - [Extended Project State System](#extended-project-state-system)
4. [Commands](#commands)
    - [init](#init---initialization)
    - [start](#start---start-container)
    - [build](#build---build-docker-image)
    - [up](#up---start-container-in-background)
    - [stop](#stop---stop-container)
    - [down](#down---remove-container)
    - [connect](#connect---connect-to-container)
    - [status](#status---check-status)
    - [list](#list---project-list)
    - [image](#image---image-management)
    - [migrate](#migrate---upgrade-version)
    - [setup](#setup---complete-environment-setup)
    - [run](#run---automated-run)
    - [join](#join---automated-run-and-connect)
    - [ps](#ps---list-containers)
    - [help](#help---display-help)
5. [Configuration File](#configuration-file)
6. [Troubleshooting](#troubleshooting)

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

## New Major Features

### Real-time Docker Status Synchronization

Starting from Dockit v1.3.0, the `dockit list` command automatically synchronizes registry information with actual Docker status in real-time.

#### Key Features:
- **Automatic state detection**: Checks actual Docker image and container status for each project when running `dockit list`
- **External change detection**: Automatically reflects image/container status changes made directly with Docker commands
- **Manual error state preservation**: `error` states set due to build failures are not automatically changed
- **Performance optimization**: Safely skips when Docker is unavailable or registry files don't exist

#### Example Usage:
```bash
# Delete image externally
docker image rm my-project-image

# Running dockit list automatically changes state from ready → none
dockit list
```

### Image Reuse Functionality

You can reuse images already built by other projects to increase development efficiency and save system resources.

#### Usage:
```bash
dockit init
# Select 'l - Reuse image' from the options
# Enter the absolute path of the project to reuse (e.g., /home/user/project)
```

#### Key Features:
- **Path-based image sharing**: Input absolute path to share images from that project
- **Automatic validation**: Checks if the specified path's image exists
- **Resource efficiency**: Saves build time and system resources
- **Safe reuse**: Validates image existence before reuse setup

#### Workflow:
```bash
dockit init
# Select 'l - Reuse image'
# Enter absolute path: /home/hgs/my-base-project
# Image existence verified and reuse configured
```

#### Important Notes:
- Extracts image name from `.dockit_project/.env` file at the specified path
- Verifies that the image actually exists in Docker
- Prompts for retry if image doesn't exist
- Original project's image settings are preserved

### Extended Project State System

Dockit v1.3.0 introduces an expanded state system for complete project lifecycle management.

#### New States:
- **`none`**: After initialization, before build
- **`ready`**: Image build completed, ready to run
- **`error`**: Build failed or error state

#### Existing States:
- **`running`**: Container is currently running
- **`stopped`**: Container exists but is stopped
- **`down`**: Container has been removed

#### Complete Lifecycle:
```
init → none → build → ready → up → running → stop → stopped → down → ready
                ↓ (build failure)
              error
```

#### State Color Display:
- **`none`** (blue): After initialization, before build
- **`ready`** (cyan): Image build completed, ready to run
- **`error`** (red): Build failed or error state
- **`running`** (green): Container running
- **`stopped`** (yellow): Container stopped
- **`down`** (gray): Container removed

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
- Builds a Docker image or reuses an existing image
- Creates a docker-compose.yml file

#### Initialization Options:

During initialization, you can choose between two approaches:

**1. Build New Image** (default option):
- Configure username, UID/GID, password, working directory, etc.
- Select base image (Ubuntu, CentOS, Alpine, etc.)
- Build a new Docker image for project-specific customized environment

**2. Image Reuse** (`l - Reuse image` option):
- Reuse an image already built by another project
- Enter the **absolute path** of the project to reuse (e.g., `/home/user/my-project`)
- Automatically validates image existence
- Saves system resources and build time

#### Image Reuse Workflow:
```bash
dockit init
# Select 'l - Reuse image'
# Enter absolute path: /home/hgs/my-base-project
# Image existence verified and reuse setup complete
```

#### Important Notes for Reuse:
- Extracts image name from `.dockit_project/.env` file at the specified path
- Verifies that the image actually exists in Docker
- Prompts for retry if image doesn't exist
- Preserves original project's image configuration
- The reusing project inherits the image but maintains its own container settings

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
- (no arguments): Build current project image
- `number`: Build image for specified project number
- `"this"`: Build image for current project directory
- `"all"`: Build all dockit projects in parallel
- `--no-cache`: Forces a rebuild of the image without using Docker cache

#### Usage Examples:
```bash
dockit build              # Build current project (with cache)
dockit build 1            # Build project number 1
dockit build this         # Build current project
dockit build all          # Build all projects in parallel
dockit build --no-cache   # Force rebuild current project without cache
dockit build 1 --no-cache # Build project 1 without cache
```

#### Key Features:
- **Parallel builds**: When using `all` option, builds multiple projects simultaneously to save time
- **Isolated build failures**: One project's build failure doesn't affect other projects
- **Automatic state management**: Automatically transitions to `ready` state on success, `error` state on failure
- **Container cleanup**: Automatically stops and removes existing containers before building
- **Cache control**: Use `--no-cache` to force complete rebuild when needed

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

### list - Project List

Display all projects created with dockit and provide real-time Docker status synchronization.

```bash
dockit list
```

#### Key Features:

**Real-time Status Synchronization**:
- Checks actual Docker status for each project every time the command runs
- Automatically detects and reflects Docker image/container status changes made externally
- Manual `error` states are excluded from automatic changes and preserved

**Display Information**:
- Project number
- Project path (in simplified form)
- Current project status (color-coded)
- Image name
- Container name

#### Status Color Display:
- **`none`** (blue): After initialization, before build
- **`ready`** (cyan): Image build completed, ready to run
- **`error`** (red): Build failed or error state
- **`running`** (green): Container running
- **`stopped`** (yellow): Container stopped
- **`down`** (gray): Container removed

#### Synchronization Example:
```bash
# Delete image directly with Docker
docker image rm my-project-image

# Running dockit list automatically changes state from ready → none
dockit list
```

#### Path Display:
- Uses `~` shorthand for home directory
- Shows simplified paths for better readability
- Marks invalid projects with warning indicators

### image - Image Management

Provides comprehensive functionality for managing Docker images created by dockit.

```bash
dockit image <command> [options]
```

#### Subcommands:

**1. list - View image list**
```bash
dockit image list
```
- Displays all Docker images created by dockit in table format
- Includes number, image ID, creation date, size, and image name
- Provides guidance on image creation if no images exist

**2. remove - Remove specific image**
```bash
dockit image remove <image_name_or_number>
```
- Removes specific image by name or list number
- Examples:
  ```bash
  dockit image remove 1                        # Remove by number
  dockit image remove dockit-home-user-project # Remove by name
  ```

**3. prune - Clean unused images**
```bash
dockit image prune
```
- Finds and removes dockit images not used by any containers
- Shows image list and estimated space savings before removal
- Provides safe confirmation prompt

**4. clean - Remove all images**
```bash
dockit image clean
```
- Completely removes all dockit images and related containers
- Very powerful feature that cannot be undone
- 2-stage safety confirmation process:
  1. First confirmation: Enter 'y' or 'yes'
  2. Second confirmation: Enter 'DELETE' (uppercase)

#### Key Features:

**Safety Measures**:
- Targets only dockit images to protect system images
- Automatically detects and warns about containers using images
- Provides detailed information before removal (usage status, estimated space savings, etc.)

**Detailed Analysis**:
- Shows usage status for each image (in use/unused)
- Provides container dependency information
- Calculates total images, images in use, and estimated space savings

**Automated Cleanup**:
- `clean` command automatically stops and removes related containers
- Visual progress indicators for each step (✓/✗/⚠️)

#### Usage Scenarios:

**Regular Maintenance**:
```bash
# Clean only unused images (safe)
dockit image prune

# Complete development environment reset (caution required)
dockit image clean
```

**Specific Image Management**:
```bash
# Check image list
dockit image list

# Remove specific image
dockit image remove 3
```

This functionality allows you to effectively manage Docker image usage and optimize system resources.

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