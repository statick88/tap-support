# Proposal: TikTok Tap Support - Core App

## Intent

Desarrollar una aplicación TUI (Terminal User Interface) que permita:
1. Contador manual de taps durante lives de TikTok
2. Visualización de métricas públicas de cuenta (seguidores, likes, videos)
3. Funcionamiento en background mediante interfaz TUI

El usuario da los taps físicamente en su dispositivo, la app los cuenta y muestra estadísticas en tiempo real.

## Scope

### In Scope
- App TUI corriendo en terminal
- Contador de taps con start/stop/reset
- Temporizador de sesión (taps por minuto)
- Métricas de cuenta: seguidores, likes totales, following, videos
- Modo background (minimizado)
- Historial de sesiones

### Out of Scope
- Automatización de taps (solo cuenta los que el usuario da)
- Chat en vivo
- Descarga de videos
- Análisis de comentarios

## Approach

Arquitectura hexagonal (Clean Architecture):
- **UI Layer**: Bubble Tea (Go TUI framework)
- **Application Layer**: Casos de uso (contador, métricas)
- **Domain Layer**: Entidades (Session, Account, Metrics)
- **Infrastructure Layer**: TikTok API client, storage

## Affected Areas

| Area | Impact | Descripción |
|------|--------|-------------|
| `internal/domain/` | New | Entidades del dominio |
| `internal/application/` | New | Casos de uso |
| `internal/infrastructure/` | New | TikTok API client |
| `internal/ui/` | New | Componentes Bubble Tea |
| `cmd/tap-support/` | New | Entry point |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|-------------|
| TikTok cambia API pública | Medium | Diseño adaptable, abstracción de cliente |
| Rate limiting | Low | Backoff exponencial, caché |
| Dependencias externas | Low | Interface contracts, mocks para testing |

## Rollback Plan

- Cada feature en branch separado
- Go modules para dependencias
- Fácil rollback: `git checkout HEAD~1`

## Dependencies

- Go 1.21+
- Bubble Tea (charmbracelet/tea)
- Lipgloss (styling TUI)

## Success Criteria

- [ ] App compila y corre en terminal
- [ ] Contador de taps funcional (start/stop/reset)
- [ ] Cálculo de taps/minuto correcto
- [ ] Métricas de cuenta se muestran correctamente
- [ ] Tests unitarios pasan
- [ ] Seguridad: sin hardcoded secrets
