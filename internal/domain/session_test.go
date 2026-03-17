package domain

import (
	"testing"
	"time"
)

func TestSession_NewSession(t *testing.T) {
	session := NewSession()

	if session == nil {
		t.Fatal("NewSession returned nil")
	}

	if session.TapCount != 0 {
		t.Errorf("expected TapCount 0, got %d", session.TapCount)
	}

	if session.Rate != 0 {
		t.Errorf("expected Rate 0, got %f", session.Rate)
	}

	if session.ID == "" {
		t.Error("expected non-empty ID")
	}

	if session.StartTime.IsZero() {
		t.Error("expected non-zero StartTime")
	}
}

func TestSession_IncrementTap(t *testing.T) {
	session := NewSession()

	session.IncrementTap()
	if session.TapCount != 1 {
		t.Errorf("expected 1 tap, got %d", session.TapCount)
	}

	session.IncrementTap()
	session.IncrementTap()
	if session.TapCount != 3 {
		t.Errorf("expected 3 taps, got %d", session.TapCount)
	}
}

func TestSession_Stop(t *testing.T) {
	session := NewSession()
	session.TapCount = 100
	// Set start time to 1 minute ago for rate calculation
	session.StartTime = time.Now().Add(-1 * time.Minute)

	session.Stop()

	if session.EndTime == nil {
		t.Error("expected EndTime to be set")
	}

	// Rate should be approximately 100 taps/minute
	if session.Rate < 99 || session.Rate > 101 {
		t.Errorf("expected rate ~100, got %f", session.Rate)
	}
}

func TestSession_IsActive(t *testing.T) {
	session := NewSession()

	if !session.IsActive() {
		t.Error("expected session to be active initially")
	}

	session.Stop()

	if session.IsActive() {
		t.Error("expected session to be inactive after stop")
	}
}

func TestSession_FormatElapsed(t *testing.T) {
	tests := []struct {
		name     string
		setup    func() *Session
		expected string
	}{
		{
			name: "new session",
			setup: func() *Session {
				return NewSession()
			},
			expected: "00:00",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			session := tt.setup()
			result := session.FormatElapsed()

			if len(result) != 5 {
				t.Errorf("expected format like 00:00, got %s", result)
			}
		})
	}
}

func TestSession_FormatRate(t *testing.T) {
	session := NewSession()

	if session.FormatRate() != "0.0" {
		t.Errorf("expected 0.0, got %s", session.FormatRate())
	}

	session.Rate = 150.5
	if session.FormatRate() != "150.5" {
		t.Errorf("expected 150.5, got %s", session.FormatRate())
	}
}

func TestSession_RateCalculation(t *testing.T) {
	session := NewSession()

	// Add taps
	session.TapCount = 60

	// Simulate 1 minute elapsed by setting start time in the past
	session.StartTime = time.Now().Add(-1 * time.Minute)

	// Calculate rate
	session.calculateRate()

	// Should be ~60 taps per minute
	if session.Rate < 59 || session.Rate > 61 {
		t.Errorf("expected rate ~60, got %f", session.Rate)
	}
}
