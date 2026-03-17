package application

import (
	"github.com/statick/tap-support/internal/domain"
	"github.com/statick/tap-support/internal/infrastructure/tiktok"
)

// MetricsService handles TikTok account metrics
type MetricsService struct {
	client tiktok.TikTokClient
}

// NewMetricsService creates a new metrics service
func NewMetricsService(client tiktok.TikTokClient) *MetricsService {
	return &MetricsService{
		client: client,
	}
}

// GetAccountMetrics fetches metrics for a TikTok account
func (s *MetricsService) GetAccountMetrics(username string) (*domain.Account, error) {
	// Validate and sanitize input
	if err := domain.ValidateUsername(username); err != nil {
		return nil, domain.NewAppError("INVALID_USERNAME", err.Error(), err)
	}

	sanitized := domain.SanitizeUsername(username)

	// Fetch from TikTok
	account, err := s.client.FetchAccountMetrics(sanitized)
	if err != nil {
		return nil, err
	}

	return account, nil
}
