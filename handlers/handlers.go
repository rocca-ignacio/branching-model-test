package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"
)

// Item represents a sample resource
type Item struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at"`
}

// Response represents a standard API response
type Response struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// In-memory storage for demo purposes
var items = []Item{
	{ID: "1", Name: "Item One", CreatedAt: time.Now()},
	{ID: "2", Name: "Item Two", CreatedAt: time.Now()},
	{ID: "3", Name: "Item Three", CreatedAt: time.Now()},
}

// HealthCheck returns the health status of the API
func HealthCheck(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusOK, Response{
		Success: true,
		Data: map[string]string{
			"status": "healthy",
			"time":   time.Now().Format(time.RFC3339),
		},
	})
}

// GetItems returns all items
func GetItems(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		respondJSON(w, http.StatusMethodNotAllowed, Response{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	respondJSON(w, http.StatusOK, Response{
		Success: true,
		Data:    items,
	})
}

// GetItemByID returns a single item by ID
func GetItemByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		respondJSON(w, http.StatusMethodNotAllowed, Response{
			Success: false,
			Error:   "Method not allowed",
		})
		return
	}

	// Extract ID from path
	path := strings.TrimPrefix(r.URL.Path, "/api/v1/items/")
	if path == "" {
		respondJSON(w, http.StatusBadRequest, Response{
			Success: false,
			Error:   "Item ID is required",
		})
		return
	}

	// Find item
	for _, item := range items {
		if item.ID == path {
			respondJSON(w, http.StatusOK, Response{
				Success: true,
				Data:    item,
			})
			return
		}
	}

	respondJSON(w, http.StatusNotFound, Response{
		Success: false,
		Error:   "Item not found",
	})
}

// respondJSON is a helper function to send JSON responses
func respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}
