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

### start - Start Container

Start the initialized Docker container.

```bash
dockit start
```

This command performs the following tasks:
- Starts the container using Docker Compose
- Asks whether to connect to the container (optional)

### build - Build Docker Image

Build a Docker image for the development environment.

```bash
dockit build
```

This command performs the following tasks:
- Creates a temporary Dockerfile from a template
- Configures base image and user settings
- Builds a Docker image with appropriate configurations
- Useful when you need to rebuild or update the development environment image

### up - Start Container in Background

Start the container in background without connection prompt.

```bash
dockit up
```

This command performs the following tasks:
- Starts the container using Docker Compose in detached mode
- Does not ask for container connection
- Shows the container status information
- Useful for automated scripts or when you don't need to connect immediately

### stop - Stop Container

Stop a running container (preserving state).

```bash
dockit stop
```

This command stops the container but does not delete it. All data and settings are preserved, and you can restart it later with the `start` command.

### down - Remove Container

Completely remove the container.

```bash
dockit down
```

This command stops and removes the container. Be careful as all data stored in the container will be deleted.

### connect - Connect to Container

Connect to a running container.

```bash
dockit connect
```

This command connects to a running container through an interactive shell.

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
- This is normal behavior. The container user information displayed by the `dockit status` command might be different if the base image already has a user with the same UID/GID.
- What matters is whether the UID and GID match. File system permissions are determined by UID/GID, not by names.
- If you encounter file permission issues, check with `dockit status` to verify that the container user's UID/GID matches your host system's user UID/GID. 