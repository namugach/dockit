# Dockit - Docker Development Environment Tool

Dockit is a modular shell script tool for quickly setting up and managing development environments using Docker.

## Features

- Docker development environment installation and configuration
- Container start/stop/remove management
- Container access and status checking
- Automatic application of current user settings (UID/GID) to container
- Host-container volume mount support
- Modular design for easy extension
- Clean project structure (generated files managed in .dockit directory)
- Multilingual support (Korean/English)

## Language Settings

Dockit supports both Korean and English. You can change the language settings in the following ways:

### Default Language Settings

- In WSL environment, Korean is set as the default language.
- In regular Linux environments, the language is automatically detected based on system locale.

### How to Change Language

1. Using environment variables:
```bash
LANGUAGE=ko ./dockit.sh status  # Run in Korean
LANGUAGE=en ./dockit.sh status  # Run in English
```

2. In settings.env file:
```bash
LANGUAGE=ko  # Set to Korean
LANGUAGE=en  # Set to English
LANGUAGE=local  # Use system locale
```

### Checking Language Information in Debug Mode

When debug mode is enabled, you can view detailed information about the current language settings:

```bash
DEBUG=true ./dockit.sh status
```

Output information:
- Currently selected language
- Language setting source (environment variable/config file/system locale)
- Locale settings
- Timezone settings

## Usage

### Basic Commands

```bash
./dockit.sh install   # Installation and initial setup
./dockit.sh start     # Start container
./dockit.sh stop      # Stop container (state preserved)
./dockit.sh down      # Completely remove container
./dockit.sh connect   # Access container
./dockit.sh status    # Check container status
./dockit.sh help      # Display help
```

### Installation Process

When running the `install` command, you can configure the following settings:

- Username: Current logged-in user (auto-detected)
- UID/GID: Current user's UID/GID (auto-detected)
- Password: Default "1234"
- Working Directory: Default "work/project"
- Image Name: Default "my-ubuntu"
- Container Name: Default "my-container"

## Directory Structure

```
./
├── dockit.sh                     # Main script
├── src/                          # Source code directory
│   ├── modules/                  # Module directory
│   │   ├── common.sh             # Common functions module
│   │   ├── install.sh            # Installation module
│   │   ├── start.sh              # Start module
│   │   ├── stop.sh               # Stop module
│   │   ├── down.sh               # Remove module
│   │   ├── connect.sh            # Access module
│   │   ├── status.sh             # Status check module
│   │   └── help.sh               # Help module
│   └── templates/                # Template files directory
│       ├── Dockerfile.template   # Docker image template
│       └── docker-compose.yml.template # Docker Compose template
├── .dockit/                      # Generated files directory (auto-generated)
│   ├── .env                      # User settings file
│   ├── docker-compose.yml        # Docker Compose configuration file
│   └── dockit.log                # Log file
└── README.md                     # This file
```

## Auto-generated Files

All files generated during installation and execution are stored in the `.dockit` directory:

- `.dockit/.env`: User settings file
- `.dockit/docker-compose.yml`: Docker Compose configuration file
- `.dockit/dockit.log`: Log file

This structure keeps the project root directory clean and makes it easy to exclude generated files from version control systems.

## Docker Image Information

The default image is `ubuntu:24.04` and includes the following tools:

- sudo
- git
- English locale settings

## Container Management Commands

Dockit provides the following commands for container management:

- `start`: Starts the container. Creates a new one if it doesn't exist.
- `stop`: Stops the container. State is preserved for later restart.
- `down`: Completely removes the container. All data inside the container is deleted.
- `connect`: Accesses a running container.
- `status`: Checks the current status of the container.

## Development Philosophy

This project follows these principles:

1. Modular Structure - Each function is separated for easy maintenance
2. Clear Separation of Configuration and Source Files - Distinguishes between static and dynamic files
3. User-friendly Interface - Interactive installation and clear status display
4. Container Internal User Permission Issues Resolution - Uses same UID/GID as host 