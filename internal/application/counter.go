package application

import (
	"github.com/statick/tap-support/internal/domain"
)

// CounterService handles tap counting logic
type CounterService struct {
	currentSession *domain.Session
}

// NewCounterService creates a new counter service
func NewCounterService() *CounterService {
	return &CounterService{}
}

// StartSession starts a new counting session
func (s *CounterService) StartSession(username string) {
	s.currentSession = domain.NewSession()
	s.currentSession.Username = username
}

// StopSession stops the current session and returns it
func (s *CounterService) StopSession() *domain.Session {
	if s.currentSession == nil {
		return nil
	}

	s.currentSession.Stop()
	session := s.currentSession
	s.currentSession = nil
	return session
}

// ResetSession resets the current session
func (s *CounterService) ResetSession() {
	s.currentSession = nil
}

// IncrementTap increments the tap count
func (s *CounterService) IncrementTap() {
	if s.currentSession == nil {
		return
	}
	s.currentSession.IncrementTap()
}

// GetCurrentSession returns the current session
func (s *CounterService) GetCurrentSession() *domain.Session {
	return s.currentSession
}

// HasActiveSession returns true if there's an active session
func (s *CounterService) HasActiveSession() bool {
	return s.currentSession != nil && s.currentSession.IsActive()
}

// SetUsername sets the username for the current session
func (s *CounterService) SetUsername(username string) {
	if s.currentSession == nil {
		return
	}
	s.currentSession.Username = username
}
