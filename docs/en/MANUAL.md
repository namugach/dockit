# Dockit User Manual

This document explains how to use Dockit in detail.

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [New Key Features](#new-key-features)
    - [Real-time Docker Status Synchronization](#real-time-docker-status-synchronization)
    - [Image Reuse Feature](#image-reuse-feature)
    - [Expanded Project Status System](#expanded-project-status-system)
4. [Commands](#commands)
    - [init](#init---initialize)
    - [start](#start---start-container)
    - [build](#build---build-docker-image)
    - [up](#up---start-container-in-the-background)
    - [stop](#stop---stop-container)
    - [down](#down---remove-container)
    - [connect](#connect---connect-to-container)
    - [status](#status---check-status)
    - [list](#list---project-list)
    - [ls](#ls---quick-project-list)
    - [base](#base---base-image-management)
    - [image](#image---image-management)
    - [migrate](#migrate---version-upgrade)
    - [setup](#setup---full-environment-setup)
    - [run](#run---automatic-execution)
    - [ps](#ps---container-list)
    - [clone](#clone---project-clone)
    - [cleanup](#cleanup---zombie-resource-cleanup)
    - [network](#network---manage-networks)
    - [help](#help---help)
5. [Configuration Files](#configuration-files)
6. [Troubleshooting](#troubleshooting)

## Introduction

Dockit is a modular shell script tool designed to quickly set up and manage development environments using Docker. This tool provides a consistent development environment through Docker containers and helps configure the same environment across various operating systems.

Dockit's main goals are:
- To reduce the complexity of development environment setup
- To provide a consistent development environment
- To enhance the portability of development setups
- To configure a standardized environment for team collaboration

## Installation

### Requirements

- Docker must be installed.
- A Bash shell environment is required.

### Installation Guide

To install Dockit, execute the following commands:

```bash
# Clone the repository
git clone https://github.com/namugach/dockit.git
cd dockit

# Run the installation script
./bin/install.sh
```

This command installs Dockit on your system and adds the necessary paths to your shell environment.
After installation, you can use the `dockit` command from any directory.

### Uninstallation

To remove Dockit from your system:

```bash
./bin/uninstall.sh
```

## New Key Features

### Real-time Docker Status Synchronization

Starting from Dockit v1.3.0, the `dockit list` command synchronizes registry information with the actual Docker status in real-time.

#### Key Features:
- **Automatic Status Detection**: Checks the actual Docker image and container status for each project upon running `dockit list`.
- **External Change Detection**: Automatically reflects the status of images/containers changed directly via Docker commands.
- **Manual `error` Status Preservation**: The `error` status set by a build failure is not automatically changed.
- **Performance Optimization**: Safely skips if Docker is not available or registry files do not exist.

#### Example Scenario:
```bash
# Delete an image externally
docker image rm my-project-image

# Running dockit list will automatically change the status from ready → none
dockit list
```

### Image Reuse Feature

You can reuse an image already built in another project to improve development efficiency and save system resources.

#### How to Use:
```bash
dockit init
# Choose 'l - Reuse image' from the options
# Enter the absolute path of the project to reuse (e.g., /home/user/project)
```

#### Key Features:
- **Path-based Image Sharing**: Automatically generates and reuses the image name from the project at the given absolute path.
- **Image Existence Verification**: Automatically checks if the image from the specified path actually exists.
- **Safe Reuse**: Provides options to retry or cancel if the image does not exist.
- **Resource Efficiency**: Saves disk space by sharing the same base environment across multiple projects.

#### Use Cases:
- Using the same development environment for multiple projects.
- Sharing a standardized development image within a team.
- Reducing the time for building base images.

### Expanded Project Status System

New statuses have been added to more accurately track the entire project lifecycle.

#### New Statuses:
- **`none`**: The state after project initialization but before the image is built.
- **`ready`**: The state where the image build is complete and the container is ready to run.
- **`error`**: The state where an image build has failed or another error has occurred.

#### Existing Statuses:
- **`running`**: The container is currently running.
- **`stopped`**: The container is stopped.
- **`down`**: The container has been removed (the image may still exist).

#### State Transition Flow:
```
init → none → build → ready → up → running
                ↓              ↓
              error          stopped → down
```

#### Status Color Indicators:
- `none`: Blue
- `ready`: Cyan
- `error`: Red
- `running`: Green
- `stopped`: Yellow
- `down`: Gray

## Commands

Dockit provides the following commands:

### init - Initialize

Initializes and sets up the Docker development environment.

```bash
dockit init
```

This command performs the following tasks:
- Creates the `.dockit_project` directory.
- Gathers user configuration information.
- Builds a Docker image or reuses an existing one.
- Creates a `docker-compose.yml` file.

#### Directory Name Validation and Auto-Rename:

Before initialization, it automatically checks if the current directory name is compliant with Docker image naming rules.

**Key Features:**
- **Detects Uppercase**: Automatically checks for uppercase letters in the directory name.
- **Auto-conversion**: Converts camelCase to snake_case (e.g., `MyProject` → `my_project`).
- **Safe Renaming**: Checks if the target directory exists to prevent conflicts.
- **Auto-restart**: Automatically restarts initialization in the new directory after renaming.

**Example Scenario:**
```bash
# Current directory: /home/user/MyProject
dockit init

# A warning message is displayed:
# "The current directory name contains uppercase letters."
# "Docker image names only allow lowercase letters."
# 
# Current: /home/user/MyProject
# Suggested: /home/user/my_project
# 
# Do you want to rename the directory? [Y/n]: Y

# After automatic renaming, initialization restarts in the new directory.
```

**User Choices:**
- **Y (default)**: Renames the directory to the suggested name and continues initialization.
- **n**: Cancels the renaming, advising to use the current name or rename manually.

#### Initialization Options:

You can choose between two methods during initialization:

**1. Build a new image** (default option):
- Set username, UID/GID, password, working directory, etc.
- Choose a base image (Ubuntu, CentOS, Alpine, etc.).
- Build a new Docker image to create a custom environment for each project.

**2. Reuse an image** (`l - Reuse image` option):
- Reuse an image already built by another project.
- Enter the **absolute path** of the project to reuse (e.g., `/home/user/my-base-project`).
- The setup is completed after verifying the image's existence.

#### Image Reuse Workflow:
```bash
dockit init
# Choose 'l - Reuse image'
# Enter absolute path: /home/hgs/my-base-project
# The reuse setup is completed after verifying the image's existence.
```

#### Notes on Reusing Images:
- Extracts the image name from the `.dockit_project/.env` file at the specified path.
- Verifies that the image actually exists in Docker.
- If the image does not exist, it offers to retry or build a new one.

During initialization, you can configure the following:
- Username
- UID/GID
- Password
- Working directory
- Image name (for new builds) or the path of the image to reuse
- Container name

### Start Command

This command is used to start containers. It offers an option to automatically create and start a container if it doesn't exist.

Usage:
```bash
dockit start [option]
```

Options:
- (no arguments): Displays a list of available containers.
- `number`: Starts the container with the specified number from the list.
- `"this"`: Starts the container in the current project directory.
- `"all"`: Starts all dockit containers.

**Auto-creation Feature:**
If a container does not exist, you will be prompted:
- "The container does not exist. Do you want to create and start it? (Y/n)"
- Choosing 'Y' will automatically run `dockit up` to create and start the container.
- Choosing 'n' will cancel the operation.

Examples:
```bash
dockit start           # Display container list
dockit start 1         # Start container 1 (creates if not present)
dockit start 1 2 3     # Start containers 1, 2, and 3
dockit start this      # Start the container for the current project (creates if not present)
dockit start all       # Start all dockit containers
```

### build - Build Docker Image

Builds a Docker image for the development environment.

```bash
dockit build [option]
```

#### Options:
- (no arguments): Builds the image for the current project.
- `number`: Builds the project for the specified number from the list.
- `"this"`: Builds the image for the current project directory.
- `"all"`: Builds all dockit projects in parallel.
- `--no-cache`: Forces a rebuild of the image without using the Docker cache.

#### Usage Examples:
```bash
dockit build              # Build the current project (using cache)
dockit build 1            # Build project 1
dockit build this         # Build the current project
dockit build all          # Build all projects in parallel
dockit build --no-cache   # Force rebuild the current project without cache
dockit build 1 --no-cache # Build project 1 without cache
```

#### Key Features:
- **Parallel Build**: The `all` option saves time by building multiple projects simultaneously.
- **Isolated Build Failure**: A build failure in one project does not affect others.
- **Automatic State Management**: Automatically transitions to the `ready` state on success, and to the `error` state on failure.
- **Container Cleanup**: Automatically stops and removes the existing container before a build.

This command performs the following tasks:
- Builds an image using `.dockit_project/Dockerfile`.
- Applies user modifications to the Dockerfile in the build.
- Resolves Docker caching issues with the `--no-cache` option.
- Detects UID conflicts and handles user setup automatically.

#### Customizing Dockerfile:
You can directly modify the `.dockit_project/Dockerfile` created by `dockit init`:
- Install additional packages.
- Set environment variables.
- Add custom settings.
- Apply changes by running `dockit build` after modification.

#### Automatic UID Conflict Handling:
If a user with the same UID already exists in the base image:
- It automatically detects the existing user.
- Applies the set password to that user.
- Grants sudo privileges automatically.
- Ensures a smooth working environment without file permission issues.

### Up Command

Starts the container in the background without a connection prompt.

Usage:
```bash
dockit up [option]
```

Options:
- (no arguments): Displays a list of available containers.
- `number`: Starts the container with the specified number from the list.
- `"this"`: Starts the container in the current project directory.
- `"all"`: Starts all dockit containers.

This command performs the following tasks:
- Starts the container in detached mode using Docker Compose.
- Does not prompt for connection.
- Displays container status information.
- Useful for automation scripts or when immediate connection is not needed.

Examples:
```bash
dockit up             # Display container list
dockit up 1           # Start container 1
dockit up 1 2 3       # Start containers 1, 2, and 3
dockit up this        # Start the container for the current project
dockit up all         # Start all dockit containers
```

### Stop Command

This command is used to stop a running container. It preserves the container's state.

Usage:
```bash
dockit stop [option]
```

Options:
- (no arguments): Displays a list of available containers.
- `number`: Stops the container with the specified number from the list.
- `"this"`: Stops the container in the current project directory.
- `"all"`: Stops all dockit containers.

Examples:
```bash
dockit stop           # Display container list
dockit stop 1         # Stop container 1
dockit stop 1 2 3     # Stop containers 1, 2, and 3
dockit stop this      # Stop the container for the current project
dockit stop all       # Stop all dockit containers
```

### Down Command

Completely removes a container.

Usage:
```bash
dockit down [option]
```

Options:
- (no arguments): Displays a list of available containers.
- `number`: Removes the container with the specified number from the list.
- `"this"`: Removes the container in the current project directory.
- `"all"`: Removes all dockit containers.

This command stops and removes the container. Use with caution, as all data inside the container will be deleted.

Examples:
```bash
dockit down           # Display container list
dockit down 1         # Remove container 1
dockit down 1 2 3     # Remove containers 1, 2, and 3
dockit down this      # Remove the container for the current project
dockit down all       # Remove all dockit containers
```

### Connect Command

A container connection command with auto-creation and auto-start features.

Usage:
```bash
dockit connect [option]
```

Options:
- (no arguments): Displays usage information.
- `number`: Connects to the container with the specified number from the list.
- `"this"`: Connects to the container in the current project directory.

**Auto-creation and Auto-start Features:**

1.  **If the container does not exist:**
    - "The container does not exist. Would you like to create, start, and then connect? (Y/n)"
    - Choosing 'Y' will automatically run `dockit up` to create and start the container, then connect.
    - Choosing 'n' will cancel the operation.

2.  **If the container is stopped:**
    - "The container is stopped. Would you like to start it and then connect? (Y/n)"
    - Choosing 'Y' will start the container and then connect.
    - Choosing 'n' will cancel the operation.

3.  **If the container is running:**
    - It connects to the container immediately.

Examples:
```bash
dockit connect         # Display usage information
dockit connect 1       # Connect to container 1 (creates/starts if necessary)
dockit connect this    # Connect to the current project's container (creates/starts if necessary)
```

This command provides a seamless workflow to connect to any container with a single command, regardless of its current state.

### status - Check Status

Checks the current status of the container.

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

- **Container Status** (if the container exists):
  - Container ID
  - Running State
  - Creation Time
  - Image Information
  - IP Address (if running)
  - Port Information (if running)

Host user settings and container user information are always displayed separately, making it particularly useful for diagnosing permission issues. Even if the container has not yet been created, you can still check the host settings.

### list - Project List

Displays a list of all projects created with dockit, providing real-time Docker status synchronization.

```bash
dockit list [option]
```

#### Options:
- **-d, --delete**: Removes projects from the registry. You can remove multiple projects at once.

#### Key Features:

**Real-time Status Synchronization**:
- Checks the actual Docker status of each project every time the command is run.
- Automatically detects and reflects the status of Docker images/containers changed externally.
- Manually set `error` states are preserved and not automatically changed.

**Display Information**:
- Project number
- Project path (in a simplified form)
- Current project status (color-coded)
- Image name
- Container name

#### Status Color Display:
- **`none`** (blue): After initialization, before the image is built
- **`ready`** (cyan): Image build is complete, ready to run the container
- **`error`** (red): Build failed or another error occurred
- **`running`** (green): The container is running
- **`stopped`** (yellow): The container is stopped
- **`down`** (gray): The container has been removed

#### Synchronization Example:
```bash
# Delete an image directly using Docker
docker image rm my-project-image

# Running dockit list will automatically change the status from ready → none
dockit list
```

#### Path Display:
- Displays the home directory as `~`.
- Shows a simplified path for better readability.
- Displays a warning for projects with issues.

This feature ensures that the actual Docker status and registry information are always consistent when managing multiple projects.

### ls - Quick Project List

Displays a list of all projects created with dockit (an alias for the `list` command).

```bash
dockit ls
```

This is a convenient shorthand for the `list` command and provides the same functionality:
- Real-time Docker status synchronization
- Color-coded status display
- Project information overview

Perfect for a quick status check with less typing. All features of the `list` command are available through this alias.

### base - Base Image Management

Provides features to manage the base images (e.g., ubuntu, node, python) used in projects.

```bash
dockit base <command> [options]
```

#### Subcommands:

**1. list - View base image list**
```bash
dockit base list
# or
dockit base ls
```
- Displays all available base images with numbers.
- Marks the currently selected base image with a `*`.
- Example:
  ```
     1. * namugach/ubuntu-basic:24.04-kor (currently selected)
     2.   ubuntu:24.04
     3.   ubuntu:22.04
     4.   node:20
     5.   python:3.11
  ```

**2. set - Set base image**
```bash
dockit base set <image_or_number>
```
- Sets the default base image.
- Can be selected by image name or number.
- Examples:
  ```bash
  dockit base set ubuntu:22.04    # Set by name
  dockit base set 3               # Set by number
  ```

**3. add - Add base image**
```bash
dockit base add <image>
```
- Adds a new base image to the list.
- Examples:
  ```bash
  dockit base add golang:1.21
  dockit base add rust:1.70
  ```

**4. remove - Remove base image**
```bash
dockit base remove <image_or_number> [image2] [image3] ...
# or
dockit base rm <image_or_number> [image2] [image3] ...
```
- Removes base images from the list.
- Can remove multiple images at once.
- The currently selected image is automatically skipped.
- Examples:
  ```bash
  dockit base rm 5                    # Remove one
  dockit base rm 1 2 3                # Remove multiple by number
  dockit base rm ubuntu:20.04 node:18 # Remove multiple by name
  dockit base rm 1 ubuntu:22.04 3     # Mix numbers and names
  ```

**5. validate - Validate base images**
```bash
dockit base validate
# or
dockit base check
```
- Checks if all base images in the list actually exist.
- Validates image existence on Docker Hub.
- Displays a list of non-existent images.

**6. reset - Reset to defaults**
```bash
dockit base reset
```
- Resets the base image list to its default values.
- Executes after a confirmation prompt.

#### Key Features:

**Number-based Interface**:
- Allows selection with simple numbers instead of long image names.
- Easy and fast selection, like `dockit base set 2`.

**Multiple Operations Support**:
- Remove multiple images at once: `dockit base rm 1 2 3`.
- Freely mix numbers and names: `dockit base rm 1 ubuntu:22.04 3`.

**Smart Protection**:
- The currently selected base image is automatically skipped during removal.
- Provides a summary of the operation: "Removal completed: 2 successful, 1 skipped, 0 failed".

**Language Independent**:
- Allows free selection of base images regardless of language settings.
- Can use English base images even in a Korean environment.

#### Usage Scenarios:

**Basic Usage**:
```bash
# Check current base image list
dockit base list

# Switch to Ubuntu 22.04
dockit base set ubuntu:22.04

# Add new base image
dockit base add golang:1.21

# Clean up unnecessary images
dockit base rm 5 6 7
```

**Environment-specific Setup**:
```bash
# For Node.js projects
dockit base set node:20

# For Python projects
dockit base set python:3.11

# For Go projects
dockit base set golang:1.21
```

This functionality allows you to easily select and manage optimized base images for each project.

### image - Image Management

Provides comprehensive features for managing Docker images created by dockit.

```bash
dockit image <command> [options]
```

#### Subcommands:

**1. list - View image list**
```bash
dockit image list
# or
dockit image ls
```
- Displays all Docker images created by dockit in a table format.
- Includes number, image ID, creation date, size, and image name.
- Provides instructions on how to create an image if none exist.
- `ls` is a convenient alias for `list`.

**2. remove - Remove a specific image**
```bash
dockit image remove <image_name_or_number>
```
- Removes a specific image by its name or list number.
- Examples:
  ```bash
  dockit image remove 1                        # Remove by number
  dockit image remove dockit-home-user-project # Remove by name
  ```

**3. prune - Clean up unused images**
```bash
dockit image prune
```
- Finds and removes dockit images that are not being used by any container.
- Displays a list of images to be removed and the estimated space savings before deletion.
- Provides a safe confirmation prompt.
- **Safety Feature**: Protects base images registered in the local registry from being deleted.

**4. clean - Remove all images**
```bash
dockit image clean
```
- Completely removes all dockit images and their related containers.
- This is a very powerful feature and cannot be undone.
- It has a 2-stage safety confirmation process:
  1. First confirmation: Enter 'y' or 'yes'.
  2. Second confirmation: Enter 'DELETE' (in uppercase).

#### Key Features:

**Safety Measures**:
- Targets only dockit images to protect system images.
- Automatically detects and warns about containers using the images.
- Provides detailed information before removal (usage status, estimated space savings, etc.).

**Detailed Analysis**:
- Displays the usage status for each image (in use/unused).
- Provides container dependency information.
- Calculates the total number of images, images in use, and estimated space savings.

**Automated Cleanup**:
- The `clean` command also automatically stops and removes related containers.
- Visually indicates the progress of each step (✓/✗/⚠️).

#### Usage Scenarios:

**Regular Maintenance**:
```bash
# Clean up only unused images (safe)
dockit image prune

# Completely reset the development environment (requires caution)
dockit image clean
```

**Specific Image Management**:
```bash
# Check the image list
dockit image list

# Remove a specific image
dockit image remove 3
```

This feature allows you to effectively manage Docker image usage and optimize system resources.

### migrate - Upgrade Version

Upgrades Dockit to a new version while preserving user settings.

```bash
dockit migrate
```

This command performs the following tasks:
- Creates a backup of the current settings.
- Initializes the new version environment.
- Migrates user settings to the new version.
- Preserves user-customized settings.

The migration process is designed to be safe and includes an automatic rollback feature in case of failure.

### setup - Complete Environment Setup

Initializes, builds, starts, and connects to the container all at once.

```bash
dockit setup
```

This command provides a streamlined process by sequentially performing the following tasks:
- Initializes the Docker development environment (same as the `init` command).
- Builds the Docker image (same as the `build` command).
- Starts the container (same as the `up` command).
- Connects to the container (same as the `connect` command).

Since a confirmation prompt is displayed at each step, you can stop at any point. This command is ideal for users who want to set up the entire environment with a single command while still controlling each step.

### run - Automated Run

Automatically initializes, builds, and starts in one go.

```bash
dockit run
```

This command sequentially performs the following tasks without user confirmation prompts:
- Initializes the Docker development environment (same as the `init` command).
- Builds the Docker image (same as the `build` command).
- Starts the container in the background (same as the `up` command).

Unlike the `setup` command, which asks for user confirmation at each step, the `run` command executes all tasks automatically in sequence. This is ideal for scripts or situations where you want to perform all operations without interruption.

### ps - List Containers

Lists all containers created by dockit (both running and stopped).

```bash
dockit ps
```

This command displays the following information for all containers created with dockit:
- Container ID (12 characters)
- Image name
- Container name (in a simplified form)
- Creation date and time
- Status (running or stopped, color-coded)
- IP address (for running containers)
- Exposed ports (for running containers)

Container names are displayed in a simplified form for better readability:
- The 'dockit-' prefix is removed.
- It shows the meaningful last part of the directory name instead of the full path.
  - Example: 'dockit-home-hgs-dockit-test-temp-b' → 'temp-b'

Additionally, after the command execution, it provides useful `dockit` command combination examples based on the current container status to help you easily perform the next action.

This feature is very useful when managing multiple dockit environments, making it easy to distinguish and check the status of containers created from different projects at a glance.

### clone - Clone Project

Clones an existing Dockit project to create a new project with a similar environment. This command simplifies the process of duplicating a project setup, including its Docker image and configurations.

```bash
dockit clone <source_project> [new_project_name]
```

#### Arguments:

-   `<source_project>`: The source project to be cloned. It can be the project number from the `dockit ls` list, its full ID, or a unique prefix of the ID.
-   `[new_project_name]` (Optional): The name for the new, cloned project. If not provided, you will be prompted to enter a name.

#### Key Features:

-   **Image Committing**: Creates a new Docker image from the state of the source project's running container.
-   **Configuration Duplication**: Copies all configuration files from the source project's `.dockit_project` directory.
-   **Automatic Naming**: Suggests a name for the new project and handles potential name conflicts.
-   **Rollback Mechanism**: If any step of the cloning process fails, it automatically rolls back the changes, such as removing the created directory, image, and registry entry.
-   **Interactive and Non-interactive Modes**: Operates interactively by prompting for a new name, or non-interactively if the new name is provided as an argument.

#### Workflow:

1.  **Select Source**: Specify the project to clone.
2.  **Name New Project**: Provide a name for the new project, or let Dockit suggest one.
3.  **Container Check**: Ensures the source container is running, and starts it if it's stopped.
4.  **Image Creation**: Commits the running container to a new Docker image.
5.  **File Copying**: Duplicates the `.dockit_project` directory.
6.  **Configuration Update**: Updates the `.env` and `docker-compose.yml` files with the new project's name and image.
7.  **Registry Update**: Registers the new project in the Dockit registry.

#### Example Usage:

```bash
# List projects to find the source project number
dockit ls

# Clone project number 1 to a new project named "my_new_project"
dockit clone 1 my_new_project

# Clone a project and get prompted for a name
dockit clone 1
```

This command is ideal for quickly spinning up new projects based on a pre-configured "template" project, ensuring consistency and saving setup time.

### cleanup - Clean up zombie resources

Cleans up unused Docker resources (networks, volumes, etc.) to optimize the system.

```bash
dockit cleanup
```

This command finds and removes Docker networks and volumes that are no longer associated with any `dockit` projects. This allows you to safely clean up "zombie" resources that are unnecessarily consuming disk space.

#### Key Features:
- **Automatic Detection**: Automatically identifies networks and volumes that are not being used by any projects currently registered in the `dockit` registry.
- **Safe Cleanup**: It first shows a list of resources to be removed and proceeds with the actual deletion only after receiving user confirmation.
- **System Optimization**: Keeps your Docker environment clean and prevents potential conflicts by removing unnecessary resources.

### network - Manage Networks

Manages Docker networks created by dockit.

```bash
dockit network <subcommand>
```

#### Subcommands:

-   **ls, list**: Displays a list of all networks created by dockit.
-   **prune**: Finds and removes dockit networks that are not used by any container.

#### Usage Examples:

```bash
# View all dockit networks
dockit network ls

# Clean up unused networks
dockit network prune
```

### help - Display Help

Displays help information.

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