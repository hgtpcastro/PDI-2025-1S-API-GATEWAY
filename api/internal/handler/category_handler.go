package handler

import (
	"encoding/json"
	"net/http"

	"github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/database"
	"github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/models"
	"github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/repository"
)

type CategoryHandler struct {
	repo *repository.CategoryRepository
}

func NewCategoryHandler(db *database.Database) *CategoryHandler {
	return &CategoryHandler{repo: repository.NewCategoryRepository(db)}
}

func (h *CategoryHandler) GetAll(w http.ResponseWriter, r *http.Request) {
	categories, err := h.repo.GetAll()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(categories)
}

func (h *CategoryHandler) Create(w http.ResponseWriter, r *http.Request) {
	var c models.Category
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	if err := h.repo.Create(c); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
}
