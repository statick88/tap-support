# TikTok Tap Support 🎵

A terminal-based TikTok live tap counter application built with Go and Bubble Tea.

## Features

- **Auto-tapping**: Automatically counts taps without pressing any keys
- **User Change**: Easily switch between TikTok usernames
- **Session Tracking**: Track and save your tap sessions
- **Metrics**: View TikTok account metrics
- **History**: Review past tap sessions
- **Real-time Rate**: See taps per minute in real-time

## Installation

```bash
git clone https://github.com/statick88/tap-support.git
cd tap-support
go build -o tap-support ./cmd/tap-support
```

Or install directly:

```bash
go install github.com/statick/tap-support@latest
```

## Usage

```bash
./tap-support
```

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

## Configuration

- Default username: `yazgardea`
- Auto-tap rate: 10 taps per second (every 100ms)
- Data is stored in `./data` directory

Copy `.env.example` to `.env` if needed:

```bash
cp .env.example .env
```

## Tech Stack

- Go
- Bubble Tea (Charmbracelet)
- Lip Gloss (Charmbracelet)

## License

MIT
