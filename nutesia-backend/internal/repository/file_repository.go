package repository

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sync"
)

// FileRepository is a local-development persistence adapter. It keeps the API
// contract independent of the eventual MongoDB implementation.
type FileRepository struct {
	dataDir string
	mu      sync.RWMutex
}

func NewFileRepository(dataDir string) (*FileRepository, error) {
	if err := os.MkdirAll(dataDir, 0o755); err != nil {
		return nil, err
	}
	return &FileRepository{dataDir: dataDir}, nil
}

func (r *FileRepository) Get(collection, key string) (json.RawMessage, bool, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	data, err := os.ReadFile(r.path(collection, key))
	if errors.Is(err, os.ErrNotExist) {
		return nil, false, nil
	}
	return data, err == nil, err
}

func (r *FileRepository) Put(collection, key string, value any) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.putLocked(collection, key, value)
}

// Update reads and writes one JSON document while holding the repository lock.
// It is used for state which must not be changed by competing requests, such as
// a user's credit wallet.
func (r *FileRepository) Update(collection, key string, fn func(json.RawMessage, bool) (any, error)) (any, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	data, err := os.ReadFile(r.path(collection, key))
	found := err == nil
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return nil, err
	}
	value, err := fn(data, found)
	if err != nil {
		return nil, err
	}
	if err := r.putLocked(collection, key, value); err != nil {
		return nil, err
	}
	return value, nil
}

func (r *FileRepository) putLocked(collection, key string, value any) error {
	data, err := json.Marshal(value)
	if err != nil {
		return err
	}
	path := r.path(collection, key)
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, data, 0o600)
}

func (r *FileRepository) List(collection string) ([]json.RawMessage, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	dir := filepath.Join(r.dataDir, collection)
	entries, err := os.ReadDir(dir)
	if errors.Is(err, os.ErrNotExist) {
		return []json.RawMessage{}, nil
	}
	if err != nil {
		return nil, err
	}
	items := make([]json.RawMessage, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		data, err := os.ReadFile(filepath.Join(dir, entry.Name()))
		if err != nil {
			return nil, err
		}
		items = append(items, data)
	}
	return items, nil
}

func (r *FileRepository) path(collection, key string) string {
	return filepath.Join(r.dataDir, collection, key+".json")
}
