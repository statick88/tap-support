package domain

import (
	"fmt"
)

// SessionHistory stores multiple sessions
type SessionHistory struct {
	Sessions []Session `json:"sessions"`
}

// Add adds a session to history
func (h *SessionHistory) Add(s Session) {
	h.Sessions = append([]Session{s}, h.Sessions...)

	// Keep only last 100
	if len(h.Sessions) > 100 {
		h.Sessions = h.Sessions[:100]
	}
}

// GetLastN returns the last N sessions
func (h *SessionHistory) GetLastN(n int) []Session {
	if n <= 0 || len(h.Sessions) <= n {
		return h.Sessions
	}
	return h.Sessions[:n]
}

// FormatSessionSummary returns a formatted summary for display
func (s *Session) FormatSessionSummary() string {
	return fmt.Sprintf("%s | %s taps | %s taps/min",
		s.StartTime.Format("2006-01-02 15:04"),
		formatTapCount(s.TapCount),
		s.FormatRate())
}

func formatTapCount(n int) string {
	if n >= 1000 {
		return fmt.Sprintf("%.1fK", float64(n)/1000)
	}
	return fmt.Sprintf("%d", n)
}
