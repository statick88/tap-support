package ui

import (
	"fmt"
	"time"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/statick/tap-support/internal/application"
	"github.com/statick/tap-support/internal/ui/views"
)

type model struct {
	app       *App
	textInput textinput.Model
}

// App represents the main application
type App struct {
	counter     *application.CounterService
	metrics     *application.MetricsService
	history     *application.HistoryService
	view        string // "counter", "metrics", "history"
	username    string
	input       textinput.Model
	autoTapping bool // Controla si el conteo automático está activo
}

// NewApp creates a new application
func NewApp(counter *application.CounterService, metrics *application.MetricsService, history *application.HistoryService) *App {
	// Initialize text input
	ti := textinput.New()
	ti.Placeholder = "yazgardea"
	ti.Focus()

	// Create the app
	app := &App{
		counter:     counter,
		metrics:     metrics,
		history:     history,
		view:        "counter",
		input:       ti,
		username:    "yazgardea", // Default username
		autoTapping: true,        // Start in auto-tapping mode
	}

	// Start session automatically on startup
	app.counter.StartSession(app.username)

	return app
}

// Init initializes the application
func (a *App) Init() tea.Cmd {
	// Start auto-tapping ticker (1 tap per 100ms)
	return tea.Tick(100*time.Millisecond, func(t time.Time) tea.Msg {
		return tapTickMsg{}
	})
}

// tapTickMsg is a message sent periodically to trigger auto-tapping
type tapTickMsg struct{}

// Update handles incoming messages
func (a *App) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tapTickMsg:
		// Auto-tap if enabled and session is active
		if a.autoTapping && a.counter.HasActiveSession() {
			a.counter.IncrementTap()
		}
		// Continue ticking
		return a, tea.Tick(100*time.Millisecond, func(t time.Time) tea.Msg {
			return tapTickMsg{}
		})

	case tea.KeyMsg:
		key := msg.String()

		// Handle special keys for all views
		if key == "q" || key == "ctrl+c" {
			return a, tea.Quit
		}

		// Toggle auto-tapping with space
		if key == " " {
			a.autoTapping = !a.autoTapping
			return a, nil
		}

		// Handle metrics view input
		if a.view == "metrics" {
			// Let the text input handle the key
			a.input, cmd = a.input.Update(msg)

			// Check for Enter key to fetch metrics
			if key == "enter" && a.input.Value() != "" {
				username := a.input.Value()
				a.username = username
				// Restart session with new username
				if a.counter.HasActiveSession() {
					a.counter.StopSession()
				}
				a.counter.StartSession(a.username)
				a.view = "counter"
				a.input.Reset()
				return a, nil
			}

			// Check for escape to cancel input
			if key == "esc" {
				a.view = "counter"
				a.input.Reset()
				return a, nil
			}

			return a, cmd
		}

		// Handle username input view
		if a.view == "username" {
			a.input, cmd = a.input.Update(msg)

			if key == "enter" && a.input.Value() != "" {
				a.username = a.input.Value()
				// Restart session with new username if active
				if a.counter.HasActiveSession() {
					session := a.counter.StopSession()
					if session != nil {
						_ = a.history.SaveSession(session)
					}
					a.counter.StartSession(a.username)
				}
				a.view = "counter"
				a.input.Reset()
				return a, nil
			}

			if key == "esc" {
				a.view = "counter"
				a.input.Reset()
				return a, nil
			}

			return a, cmd
		}

		// Handle view switching for other views
		switch key {
		case "c":
			a.view = "counter"
		case "m":
			a.view = "metrics"
			a.input.Reset()
			a.input.Focus()
		case "u":
			// Change username
			a.view = "username"
			a.input.Reset()
			a.input.Placeholder = a.username
			a.input.Focus()
		case "h":
			a.view = "history"
		case "s":
			// Toggle session manually
			if a.counter.HasActiveSession() {
				session := a.counter.StopSession()
				if session != nil {
					_ = a.history.SaveSession(session)
				}
			} else {
				a.counter.StartSession(a.username)
			}
		case "r":
			a.counter.ResetSession()
		case "t":
			// Manual tap (only if not auto-tapping)
			if !a.autoTapping && a.counter.HasActiveSession() {
				a.counter.IncrementTap()
			}
		}
	}

	return a, nil
}

// View returns the string representation of the UI
func (a *App) View() string {
	switch a.view {
	case "counter":
		return a.counterView()
	case "metrics":
		return a.metricsView()
	case "history":
		return a.historyView()
	case "username":
		return a.usernameView()
	default:
		return a.counterView()
	}
}

func (a *App) counterView() string {
	session := a.counter.GetCurrentSession()

	header := views.AppStyles.Header.Render("TikTok Tap Counter")
	help := views.AppStyles.Help.Render("\n[Space/t] Tap | [s] Start/Stop | [r] Reset | [u] User | [m] Metrics | [h] History | [q] Quit")

	if session == nil || !session.IsActive() {
		// No active session - show start prompt
		return fmt.Sprintf("%s\n\n%s\n\n%s\n\n%s",
			header,
			views.AppStyles.Counter.Render("0"),
			views.AppStyles.Label.Render("Press [s] to start counting"),
			help)
	}

	// Active session
	tapCount := views.AppStyles.Counter.Render(fmt.Sprintf("%d", session.TapCount))
	rate := views.AppStyles.Rate.Render(session.FormatRate() + " taps/min")
	timer := views.AppStyles.Timer.Render(session.FormatElapsed())

	// Show username
	username := views.AppStyles.Label.Render(fmt.Sprintf("User: %s", session.Username))

	return fmt.Sprintf("%s\n\n%s\n\n%s\n\n%s\n\n%s\n\n%s",
		header,
		tapCount,
		rate,
		timer,
		username,
		help)
}

func (a *App) metricsView() string {
	header := views.AppStyles.Header.Render("TikTok Account Metrics")
	help := views.AppStyles.Help.Render("\n[Enter] Fetch | [c] Counter | [u] User | [h] History | [q] Quit")

	// Render the text input
	inputView := a.input.View()

	return header + "\n\n" +
		views.AppStyles.Label.Render("Enter TikTok username:") + "\n" +
		inputView + "\n\n" +
		help
}

func (a *App) usernameView() string {
	header := views.AppStyles.Header.Render("Change Username")
	help := views.AppStyles.Help.Render("\n[Enter] Save | [Esc] Cancel | [q] Quit")

	inputView := a.input.View()

	return header + "\n\n" +
		views.AppStyles.Label.Render("Enter new TikTok username:") + "\n" +
		inputView + "\n\n" +
		help
}

func (a *App) historyView() string {
	header := views.AppStyles.Header.Render("Session History")
	help := views.AppStyles.Help.Render("\n[c] Counter | [m] Metrics | [q] Quit")

	sessions, _ := a.history.GetHistory(10)

	if len(sessions) == 0 {
		return fmt.Sprintf("%s\n\n%s\n\n%s",
			header,
			views.AppStyles.Label.Render("No sessions yet"),
			help)
	}

	var historyText string
	for _, s := range sessions {
		historyText += s.FormatSessionSummary() + "\n"
	}

	return fmt.Sprintf("%s\n\n%s\n\n%s",
		header,
		views.AppStyles.Value.Render(historyText),
		help)
}
