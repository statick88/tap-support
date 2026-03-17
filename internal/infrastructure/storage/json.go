package storage

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// Storage defines the interface for data persistence
type Storage interface {
	Save(key string, data interface{}) error
	Load(key string, dest interface{}) error
}

// JSONStorage implements Storage using JSON files
type JSONStorage struct {
	basePath string
}

// NewJSONStorage creates a new JSON file storage
func NewJSONStorage(basePath string) (*JSONStorage, error) {
	// Create directory if it doesn't exist
	if err := os.MkdirAll(basePath, 0755); err != nil {
		return nil, fmt.Errorf("failed to create storage directory: %w", err)
	}

	return &JSONStorage{
		basePath: basePath,
	}, nil
}

// Save saves data to a JSON file
func (j *JSONStorage) Save(key string, data interface{}) error {
	filename := filepath.Join(j.basePath, fmt.Sprintf("%s.json", key))

	bytes, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal data: %w", err)
	}

	if err := os.WriteFile(filename, bytes, 0644); err != nil {
		return fmt.Errorf("failed to write file: %w", err)
	}

	return nil
}

// Load loads data from a JSON file
func (j *JSONStorage) Load(key string, dest interface{}) error {
	filename := filepath.Join(j.basePath, fmt.Sprintf("%s.json", key))

	bytes, err := os.ReadFile(filename)
	if err != nil {
		if os.IsNotExist(err) {
			// File doesn't exist yet - that's okay for new storage
			return nil
		}
		return fmt.Errorf("failed to read file: %w", err)
	}

	if err := json.Unmarshal(bytes, dest); err != nil {
		return fmt.Errorf("failed to unmarshal data: %w", err)
	}

	return nil
}
