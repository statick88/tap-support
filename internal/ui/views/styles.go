package views

import (
	"github.com/charmbracelet/lipgloss"
)

// AppStyles defines the visual styles for the TUI
var AppStyles = struct {
	Header     lipgloss.Style
	Counter    lipgloss.Style
	Rate       lipgloss.Style
	Timer      lipgloss.Style
	Label      lipgloss.Style
	Value      lipgloss.Style
	Error      lipgloss.Style
	Success    lipgloss.Style
	Help       lipgloss.Style
	Background lipgloss.Style
}{
	Header: lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("#FF6B6B")).
		Padding(0, 0, 1, 0),

	Counter: lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("#4ECDC4")),

	Rate: lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("#95E1D3")),

	Timer: lipgloss.NewStyle().
		Foreground(lipgloss.Color("#A8A8A8")),

	Label: lipgloss.NewStyle().
		Foreground(lipgloss.Color("#666666")),

	Value: lipgloss.NewStyle().
		Foreground(lipgloss.Color("#FFFFFF")),

	Error: lipgloss.NewStyle().
		Foreground(lipgloss.Color("#FF6B6B")),

	Success: lipgloss.NewStyle().
		Foreground(lipgloss.Color("#4ECDC4")),

	Help: lipgloss.NewStyle().
		Foreground(lipgloss.Color("#888888")),

	Background: lipgloss.NewStyle().
		Background(lipgloss.Color("#1A1A2E")),
}
