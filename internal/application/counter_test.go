package application

import (
	"testing"
)

func TestCounterService_NewCounterService(t *testing.T) {
	cs := NewCounterService()

	if cs == nil {
		t.Fatal("NewCounterService returned nil")
	}

	if cs.HasActiveSession() {
		t.Error("expected no active session initially")
	}
}

func TestCounterService_StartSession(t *testing.T) {
	cs := NewCounterService()

	cs.StartSession("testuser")

	if !cs.HasActiveSession() {
		t.Error("expected active session after start")
	}

	session := cs.GetCurrentSession()
	if session == nil {
		t.Fatal("expected session to be non-nil")
	}

	if session.Username != "testuser" {
		t.Errorf("expected username 'testuser', got %s", session.Username)
	}

	if session.TapCount != 0 {
		t.Errorf("expected tap count 0, got %d", session.TapCount)
	}
}

func TestCounterService_StopSession(t *testing.T) {
	cs := NewCounterService()

	cs.StartSession("testuser")
	cs.IncrementTap()
	cs.IncrementTap()
	cs.IncrementTap()

	session := cs.StopSession()

	if session == nil {
		t.Fatal("expected session to be non-nil after stop")
	}

	if session.TapCount != 3 {
		t.Errorf("expected 3 taps, got %d", session.TapCount)
	}

	if session.EndTime == nil {
		t.Error("expected end time to be set")
	}

	if cs.HasActiveSession() {
		t.Error("expected no active session after stop")
	}
}

func TestCounterService_ResetSession(t *testing.T) {
	cs := NewCounterService()

	cs.StartSession("testuser")
	cs.IncrementTap()
	cs.IncrementTap()

	cs.ResetSession()

	if cs.HasActiveSession() {
		t.Error("expected no active session after reset")
	}

	if cs.GetCurrentSession() != nil {
		t.Error("expected current session to be nil after reset")
	}
}

func TestCounterService_IncrementTap(t *testing.T) {
	cs := NewCounterService()

	// Increment without active session should be ignored
	cs.IncrementTap()

	cs.StartSession("testuser")

	cs.IncrementTap()
	if cs.GetCurrentSession().TapCount != 1 {
		t.Errorf("expected 1 tap, got %d", cs.GetCurrentSession().TapCount)
	}

	cs.IncrementTap()
	if cs.GetCurrentSession().TapCount != 2 {
		t.Errorf("expected 2 taps, got %d", cs.GetCurrentSession().TapCount)
	}
}

func TestCounterService_SetUsername(t *testing.T) {
	cs := NewCounterService()

	cs.StartSession("user1")
	cs.SetUsername("user2")

	if cs.GetCurrentSession().Username != "user2" {
		t.Errorf("expected username 'user2', got %s", cs.GetCurrentSession().Username)
	}
}

func TestCounterService_SetUsernameNoSession(t *testing.T) {
	cs := NewCounterService()

	// Should not panic
	cs.SetUsername("testuser")

	if cs.HasActiveSession() {
		t.Error("expected no session to be created")
	}
}
