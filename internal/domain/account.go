package domain

import (
	"fmt"
	"regexp"
	"strconv"
	"time"
)

// Account represents TikTok account public metrics
type Account struct {
	Username  string    `json:"username"`
	Followers int       `json:"followers"`
	Following int       `json:"following"`
	Likes     int       `json:"likes"`
	Videos    int       `json:"videos"`
	FetchedAt time.Time `json:"fetched_at"`
}

// ValidateUsername validates the TikTok username format
// Returns error if invalid
func ValidateUsername(username string) error {
	if username == "" {
		return fmt.Errorf("username cannot be empty")
	}

	// TikTok usernames: 2-24 chars, letters, numbers, underscores, periods
	matched, err := regexp.MatchString(`^[a-zA-Z0-9_.]{2,24}$`, username)
	if err != nil {
		return fmt.Errorf("error validating username: %w", err)
	}

	if !matched {
		return fmt.Errorf("invalid username format. Use 2-24 characters: letters, numbers, underscores, periods")
	}

	return nil
}

// SanitizeUsername removes any potentially dangerous characters
func SanitizeUsername(username string) string {
	// Keep only alphanumeric, underscore, and period
	re := regexp.MustCompile(`[^a-zA-Z0-9_.]`)
	return re.ReplaceAllString(username, "")
}

// FormatFollowers returns followers count in a human-readable format
func (a *Account) FormatFollowers() string {
	return formatNumber(a.Followers)
}

// FormatLikes returns likes count in a human-readable format
func (a *Account) FormatLikes() string {
	return formatNumber(a.Likes)
}

// formatNumber formats a number with K/M suffix
func formatNumber(n int) string {
	if n >= 1_000_000 {
		return fmt.Sprintf("%.1fM", float64(n)/1_000_000)
	}
	if n >= 1_000 {
		return fmt.Sprintf("%.1fK", float64(n)/1_000)
	}
	return strconv.Itoa(n)
}

// ParseNumber parses a string number (handles K, M suffixes)
func ParseNumber(s string) (int, error) {
	s = s[:len(s)-1] // Remove last char (K or M)

	var multiplier float64
	if len(s) > 0 {
		switch s[len(s)-1] {
		case 'K', 'k':
			multiplier = 1_000
			s = s[:len(s)-1]
		case 'M', 'm':
			multiplier = 1_000_000
			s = s[:len(s)-1]
		}
	}

	val, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return 0, fmt.Errorf("invalid number format: %w", err)
	}

	return int(val * multiplier), nil
}
