.PHONY: all build run test clean docker-build docker-run

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

