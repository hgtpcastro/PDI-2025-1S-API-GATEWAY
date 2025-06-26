#!/bin/bash

# Script para criar a estrutura da PoC de API com Kong
# Garante a criação de pastas e arquivos com conteúdos corretos

# Configurações
PROJECT_DIR="/home/hgtpcastro/development/pdi/2025/01/api-gateway/kong/go"
API_DIR="$PROJECT_DIR/api"
KONG_DIR="$PROJECT_DIR/kong"
USER="github.com/hgtpcastro/api-gateway-kong"  # Substitua pelo seu nome de usuário do GitHub, se necessário

# Função para criar diretórios
create_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "Criado diretório: $dir"
    else
        echo "Diretório já existe: $dir"
    fi
}

# Função para criar arquivos com conteúdo
create_file() {
    local file=$1
    local content=$2
    if [ ! -f "$file" ]; then
        echo "$content" > "$file"
        echo "Criado arquivo: $file"
    else
        echo "Arquivo já existe, pulando: $file"
    fi
}

# Criar estrutura de diretórios
create_dir "$PROJECT_DIR"
create_dir "$API_DIR"
create_dir "$API_DIR/cmd/api"
create_dir "$API_DIR/internal/config"
create_dir "$API_DIR/internal/database"
create_dir "$API_DIR/internal/models"
create_dir "$API_DIR/internal/repository"
create_dir "$API_DIR/internal/handler"
create_dir "$API_DIR/internal/router"
create_dir "$KONG_DIR"

# Criar arquivos da API Go
create_file "$API_DIR/go.mod" "module github.com/$USER/product-api

go 1.21

require (
    github.com/go-chi/chi/v5 v5.0.12
    github.com/jackc/pgx/v5 v5.5.5
    github.com/joho/godotenv v1.5.1
)
"

create_file "$API_DIR/cmd/api/main.go" 'package main

import (
    "log"
    "github.com/'$USER'/product-api/internal/config"
    "github.com/'$USER'/product-api/internal/database"
    "github.com/'$USER'/product-api/internal/handler"
    "github.com/'$USER'/product-api/internal/router"
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
    if err := r.Run(":" + cfg.Port); err != nil {
        log.Fatalf("Failed to start server: %v", err)
    }
}
'

create_file "$API_DIR/internal/config/config.go" 'package config

import (
    "os"
    "github.com/joho/godotenv"
)

type Config struct {
    Port        string
    DatabaseURL string
}

func Load() (*Config, error) {
    if err := godotenv.Load(); err != nil {
        return nil, err
    }

    return &Config{
        Port:        os.Getenv("PORT"),
        DatabaseURL: os.Getenv("DATABASE_URL"),
    }, nil
}
'

create_file "$API_DIR/internal/database/database.go" 'package database

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
'

create_file "$API_DIR/internal/models/product.go" 'package models

type Product struct {
    ID         int    `json:"id"`
    Name       string `json:"name"`
    CategoryID int    `json:"category_id"`
}
'

create_file "$API_DIR/internal/models/category.go" 'package models

type Category struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
}
'

create_file "$API_DIR/internal/repository/product_repository.go" 'package repository

