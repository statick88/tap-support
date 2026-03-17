package domain

import "fmt"

// Domain errors
var (
	ErrInvalidUsername = fmt.Errorf("invalid username")
	ErrAccountNotFound = fmt.Errorf("account not found")
	ErrRateLimited     = fmt.Errorf("rate limited - please wait before retrying")
	ErrNetworkError    = fmt.Errorf("network error")
)

// AppError represents an application-level error
type AppError struct {
	Code    string
	Message string
	Err     error
}

func (e *AppError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %s (%v)", e.Code, e.Message, e.Err)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

func (e *AppError) Unwrap() error {
	return e.Err
}

// NewAppError creates a new application error
func NewAppError(code, message string, err error) *AppError {
	return &AppError{
		Code:    code,
		Message: message,
		Err:     err,
	}
}
