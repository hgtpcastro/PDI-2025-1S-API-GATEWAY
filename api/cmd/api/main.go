package main

import (
	"log"
	"net/http"

	"github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/config"
	"github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/database"
	"github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/handler"
	"github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/router"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	db, err := database.New(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	productHandler := handler.NewProductHandler(db)
	categoryHandler := handler.NewCategoryHandler(db)

	r := router.New(productHandler, categoryHandler)

	log.Printf("Server starting on port %s", cfg.Port)

	http.ListenAndServe(":"+cfg.Port, r)

	// if err := r.Run(":" + cfg.Port); err != nil {
	//     log.Fatalf("Failed to start server: %v", err)
	// }
}
