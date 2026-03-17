package domain

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"time"
)

// Session represents a tap counting session
type Session struct {
	ID        string     `json:"id"`
	Username  string     `json:"username,omitempty"`
	TapCount  int        `json:"tap_count"`
	StartTime time.Time  `json:"start_time"`
	EndTime   *time.Time `json:"end_time,omitempty"`
	Rate      float64    `json:"rate,omitempty"` // taps per minute
}

// NewSession creates a new counting session
func NewSession() *Session {
	return &Session{
		ID:        generateUUID(),
		StartTime: time.Now(),
		TapCount:  0,
		Rate:      0,
	}
}

// Stop ends the session and calculates the final rate
func (s *Session) Stop() {
	// Calculate rate first, before setting EndTime
	s.calculateRate()
	now := time.Now()
	s.EndTime = &now
}

// IncrementTap increases the tap count by 1
func (s *Session) IncrementTap() {
	s.TapCount++
	s.calculateRate()
}

// calculateRate calculates the current taps per minute
func (s *Session) calculateRate() {
	if s.EndTime != nil {
		return // Already stopped
	}

	elapsed := time.Since(s.StartTime)
	if elapsed.Seconds() < 1 {
		s.Rate = 0
		return
	}

	minutes := elapsed.Minutes()
	s.Rate = float64(s.TapCount) / minutes
}

// ElapsedTime returns the duration of the session
func (s *Session) ElapsedTime() time.Duration {
	if s.EndTime != nil {
		return s.EndTime.Sub(s.StartTime)
	}
	return time.Since(s.StartTime)
}

// IsActive returns true if the session is still running
func (s *Session) IsActive() bool {
	return s.EndTime == nil
}

// FormatElapsed returns elapsed time as a formatted string
func (s *Session) FormatElapsed() string {
	elapsed := s.ElapsedTime()

	if elapsed.Hours() >= 1 {
		return fmt.Sprintf("%02d:%02d:%02d",
			int(elapsed.Hours()),
			int(elapsed.Minutes())%60,
			int(elapsed.Seconds())%60)
	}

	return fmt.Sprintf("%02d:%02d",
		int(elapsed.Minutes()),
		int(elapsed.Seconds())%60)
}

// FormatRate returns the rate as a formatted string
func (s *Session) FormatRate() string {
	if s.Rate == 0 {
		return "0.0"
	}
	return fmt.Sprintf("%.1f", s.Rate)
}

// generateUUID generates a random UUID v4
func generateUUID() string {
	b := make([]byte, 16)
	rand.Read(b)
	return hex.EncodeToString(b)
}
