package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Port        string
	DatabaseURL string
}

func Load() (*Config, error) {
	// Carregar .env apenas se existir, ignorando erro de arquivo não encontrado
	_ = godotenv.Load() // Ignorar erro intencionalmente

	port := os.Getenv("PORT")
	if port == "" {
		return nil, os.ErrNotExist // ou defina um valor padrão, se preferir
	}

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		return nil, os.ErrNotExist // ou defina um valor padrão, se preferir
	}

	return &Config{
		Port:        port,
		DatabaseURL: databaseURL,
	}, nil
}
