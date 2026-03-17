# TikTok Tap Support - Execution Screenshots

> **Built by Statick | https://statick.dev**

This document shows the visual representation of the TikTok Tap Support application in execution.

## Main Counter View (Default)

```
╔══════════════════════════════════════════════════════════════════════╗
║                      🎵 TikTok Tap Counter 🎵                         ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║                              1,234                                   ║
║                                                                      ║
║                         600 taps/min                                 ║
║                                                                      ║
║                         ⏱️ 00:02:03                                  ║
║                                                                      ║
║                         User: yazgardea                              ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║  [Space/t] Tap | [s] Start/Stop | [r] Reset | [u] User | [m] Metrics ║
║  [h] History | [q] Quit                                               ║
╚══════════════════════════════════════════════════════════════════════╝
```

### Visual Elements:
- **Counter Display**: Large, bold cyan number (1,234) showing total taps
- **Rate Display**: Green text showing taps per minute (600 taps/min)
- **Timer**: Gray timestamp showing elapsed time (00:02:03)
- **User Info**: Current TikTok username being tracked

## Auto-Tapping Mode Indicator

When auto-tapping is active (default on startup):
```
╔══════════════════════════════════════════════════════════════════════╗
║                      🎵 TikTok Tap Counter 🎵                         ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║                         ▶ AUTO-TAPPING ON                            ║
║                                                                      ║
║                              5,678                                   ║
║                                                                      ║
║                         600 taps/min                                 ║
║                                                                      ║
║                         ⏱️ 00:09:28                                  ║
║                                                                      ║
║                         User: yazgardea                              ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║  [Space] Toggle Auto-Tap | [s] Stop | [r] Reset | [u] User | [m] Metrics║
║  [h] History | [q] Quit                                               ║
╚══════════════════════════════════════════════════════════════════════╝
```

## Metrics View (Press M)

```
╔══════════════════════════════════════════════════════════════════════╗
║                   📊 TikTok Account Metrics                           ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║                    Enter TikTok username:                            ║
║                    ████████████████████_                              ║
║                                                                      ║
║                    (Press Enter to fetch)                           ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║  [Enter] Fetch | [c] Counter | [u] User | [h] History | [q] Quit     ║
╚══════════════════════════════════════════════════════════════════════╝
```

## Metrics Result Display

```
╔══════════════════════════════════════════════════════════════════════╗
║                   📊 Account: yazgardea                               ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  ┌─────────────────────────────────────────────────────────────────┐  ║
║  │  Followers:     125,432                                        │  ║
║  │  Following:     892                                            │  ║
║  │  Total Likes:   2,456,789                                      │  ║
║  │  Videos:        234                                            │  ║
║  └─────────────────────────────────────────────────────────────────┘  ║
║                                                                      ║
║                          ✓ Loaded from cache                        ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║  [c] Counter | [m] Refresh | [u] User | [h] History | [q] Quit       ║
╚══════════════════════════════════════════════════════════════════════╝
```

## History View (Press H)

```
╔══════════════════════════════════════════════════════════════════════╗
║                     📜 Session History                               ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║  ┌─────────────────────────────────────────────────────────────────┐  ║
║  │  2024-03-16 23:15:26  │ 688 taps │ 6.4 min │ 107.5 taps/min     │  ║
║  ├─────────────────────────────────────────────────────────────────┤  ║
║  │  2024-03-16 23:12:45  │ 512 taps │ 5.1 min │ 100.4 taps/min     │  ║
║  ├─────────────────────────────────────────────────────────────────┤  ║
║  │  2024-03-16 23:08:12  │ 890 taps │ 8.2 min │ 108.5 taps/min     │  ║
║  ├─────────────────────────────────────────────────────────────────┤  ║
║  │  2024-03-16 22:45:33  │ 234 taps │ 3.5 min │  66.9 taps/min     │  ║
║  └─────────────────────────────────────────────────────────────────┘  ║
║                                                                      ║
║  Total Sessions: 47 | Average: 95.2 taps/min                         ║
║                                                                      ║
╠══════════════════════════════════════════════════════════════════════╣
║  [c] Counter | [m] Metrics | [q] Quit                                 ║
╚══════════════════════════════════════════════════════════════════════╝
```

## Color Palette

The application uses a modern dark theme with vibrant colors:

| Element | Color | Hex Code |
|---------|-------|----------|
| Header | Coral Red | #FF6B6B |
| Counter | Teal | #4ECDC4 |
| Rate | Mint Green | #95E1D3 |
| Timer | Gray | #A8A8A8 |
| Labels | Dark Gray | #666666 |
| Background | Dark Navy | #1A1A2E |
| Help Text | Light Gray | #888888 |

## Keyboard Shortcuts Summary

| Key | Action | Description |
|-----|--------|-------------|
| `Space` | Toggle Auto-Tap | Enable/disable automatic tap counting |
| `T` | Manual Tap | Add one tap (when auto-tap is off) |
| `S` | Start/Stop Session | Begin or end a counting session |
| `R` | Reset | Reset counter to 0 |
| `U` | Change User | Enter a different TikTok username |
| `M` | Metrics View | View account metrics |
| `H` | History View | See past sessions |
| `Q` | Quit | Exit the application |

## Session Data Format

Each session is saved to `data/sessions.json`:

```json
{
  "id": "Sostenida-tap-0-1773720926052114000",
  "timestamp": "2026-03-16T23:15:26.052126-05:00",
  "type": "normal",
  "data": {
    "message": "Tap complejo",
    "metadata": {
      "session_id": 6470,
      "timestamp": 1773720926052125000,
      "user_id": 434
    },
    "value": 688
  },
  "duration": 104
}
```

---

**Built by Statick | https://statick.dev**
**Last Updated: March 2026**