import (
    "context"
    "github.com/'$USER'/product-api/internal/database"
    "github.com/'$USER'/product-api/internal/models"
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
'

create_file "$API_DIR/internal/repository/category_repository.go" 'package repository

import (
    "context"
    "github.com/'$USER'/product-api/internal/database"
    "github.com/'$USER'/product-api/internal/models"
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
'

create_file "$API_DIR/internal/handler/product_handler.go" 'package handler

import (
    "encoding/json"
    "net/http"
    "github.com/go-chi/chi/v5"
    "github.com/'$USER'/product-api/internal/database"
    "github.com/'$USER'/product-api/internal/models"
    "github.com/'$USER'/product-api/internal/repository"
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
'

create_file "$API_DIR/internal/handler/category_handler.go" 'package handler

import (
    "encoding/json"
    "net/http"
    "github.com/go-chi/chi/v5"
    "github.com/'$USER'/product-api/internal/database"
    "github.com/'$USER'/product-api/internal/models"
    "github.com/'$USER'/product-api/internal/repository"
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
'

create_file "$API_DIR/internal/router/router.go" 'package router

import (
    "github.com/go-chi/chi/v5"
    "github.com/'$USER'/product-api/internal/handler"
)

func New(productHandler *handler.ProductHandler, categoryHandler *handler.CategoryHandler) *chi.Mux {
    r := chi.NewRouter()

    r.Get("/products", productHandler.GetAll)
    r.Post("/products", productHandler.Create)
    r.Get("/categories", categoryHandler.GetAll)
    r.Post("/categories", categoryHandler.Create)

    return r
}
'

create_file "$API_DIR/Dockerfile" '# Stage 1: Build
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /product-api ./cmd/api

# Stage 2: Run
FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=builder /product-api /product-api
EXPOSE 8080
ENTRYPOINT ["/product-api"]
'

create_file "$API_DIR/.env" 'PORT=8080
DATABASE_URL=postgresql://kong:kongpass@kong-database:5432/kong?sslmode=disable
'

create_file "$API_DIR/Makefile" '.PHONY: all build run test clean docker-build docker-run

all: build

build:
	go build -o bin/product-api ./cmd/api

run:
	go run ./cmd/api

test:
	go test ./...

clean:
	rm -rf bin/

docker-build:
	docker build -t product-api:latest .

docker-run:
	docker run -p 8080:8080 --env-file .env product-api:latest
'

# Criar arquivos do Kong
create_file "$KONG_DIR/docker-compose.yml" 'version: "3.9"
networks:
  kong-net:
    driver: bridge

services:
  kong-database:
    image: postgres:13
    networks:
      - kong-net
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: kong
      POSTGRES_DB: kong
      POSTGRES_PASSWORD: kongpass
    volumes:
      - kong-data:/var/lib/postgresql/data

  kong:
    image: kong:3.4
    networks:
      - kong-net
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: kong-database
      KONG_PG_USER: kong
      KONG_PG_PASSWORD: kongpass
      KONG_PROXY_ACCESS_LOG: /dev/stdout
      KONG_ADMIN_ACCESS_LOG: /dev/stdout
      KONG_PROXY_ERROR_LOG: /dev/stderr
      KONG_ADMIN_ERROR_LOG: /dev/stderr
      KONG_ADMIN_LISTEN: 0.0.0.0:8001
      KONG_ADMIN_GUI_URL: http://localhost:8002
    ports:
      - "8000:8000"  # Proxy
      - "8001:8001"  # Admin API
      - "8002:8002"  # Admin GUI
    depends_on:
      - kong-database
    volumes:
      - ./kong.yml:/kong/declarative/kong.yml
      - ./kong.conf:/kong/kong.conf
    command: >
      sh -c "kong migrations bootstrap && kong start -c /kong/kong.conf"

  api:
    image: product-api:latest
    networks:
      - kong-net
    environment:
      - PORT=8080
      - DATABASE_URL=postgresql://kong:kongpass@kong-database:5432/kong?sslmode=disable
    depends_on:
      - kong-database

volumes:
  kong-data:
'

create_file "$KONG_DIR/kong.yml" '_format_version: "3.0"
services:
  - name: product-service
    url: http://api:8080
    routes:
      - name: products-route
        paths:
          - /products
        plugins:
          - name: key-auth
            config:
              key_names:
                - apikey
          - name: rate-limiting
            config:
              minute: 5
              policy: local
          - name: proxy-cache
            config:
              cache_ttl: 60
      - name: categories-route
        paths:
          - /categories
        plugins:
          - name: request-transformer
            config:
              add:
                headers:
                  - "X-Transformed-By: Kong"
          - name: key-auth
            config:
              key_names:
                - apikey
          - name: rate-limiting
            config:
              minute: 5
              policy: local
          - name: proxy-cache
            config:
              cache_ttl: 60

consumers:
  - username: demo-user
    keyauth_credentials:
      - key: demo-key-123
'

create_file "$KONG_DIR/kong.conf" 'database = postgres
declarative_config = /kong/declarative/kong.yml
'

# Criar README.md
create_file "$PROJECT_DIR/README.md" '# API de Produtos com Kong API Gateway

Este projeto é uma Prova de Conceito (PoC) que demonstra uma API RESTful construída em Go com o roteador `chi`, PostgreSQL como banco de dados e Kong como API Gateway. A API gerencia produtos e categorias, onde cada produto pertence a uma categoria. O projeto utiliza Docker para conteinerização, build multi-stage para a API e um Makefile para simplificar os comandos. Ele também demonstra recursos do Kong, como roteamento, balanceamento de carga, transformação de dados, autenticação, cache e limitação de taxa.

## Sumário
1. [Estrutura do Projeto](#estrutura-do-projeto)
2. [Pré-requisitos](#pré-requisitos)
3. [Instruções de Configuração](#instruções-de-configuração)
4. [Recursos do Kong Demonstrados](#recursos-do-kong-demonstrados)
5. [Endpoints da API](#endpoints-da-api)
6. [Testando a API](#testando-a-api)
7. [Comandos do Makefile](#comandos-do-makefile)
8. [Práticas de Código Limpo](#práticas-de-código-limpo)
9. [Solução de Problemas](#solução-de-problemas)
10. [Melhorias Futuras](#melhorias-futuras)

## Estrutura do Projeto