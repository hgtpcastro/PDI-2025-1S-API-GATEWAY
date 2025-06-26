package repository

import (
    "context"
    "github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/database"
    "github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/models"
)

type ProductRepository struct {
    db *database.Database
}

func NewProductRepository(db *database.Database) *ProductRepository {
    return &ProductRepository{db: db}
}

func (r *ProductRepository) GetAll() ([]models.Product, error) {
    rows, err := r.db.Conn.Query(context.Background(), "SELECT id, name, category_id FROM products")
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var products []models.Product
    for rows.Next() {
        var p models.Product
        if err := rows.Scan(&p.ID, &p.Name, &p.CategoryID); err != nil {
            return nil, err
        }
        products = append(products, p)
    }
    return products, nil
}

func (r *ProductRepository) Create(p models.Product) error {
    _, err := r.db.Conn.Exec(context.Background(), 
        "INSERT INTO products (name, category_id) VALUES ($1, $2)", p.Name, p.CategoryID)
    return err
}

