<p align="center">
  <img src="../../docs/logo.png" alt="Dockit Logo" width="400">
</p>

# Dockit - Docker Development Environment Tool

[English](../../docs/en/README.md) | [한국어](../../docs/ko/README.md)

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

- [Detailed Manual](./MANUAL.md) - Complete guide to all Dockit features

## Key Features

- Docker development environment installation and configuration
- Container start/stop/remove management
- Container access and status checking
- Automatic application of current user settings (UID/GID) to container
- Host-container volume mount support
- Modular design for easy extension
- Clean project structure
- Multi-language support (English, Korean)

## Commands

Dockit provides the following main commands:

- `init`: Initialize and configure the development environment
- `start`: Start containers (options: number, "this", "all")
- `build`: Build Docker image for development environment
- `up`: Start the container in background (no connection prompt)
- `stop`: Stop containers (options: number, "this", "all")
- `down`: Remove the container completely
- `connect`: Connect to a running container
- `status`: Check container status
- `setup`: Run initialization, build, start, and connect in one go
- `run`: Automatically run initialization, build and start
- `join`: Automatically run initialization, build, start, and connect to container in one command
- `list`: List all containers created with dockit
- `migrate`: Upgrade to a newer version
- `help`: Display help information

## Project Structure

```
dockit/
├── bin/             # Executable scripts
├── src/             # Source code
│   ├── modules/     # Function-specific modules
│   └── templates/   # Dockerfile and docker-compose.yml templates
├── config/          # Configuration files
│   └── messages/    # Multilingual message files
└── docs/            # Documentation files
```

## License

MIT License 