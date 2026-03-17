package application

import (
	"testing"
	"time"
)

// TestAutoTappingLogic verifies the auto-tapping logic works correctly
func TestAutoTappingLogic(t *testing.T) {
	// Create counter service
	counter := NewCounterService()

	// Start session
	counter.StartSession("testuser")

	// Simulate auto-taps (100ms intervals = 10 taps per second)
	// The test will take about 1.5 seconds total
	for i := 0; i < 15; i++ {
		counter.IncrementTap()
		time.Sleep(100 * time.Millisecond)
	}

	// Get session
	session := counter.GetCurrentSession()

	// Verify tap count is correct
	if session.TapCount != 15 {
		t.Errorf("Expected 15 taps, got %d", session.TapCount)
	}

	if session.Username != "testuser" {
		t.Errorf("Expected username 'testuser', got '%s'", session.Username)
	}

	// Rate should be > 0 after enough time has passed
	if session.Rate <= 0 {
		t.Errorf("Expected positive rate after time, got %f", session.Rate)
	}

	// Rate should be reasonable (not crazy high)
	if session.Rate > 1000 {
		t.Errorf("Rate too high: %f", session.Rate)
	}

	t.Logf("Session stats - Taps: %d, Rate: %.1f taps/min, Elapsed: %s",
		session.TapCount, session.Rate, session.FormatElapsed())
}

// TestUserChange verifies user change functionality
func TestUserChange(t *testing.T) {
	counter := NewCounterService()
	counter.StartSession("user1")

	// Simulate some taps
	for i := 0; i < 5; i++ {
		counter.IncrementTap()
	}

	// Stop session (this would save it in real app)
	session := counter.StopSession()

	if session.TapCount != 5 {
		t.Errorf("Expected 5 taps, got %d", session.TapCount)
	}

	// Start new session with different user
	counter.StartSession("user2")

	session2 := counter.GetCurrentSession()
	if session2.Username != "user2" {
		t.Errorf("Expected username 'user2', got '%s'", session2.Username)
	}

	if session2.TapCount != 0 {
		t.Errorf("Expected new session to start with 0 taps, got %d", session2.TapCount)
	}
}
