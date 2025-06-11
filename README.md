<p align="center">
  <img src="docs/logo.png" alt="Dockit Logo" width="400">
</p>

# Dockit - Docker Development Environment Tool

[English](docs/en/README.md) | [한국어](docs/ko/README.md)

[![Version](https://img.shields.io/badge/version-1.4.5-blue.svg)](bin/VERSION)
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
- **🔄 Real-time Docker status synchronization** - Automatic detection and reflection of external Docker changes
- **♻️ Image reuse functionality** - Reuse images from other projects for maximum resource efficiency
- **🗂️ Comprehensive image management** - Complete image management with list, remove, prune, clean commands
- **📊 Extended project state system** - Complete lifecycle management with none, ready, error states
- **📁 Directory name validation and auto-rename** - Automatic detection and conversion of uppercase directory names to Docker-compliant lowercase format
- Automatic application of current user settings (UID/GID) to container
- **UID conflict detection and automatic user handling**
- **Smart password assignment to actual container users**
- Host-container volume mount support
- **User-customizable Dockerfile support**
- **Docker image caching control with --no-cache option**
- **⚡ Parallel build processing** - Support for simultaneous multi-project builds
- Modular design for easy extension
- Clean project structure
- Multi-language support (English, Korean) and complete message system

## Commands

- `init`: Initialize Docker development environment (with image reuse option support)
- `start`: Start containers with auto-creation option (options: number, "this", "all")
- `build`: Build Docker development environment image (options: number, "this", "all", --no-cache)
- `up`: Start containers in background (options: number, "this", "all")
- `stop`: Stop containers (options: number, "this", "all")
- `down`: Remove containers completely (options: number, "this", "all")
- `connect`: Connect to container with auto-creation and auto-start options
- `status`: Check container status
- `setup`: Run initialization, build, start, and connect in one go
- `run`: Automatically initialize, build, and start container without interaction
- `list`: List all projects created with dockit (real-time Docker status synchronization)
- `ls`: List all projects created with dockit (alias for list)
- `image`: Docker image management (list, ls, remove, prune, clean)
- `migrate`: Upgrade to a newer version
- `help`: Display help information

## License

MIT License 