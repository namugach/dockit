# Dockit User Manual

This document explains the detailed usage of Dockit.

## Table of Contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Commands](#commands)
    - [init](#init---initialization)
    - [start](#start---start-container)
    - [up](#up---start-container-in-background)
    - [stop](#stop---stop-container)
    - [down](#down---remove-container)
    - [connect](#connect---connect-to-container)
    - [status](#status---check-status)
    - [migrate](#migrate---upgrade-version)
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
- Container name
- Container ID
- Running state
- Creation time
- Image information
- IP address (if running)
- Port information (if running)

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