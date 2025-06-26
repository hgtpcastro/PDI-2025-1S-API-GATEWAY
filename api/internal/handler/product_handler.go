package handler

import (
	"encoding/json"
	"net/http"

	"github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/database"
	"github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/models"
	"github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/repository"
)

type ProductHandler struct {
	repo *repository.ProductRepository
}

func NewProductHandler(db *database.Database) *ProductHandler {
	return &ProductHandler{repo: repository.NewProductRepository(db)}
}

func (h *ProductHandler) GetAll(w http.ResponseWriter, r *http.Request) {
	products, err := h.repo.GetAll()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(products)
}

func (h *ProductHandler) Create(w http.ResponseWriter, r *http.Request) {
	var p models.Product
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	if err := h.repo.Create(p); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
}
