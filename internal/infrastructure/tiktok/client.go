package tiktok

import (
	"fmt"
	"io"
	"net/http"
	"regexp"
	"time"

	"github.com/statick/tap-support/internal/domain"
)

// TikTokClient defines the interface for fetching TikTok data
type TikTokClient interface {
	FetchAccountMetrics(username string) (*domain.Account, error)
}

// TikTokScraper implements TikTokClient by scraping public pages
type TikTokScraper struct {
	client *http.Client
}

// NewTikTokScraper creates a new TikTok scraper
func NewTikTokScraper() *TikTokScraper {
	return &TikTokScraper{
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// FetchAccountMetrics fetches public metrics for a TikTok account
func (t *TikTokScraper) FetchAccountMetrics(username string) (*domain.Account, error) {
	url := fmt.Sprintf("https://www.tiktok.com/@%s", username)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, domain.NewAppError("NETWORK_ERROR", "Failed to create request", err)
	}

	req.Header.Set("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
	req.Header.Set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
	req.Header.Set("Accept-Language", "en-US,en;q=0.9")

	resp, err := t.client.Do(req)
	if err != nil {
		return nil, domain.NewAppError("NETWORK_ERROR", "Failed to connect to TikTok", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 404 {
		return nil, domain.ErrAccountNotFound
	}

	if resp.StatusCode == 429 {
		return nil, domain.ErrRateLimited
	}

	if resp.StatusCode != 200 {
		return nil, domain.NewAppError("HTTP_ERROR", fmt.Sprintf("Unexpected status code: %d", resp.StatusCode), nil)
	}

	// Read the entire HTML body
	htmlBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, domain.NewAppError("PARSE_ERROR", "Failed to read response body", err)
	}

	// Extract from __UNIVERSAL_DATA_FOR_REHYDRATION__
	account := t.extractFromUniversalData(string(htmlBytes), username)

	if account != nil {
		return account, nil
	}

	return nil, domain.NewAppError("PARSE_ERROR", "Could not extract user data from TikTok page", nil)
}

// extractFromUniversalData extracts metrics from the embedded JSON
func (t *TikTokScraper) extractFromUniversalData(html string, username string) *domain.Account {
	// Find __UNIVERSAL_DATA_FOR_REHYDRATION__
	re := regexp.MustCompile(`<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" type="application/json">([^<]+)</script>`)
	matches := re.FindStringSubmatch(html)

	if len(matches) < 2 {
		return nil
	}

	jsonStr := matches[1]

	// Try to find stats directly in the JSON
	account := &domain.Account{
		Username:  username,
		FetchedAt: time.Now(),
	}

	// Extract individual stats using regex
	patterns := map[string]*int{
		`"followerCount"\s*:\s*(\d+)`:  &account.Followers,
		`"followingCount"\s*:\s*(\d+)`: &account.Following,
		`"likeCount"\s*:\s*(\d+)`:      &account.Likes,
		`"videoCount"\s*:\s*(\d+)`:     &account.Videos,
	}

	for pattern, target := range patterns {
		re := regexp.MustCompile(pattern)
		m := re.FindStringSubmatch(jsonStr)
		if len(m) >= 2 {
			fmt.Sscanf(m[1], "%d", target)
		}
	}

	if account.Followers > 0 || account.Following > 0 || account.Likes > 0 {
		return account
	}

	return nil
}
