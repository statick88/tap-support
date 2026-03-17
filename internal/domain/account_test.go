package domain

import (
	"testing"
)

func TestValidateUsername(t *testing.T) {
	tests := []struct {
		name      string
		username  string
		wantErr   bool
		errString string
	}{
		{
			name:     "valid username",
			username: "testuser",
			wantErr:  false,
		},
		{
			name:     "username with underscore",
			username: "test_user",
			wantErr:  false,
		},
		{
			name:     "username with period",
			username: "test.user",
			wantErr:  false,
		},
		{
			name:     "username with numbers",
			username: "test123",
			wantErr:  false,
		},
		{
			name:      "empty username",
			username:  "",
			wantErr:   true,
			errString: "username cannot be empty",
		},
		{
			name:     "username too short",
			username: "a",
			wantErr:  true,
		},
		{
			name:     "username with special chars",
			username: "test@user",
			wantErr:  true,
		},
		{
			name:     "username with spaces",
			username: "test user",
			wantErr:  true,
		},
		{
			name:     "username with dash",
			username: "test-user",
			wantErr:  true, // dash not allowed
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateUsername(tt.username)

			if (err != nil) != tt.wantErr {
				t.Errorf("ValidateUsername() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if tt.wantErr && tt.errString != "" {
				if err.Error() != tt.errString && !contains(err.Error(), tt.errString) {
					t.Errorf("ValidateUsername() error = %v, want containing %v", err, tt.errString)
				}
			}
		})
	}
}

func TestSanitizeUsername(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"testuser", "testuser"},
		{"test_user", "test_user"},
		{"test.user", "test.user"},
		{"test@user", "testuser"},
		{"test user", "testuser"},
		{"test!user", "testuser"},
		{"TestUser", "TestUser"},
	}

	for _, tt := range tests {
		t.Run(tt.input, func(t *testing.T) {
			result := SanitizeUsername(tt.input)
			if result != tt.expected {
				t.Errorf("SanitizeUsername(%q) = %q, want %q", tt.input, result, tt.expected)
			}
		})
	}
}

func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsAt(s, substr))
}

func containsAt(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

func TestAccount_FormatFollowers(t *testing.T) {
	tests := []struct {
		followers int
		expected  string
	}{
		{0, "0"},
		{100, "100"},
		{1000, "1.0K"},
		{1500, "1.5K"},
		{1000000, "1.0M"},
		{2500000, "2.5M"},
		{123456, "123.5K"},
	}

	for _, tt := range tests {
		t.Run(tt.expected, func(t *testing.T) {
			account := &Account{Followers: tt.followers}
			result := account.FormatFollowers()
			if result != tt.expected {
				t.Errorf("FormatFollowers(%d) = %s, want %s", tt.followers, result, tt.expected)
			}
		})
	}
}
