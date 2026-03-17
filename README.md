# TikTok Tap Support 🎵

[![Go Version](https://img.shields.io/github/go-mod/go-version/statick88/tap-support)](https://github.com/statick88/tap-support)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Go Report Card](https://goreportcard.com/badge/github.com/statick88/tap-support)](https://goreportcard.com/report/github.com/statick88/tap-support)
[![CI/CD](https://github.com/statick88/tap-support/actions/workflows/ci.yml/badge.svg)](https://github.com/statick88/tap-support/actions)
[![Docker](https://img.shields.io/docker/pulls/statick/tap-support)](https://hub.docker.com/r/statick/tap-support)
[![Stars](https://img.shields.io/github/stars/statick88/tap-support)](https://github.com/statick88/tap-support)

> **Built by Statick** | https://statick.dev
> A terminal-based TikTok live tap counter application built with Go and Bubble Tea.

## ✨ Features

- **Auto-tapping**: Automatically counts taps without pressing any keys
- **User Change**: Easily switch between TikTok usernames
- **Session Tracking**: Track and save your tap sessions
- **Metrics**: View TikTok account metrics (followers, likes, videos)
- **History**: Review past tap sessions with timestamps
- **Real-time Rate**: See taps per minute in real-time
- **Dark Mode**: Beautiful terminal UI with Lipgloss styling

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/statick88/tap-support.git
cd tap-support

# Run setup script (optional)
./setup.sh

# Or build manually
make build

# Run the application
make run
```

### Manual Installation

```bash
# Build the binary
go build -o tap-support ./cmd/tap-support

# Run the application
./tap-support
```

### Docker Installation

```bash
# Pull the image
docker pull statick/tap-support:latest

# Run the container
docker run -it --rm -e TIKTOK_USERNAME=yourusername statick/tap-support:latest
```

## 📖 Usage

### Basic Usage

```bash
# Run with default settings (auto-tap, 10 taps/sec)
./bin/tap-support

# Run with custom username
TIKTOK_USERNAME=yazgardea ./bin/tap-support

# Run with custom tap rate (taps per second)
TIKTOK_TAP_RATE=20 ./bin/tap-support

# Run without auto-tapping (manual mode)
TIKTOK_AUTO_TAP=false ./bin/tap-support
```

### Parallel Execution (Multiple Instances)

Run multiple instances simultaneously using the launcher script:

```bash
# Run a single instance
./run-multi.sh yazgardea

# Run with custom tap rate
./run-multi.sh -r 20 yazgardea

# Run with custom instance ID (for parallel execution)
./run-multi.sh -i instance1 user1
./run-multi.sh -i instance2 user2
./run-multi.sh -i instance3 user3

# Run in manual mode (no auto-tap)
./run-multi.sh -n user1

# List running instances
./run-multi.sh --list

# Stop a specific instance
./run-multi.sh --stop instance1

# Stop all instances
./run-multi.sh --killall
```

#### Example: Running 3 parallel instances

```bash
# Terminal 1
./run-multi.sh -i cuenta1 -r 10 cuenta1

# Terminal 2
./run-multi.sh -i cuenta2 -r 15 cuenta2

# Terminal 3
./run-multi.sh -i cuenta3 -r 20 cuenta3
```

Each instance will have its own:
- Storage directory (`data/cuenta1/`, `data/cuenta2/`, `data/cuenta3/`)
- Independent counter and session tracking
- Configurable tap rate

### Controls

| Key | Action |
|-----|--------|
| `Space` | Pause/Resume auto-tapping |
| `T` | Manual tap (when auto-tap is off) |
| `U` | Change TikTok username |
| `S` | Start/Stop session |
| `R` | Reset counter |
| `M` | View metrics |
| `H` | View history |
| `Q` | Quit |

### Configuration

Copy `.env.example` to `.env` if needed:

```bash
cp .env.example .env
```

#### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TIKTOK_USERNAME` | TikTok username to track | `yazgardea` |
| `TIKTOK_AUTO_TAP` | Enable auto-tapping (`true`/`false`) | `true` |
| `TIKTOK_TAP_RATE` | Taps per second (1-100) | `10` |
| `TIKTOK_STORAGE_PATH` | Data storage directory | `./data` |
| `TIKTOK_INSTANCE_ID` | Unique ID for parallel execution | (none) |

Edit the configuration in `config.yaml`:

```yaml
app:
  name: "TikTok Tap Support"
  version: "1.0.0"

storage:
  path: "./data"
  history_limit: 100

ui:
  refresh_rate_ms: 1000
  default_view: "counter"
```

## 🛠️ Development

### Prerequisites

- Go 1.24 or later
- Make (optional)

### Available Commands

```bash
# Build the application
make build

# Run tests
make test

# Run with coverage
make coverage

# Run linters
make lint

# Run in development mode
make dev

# Run stress test
make run-stress

# Build Docker image
make docker-build

# Install to system
make install

# Show help
make help
```

## 🏗️ Architecture

This project follows **Clean Architecture** principles:

```
cmd/tap-support/          # Entry point
internal/
  ├── application/         # Use cases
  │   ├── counter.go
  │   ├── history.go
  │   └── metrics.go
  ├── domain/              # Business entities
  │   ├── account.go
  │   ├── errors.go
  │   ├── history.go
  │   └── session.go
  ├── infrastructure/      # External services
  │   ├── storage/
  │   │   └── json.go
  │   └── tiktok/
  │       └── client.go
  └── ui/                  # TUI components
      ├── app.go
      └── ...
```

## 🔒 Security

- No hardcoded secrets - all configuration via environment variables
- Input sanitization for TikTok usernames
- Security scanning in CI/CD pipeline (gosec)

## 📦 Tech Stack

- **Language**: Go 1.24
- **TUI Framework**: [Bubble Tea](https://github.com/charmbracelet/bubbletea) (Charmbracelet)
- **Styling**: [Lipgloss](https://github.com/charmbracelet/lipgloss)
- **Configuration**: YAML + dotenv

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a PR.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `make test`
5. Run linters: `make lint`
6. Submit a Pull Request

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- [Charmbracelet](https://charm.sh/) for the amazing TUI libraries
- All contributors and users

---

**Built by Statick** | https://statick.dev | https://github.com/statick88