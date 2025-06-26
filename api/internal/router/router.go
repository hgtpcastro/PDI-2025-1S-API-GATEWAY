package router

import (
	"log"
	"net/http"

	"github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/handler"
	"github.com/go-chi/chi/v5"
)

func New(productHandler *handler.ProductHandler, categoryHandler *handler.CategoryHandler) *chi.Mux {
	r := chi.NewRouter()

	// Middleware de log para todas as requisições
	r.Use(func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			log.Printf("Received request: %s %s, Headers: %v", r.Method, r.URL.Path, r.Header)
			next.ServeHTTP(w, r)
		})
	})

	r.Get("/products", productHandler.GetAll)
	r.Post("/products", productHandler.Create)
	r.Get("/categories", categoryHandler.GetAll)
	r.Post("/categories", categoryHandler.Create)

	return r
}
