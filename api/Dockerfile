# Stage 1: Build
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

