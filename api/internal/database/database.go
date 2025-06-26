package database

import (
    "context"
    "github.com/jackc/pgx/v5"
)

type Database struct {
    Conn *pgx.Conn
}

func New(url string) (*Database, error) {
    conn, err := pgx.Connect(context.Background(), url)
    if err != nil {
        return nil, err
    }

    // Criar tabelas se não existirem
    _, err = conn.Exec(context.Background(), `
        CREATE TABLE IF NOT EXISTS categories (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL
        );
        CREATE TABLE IF NOT EXISTS products (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            category_id INTEGER REFERENCES categories(id)
        );
    `)
    if err != nil {
        return nil, err
    }

    return &Database{Conn: conn}, nil
}

func (db *Database) Close() {
    db.Conn.Close(context.Background())
}

