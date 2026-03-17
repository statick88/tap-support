# Design: TikTok Tap Support - Core App

## Technical Approach

Aplicación TUI construida con Go + Bubble Tea siguiendo Clean Architecture. La app funciona como contador manual donde el usuario da taps fisicamente y la app los registra mediante teclas. Las métricas de cuenta se obtienen via web scraping de datos públicos de TikTok.

## Architecture Decisions

### Decision: Clean Architecture con Capas Hexagonales

**Choice**: UI → Application → Domain → Infrastructure
**Alternatives considered**: MVC, arquitectura monolítica
**Rationale**: Separación clara de responsabilidades, fácil testing, escalabilidad

### Decision: Bubble Tea para TUI

**Choice**: charmbracelet/tea + lipgloss
**Alternatives considered**: tview, gocui, textual
**Rationale**: Moderno, buen soporte, bien mantenido, API limpia

### Decision: Web Scraping para Métricas

**Choice**: Scraping de página pública de TikTok (sin API oficial)
**Alternatives considered**: API no oficial de terceros, mock de datos
**Rationale**: No requiere autenticación, datos públicos, sin riesgo de ban

### Decision: Almacenamiento Local con JSON

**Choice**: Archivos JSON locales para historial de sesiones
**Alternatives considered**: SQLite, base de datos embebida
**Rationale**: Simple, sin dependencias externas, suficiente para uso personal

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI Layer (Bubble Tea)                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ CounterView │  │ MetricsView │  │ HistoryView │            │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘            │
└─────────┼─────────────────┼─────────────────┼──────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐ │
│  │ CounterService  │  │ MetricsService  │  │HistoryService │ │
│  └────────┬────────┘  └────────┬────────┘  └───────┬────────┘ │
└───────────┼─────────────────────┼───────────────────┼──────────┘
            │                     │                   │
            ▼                     ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Domain Layer                              │
│  ┌─────────┐  ┌──────────┐  ┌──────────┐  ┌────────────────┐  │
│  │ Session │  │ Account   │  │ Metrics  │  │ SessionHistory │  │
│  └─────────┘  └──────────┘  └──────────┘  └────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
            │                     │                   │
            ▼                     ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                          │
│  ┌─────────────────────────┐  ┌────────────────────────────┐  │
│  │ TikTokScraper           │  │ FileStorage                │  │
│  │ (HTTP Client + Parser)  │  │ (JSON read/write)          │  │
│  └─────────────────────────┘  └────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `go.mod` | Create | Module definition, dependencies |
| `internal/domain/session.go` | Create | Session entity |
| `internal/domain/account.go` | Create | Account entity |
| `internal/domain/metrics.go` | Create | Metrics value objects |
| `internal/application/counter.go` | Create | Counter use case |
| `internal/application/metrics.go` | Create | Metrics use case |
| `internal/application/history.go` | Create | History use case |
| `internal/infrastructure/tiktok/client.go` | Create | TikTok scraper |
| `internal/infrastructure/storage/json.go` | Create | JSON file storage |
| `internal/ui/models/counter.go` | Create | Counter TUI model |
| `internal/ui/models/metrics.go` | Create | Metrics TUI model |
| `internal/ui/views/main.go` | Create | Main view handler |
| `cmd/tap-support/main.go` | Create | Entry point |
| `config.yaml` | Create | Application config |
| `.env.example` | Create | Environment variables template |

## Interfaces / Contracts

```go
// Domain
type Session struct {
    ID        string
    Username  string
    TapCount  int
    StartTime time.Time
    EndTime   *time.Time
    Rate      float64 // taps per minute
}

type Account struct {
    Username   string
    Followers int
    Following int
    Likes     int
    Videos    int
}

type SessionHistory struct {
    Sessions []Session
    LastN    int
}

// Application Layer Interfaces
type CounterService interface {
    StartSession()
    StopSession() Session
    ResetSession()
    IncrementTap()
    GetCurrentSession() *Session
}

type MetricsService interface {
    GetAccountMetrics(username string) (*Account, error)
}

type HistoryService interface {
    SaveSession(session Session) error
    GetHistory(limit int) ([]Session, error)
}

// Infrastructure Layer Interfaces
type TikTokClient interface {
    FetchAccountMetrics(username string) (*Account, error)
}

type Storage interface {
    Save(key string, data interface{}) error
    Load(key string, dest interface{}) error
}
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | Domain entities, service logic | table-driven tests |
| Unit | Rate calculation, time formatting | unit tests with mocks |
| Integration | TikTok scraper | integration tests (may be skipped in CI) |
| Integration | JSON storage | integration tests with temp files |

## Migration / Rollout

No migration required - new application.

## Open Questions

- [ ] Should we support multiple TikTok accounts in one session?
- [ ] Should we add export to CSV for session history?
- [ ] How to handle TikTok page structure changes?
