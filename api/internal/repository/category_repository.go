package repository

import (
    "context"
    "github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/database"
    "github.com/github.com/hgtpcastro/api-gateway-kong/product-api/internal/models"
)

type CategoryRepository struct {
    db *database.Database
}

func NewCategoryRepository(db *database.Database) *CategoryRepository {
    return &CategoryRepository{db: db}
}

func (r *CategoryRepository) GetAll() ([]models.Category, error) {
    rows, err := r.db.Conn.Query(context.Background(), "SELECT id, name FROM categories")
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var categories []models.Category
    for rows.Next() {
        var c models.Category
        if err := rows.Scan(&c.ID, &c.Name); err != nil {
            return nil, err
        }
        categories = append(categories, c)
    }
    return categories, nil
}

func (r *CategoryRepository) Create(c models.Category) error {
    _, err := r.db.Conn.Exec(context.Background(), 
        "INSERT INTO categories (name) VALUES ($1)", c.Name)
    return err
}

