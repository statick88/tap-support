package application

import (
	"github.com/statick/tap-support/internal/domain"
	"github.com/statick/tap-support/internal/infrastructure/storage"
)

// HistoryService handles session history storage
type HistoryService struct {
	storage storage.Storage
}

// NewHistoryService creates a new history service
func NewHistoryService(storage storage.Storage) *HistoryService {
	return &HistoryService{
		storage: storage,
	}
}

// SaveSession saves a completed session to history
func (s *HistoryService) SaveSession(session *domain.Session) error {
	if session == nil {
		return nil
	}

	// Load existing history
	history := &domain.SessionHistory{
		Sessions: []domain.Session{},
	}

	_ = s.storage.Load("sessions", history)

	// Add new session
	history.Sessions = append([]domain.Session{*session}, history.Sessions...)

	// Keep only last 100 sessions
	if len(history.Sessions) > 100 {
		history.Sessions = history.Sessions[:100]
	}

	return s.storage.Save("sessions", history)
}

// GetHistory returns the session history
func (s *HistoryService) GetHistory(limit int) ([]domain.Session, error) {
	history := &domain.SessionHistory{
		Sessions: []domain.Session{},
	}

	err := s.storage.Load("sessions", history)
	if err != nil {
		return nil, err
	}

	if limit > 0 && len(history.Sessions) > limit {
		return history.Sessions[:limit], nil
	}

	return history.Sessions, nil
}

// AddSessionHistory domain entity
type SessionHistory struct {
	Sessions []domain.Session `json:"sessions"`
}
