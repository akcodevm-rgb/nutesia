package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/api/iterator"
	"google.golang.org/api/option"
)

// FirestoreRepository is a Firebase Cloud Firestore persistence adapter implementing the Repository interface.
type FirestoreRepository struct {
	client *firestore.Client
	mu     sync.Mutex
}

type firestoreDoc struct {
	Data string `firestore:"data"`
}

// NewFirestoreRepository initializes a connection to Google Cloud Firestore using Project ID and optional credentials file.
func NewFirestoreRepository(ctx context.Context, projectID, credsFile string) (*FirestoreRepository, error) {
	if projectID == "" {
		return nil, errors.New("firebase project ID cannot be empty")
	}

	var opts []option.ClientOption
	if credsFile != "" {
		opts = append(opts, option.WithCredentialsFile(credsFile))
	}

	client, err := firestore.NewClient(ctx, projectID, opts...)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize firestore client: %w", err)
	}

	return &FirestoreRepository{
		client: client,
	}, nil
}

func (r *FirestoreRepository) Get(collection, key string) (json.RawMessage, bool, error) {
	collName, docID := resolveCollectionAndID(collection, key)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	docRef := r.client.Collection(collName).Doc(docID)
	docSnap, err := docRef.Get(ctx)
	if err != nil {
		if errors.Is(err, iterator.Done) || strings.Contains(err.Error(), "NotFound") || strings.Contains(err.Error(), "not found") || docSnap == nil || !docSnap.Exists() {
			return nil, false, nil
		}
		return nil, false, err
	}
	if !docSnap.Exists() {
		return nil, false, nil
	}
	var doc firestoreDoc
	if err := docSnap.DataTo(&doc); err != nil {
		return nil, false, err
	}
	return json.RawMessage([]byte(doc.Data)), true, nil
}

func (r *FirestoreRepository) Put(collection, key string, value any) error {
	collName, docID := resolveCollectionAndID(collection, key)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var data []byte
	switch v := value.(type) {
	case json.RawMessage:
		data = v
	case []byte:
		data = v
	case string:
		data = []byte(v)
	default:
		var err error
		data, err = json.Marshal(value)
		if err != nil {
			return err
		}
	}

	docRef := r.client.Collection(collName).Doc(docID)
	doc := firestoreDoc{
		Data: string(data),
	}

	_, err := docRef.Set(ctx, doc)
	return err
}

func (r *FirestoreRepository) Update(collection, key string, fn func(json.RawMessage, bool) (any, error)) (any, error) {
	collName, docID := resolveCollectionAndID(collection, key)
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	var result any
	err := r.client.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		docRef := r.client.Collection(collName).Doc(docID)
		docSnap, err := tx.Get(docRef)
		found := true
		var raw []byte
		if err != nil {
			// Check if document simply doesn't exist
			if strings.Contains(err.Error(), "NotFound") || strings.Contains(err.Error(), "not found") {
				found = false
			} else {
				return err
			}
		} else if !docSnap.Exists() {
			found = false
		} else {
			var doc firestoreDoc
			if err := docSnap.DataTo(&doc); err != nil {
				return err
			}
			raw = []byte(doc.Data)
		}

		val, err := fn(json.RawMessage(raw), found)
		if err != nil {
			return err
		}

		var data []byte
		switch v := val.(type) {
		case json.RawMessage:
			data = v
		case []byte:
			data = v
		case string:
			data = []byte(v)
		default:
			var err error
			data, err = json.Marshal(val)
			if err != nil {
				return err
			}
		}

		doc := firestoreDoc{
			Data: string(data),
		}

		err = tx.Set(docRef, doc)
		if err != nil {
			return err
		}

		result = val
		return nil
	})

	if err != nil {
		return nil, err
	}
	return result, nil
}

func (r *FirestoreRepository) List(collection string) ([]json.RawMessage, error) {
	collName, prefix := resolveCollectionListFilter(collection)
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	iter := r.client.Collection(collName).Documents(ctx)
	defer iter.Stop()

	var items []json.RawMessage
	for {
		docSnap, err := iter.Next()
		if errors.Is(err, iterator.Done) {
			break
		}
		if err != nil {
			return nil, err
		}
		if prefix != "" {
			if !strings.HasPrefix(docSnap.Ref.ID, prefix+":") {
				continue
			}
		}
		var doc firestoreDoc
		if err := docSnap.DataTo(&doc); err != nil {
			return nil, err
		}
		items = append(items, json.RawMessage([]byte(doc.Data)))
	}

	if items == nil {
		items = []json.RawMessage{}
	}

	return items, nil
}

func resolveCollectionAndID(collection, key string) (string, string) {
	if strings.Contains(collection, "/") {
		parts := strings.Split(collection, "/")
		return parts[0], parts[1] + ":" + key
	}
	return collection, key
}

func resolveCollectionListFilter(collection string) (string, string) {
	if strings.Contains(collection, "/") {
		parts := strings.Split(collection, "/")
		return parts[0], parts[1]
	}
	return collection, ""
}
