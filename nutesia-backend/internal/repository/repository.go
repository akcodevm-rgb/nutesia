package repository

import "encoding/json"

// Repository defines the persistence contract for all backend storage implementations
// (e.g., local FileRepository or MongoDB Atlas / MongoRepository).
type Repository interface {
	Get(collection, key string) (json.RawMessage, bool, error)
	Put(collection, key string, value any) error
	Update(collection, key string, fn func(json.RawMessage, bool) (any, error)) (any, error)
	List(collection string) ([]json.RawMessage, error)
}
