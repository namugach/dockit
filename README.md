<p align="center">
  <img src="docs/logo.png" alt="Dockit Logo" width="400">
</p>

# Dockit - Docker Development Environment Tool

[English](docs/en/README.md) | [한국어](docs/ko/README.md)

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](bin/VERSION)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](docs/meta/LICENSE)

Dockit is a modular shell script tool for quickly setting up and managing development environments using Docker.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/namugach/dockit.git
cd dockit

# Install Dockit to your system
./bin/install.sh

# Initialize a new development environment
dockit init
```

This will install Dockit to your system and make the `dockit` command available in your path. After installation, you can use Dockit from any directory.

## Uninstallation

To remove Dockit from your system:

```bash
./bin/uninstall.sh
```

## Documentation

- [English Manual](docs/en/MANUAL.md) - Detailed usage instructions
- [한국어 메뉴얼](docs/ko/MANUAL.md) - 자세한 사용 방법
- [Changelog](docs/meta/CHANGELOG.md) - Version history and changes
- [Project Description](docs/meta/DESCRIPTION.md) - Detailed project description

## Language Selection

- [English Documentation](docs/en/README.md)
- [한국어 문서](docs/ko/README.md)

## Features

- Docker development environment installation and configuration
- Container start/stop/remove management
- Container access and status checking
- Automatic application of current user settings (UID/GID) to container
- Host-container volume mount support
- Modular design for easy extension
- Clean project structure
- Multi-language support (English, Korean)

## Commands

- `init`: Initialize and configure the development environment
- `start`: Start containers with auto-creation option (options: number, "this",  "all")
- `build`: Build Docker image for development environment
- `up`: Start containers in background (options: number, "this", "all")
- `stop`: Stop containers (options: number, "this",  "all")
- `down`: Remove containers completely (options: number, "this", "all")
- `connect`: Connect to container with auto-creation and auto-start options
- `status`: Check container status
- `migrate`: Upgrade to a newer version
- `run`: Automatically initialize, build, and start container without interaction
- `join`: Automatically initialize, build, start, and connect to container in one command
- `list`: List all containers created with dockit
- `help`: Display help information

## License

MIT License 