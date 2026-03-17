# Tasks: TikTok Tap Support - Core App

## Phase 1: Infrastructure & Setup

- [x] 1.1 Initialize Go module with `go mod init github.com/statick/tap-support`
- [x] 1.2 Add dependencies: `github.com/charmbracelet/bubbletea`, `github.com/charmbracelet/lipgloss`, `github.com/joho/godotenv`
- [x] 1.3 Create `config.yaml` with app settings (storage path, default history limit)
- [x] 1.4 Create `.env.example` with `TIKTOK_STORAGE_PATH` variable
- [x] 1.5 Create `cmd/tap-support/main.go` with basic entry point

## Phase 2: Domain Layer

- [x] 2.1 Create `internal/domain/session.go` with Session struct and methods
- [x] 2.2 Create `internal/domain/account.go` with Account struct
- [x] 2.3 Create `internal/domain/metrics.go` with Metrics value objects
- [x] 2.4 Create `internal/domain/errors.go` with domain-specific errors

## Phase 3: Application Layer (Services)

- [x] 3.1 Create `internal/application/counter.go` with CounterService interface and implementation
- [x] 3.2 Create `internal/application/metrics.go` with MetricsService interface and implementation
- [x] 3.3 Create `internal/application/history.go` with HistoryService interface and implementation

## Phase 4: Infrastructure Layer

- [x] 4.1 Create `internal/infrastructure/tiktok/client.go` with TikTokClient interface and scraper implementation
- [x] 4.2 Create `internal/infrastructure/storage/json.go` with Storage interface and JSON implementation
- [x] 4.3 Add input sanitization for username in TikTok client

## Phase 5: UI Layer (Bubble Tea)

- [x] 5.1 Create `internal/ui/models/counter.go` with CounterModel (Bubble Tea model)
- [x] 5.2 Create `internal/ui/models/metrics.go` with MetricsModel
- [x] 5.3 Create `internal/ui/models/history.go` with HistoryModel
- [x] 5.4 Create `internal/ui/views/styles.go` with Lipgloss styles
- [x] 5.5 Create `internal/ui/app.go` with main App struct and routing

## Phase 6: Integration & Wiring

- [x] 6.1 Wire up all services in `cmd/tap-support/main.go`
- [x] 6.2 Implement keyboard handling for tap counting (Space, 't' key)
- [x] 6.3 Implement start/stop/reset logic
- [x] 6.4 Implement real-time rate calculation (every second)
- [x] 6.5 Implement background mode toggle

## Phase 7: Testing

- [x] 7.1 Write unit tests for `domain/session.go` (rate calculation)
- [x] 7.2 Write unit tests for `application/counter.go` (increment, start, stop)
- [x] 7.3 Write unit tests for `domain/account.go` (validation)
- [ ] 7.4 Test input sanitization in TikTok client

## Phase 9: Professional Setup & CI/CD

- [x] 9.1 Create Makefile with professional build commands (build, test, lint, run)
- [x] 9.2 Add Dockerfile for containerized deployment
- [x] 9.3 Create .github/workflows/ci.yml with full CI/CD pipeline
- [x] 9.4 Add .golangci.yaml for linting configuration
- [x] 9.5 Add .editorconfig for consistent formatting
- [x] 9.6 Add CONTRIBUTING.md with contribution guidelines
- [x] 9.7 Add LICENSE (MIT) and CODE_OF_CONDUCT.md
- [x] 9.8 Create setup.sh for quick installation

## Phase 10: Documentation & Badges

- [x] 10.1 Update README.md with badges, installation, and usage
- [x] 10.2 Update config.yaml with version and proper app metadata
- [x] 10.3 Add SecGov compliance documentation
