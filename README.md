# API de Produtos com Kong API Gateway

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
├── api/
│   ├── cmd/
│   │   └── api/
│   │       └── main.go
│   ├── internal/
│   │   ├── config/
│   │   ├── database/
│   │   ├── models/
│   │   ├── repository/
│   │   ├── handler/
│   │   └── router/
│   ├── Dockerfile
│   ├── go.mod
│   ├── go.sum
│   └── Makefile
├── kong/
│   ├── docker-compose.yml
│   ├── kong.yml
│   └── kong.conf
└── README.md


- **api/**: Aplicação Go com layout padrão do Go.
- **kong/**: Configurações do Kong API Gateway.
- **Dockerfile**: Build multi-stage para a API.
- **Makefile**: Comandos simplificados para build e execução.

## Pré-requisitos
- Docker e Docker Compose
- Go 1.21
- Make (opcional, para uso do Makefile)
- curl ou Postman para testes

## Instruções de Configuração
1. **Clonar o Repositório**
   ```bash
   git clone https://github.com/yourusername/product-api.git
   cd product-api

2. **Construir a Imagem Docker da API**
    ```bash
    cd api
    make docker-build

3. **Iniciar a Infraestrutura**
    ```bash
  cd ../kong
  docker-compose up -d

4. **Verificar a API Admin do Kong**
    ```bash
    curl http://localhost:8001

  5. **Acessar a Interface Gráfica do Kong Abra http://localhost:8002 no navegador.**

## Recursos do Kong Demonstrados

A PoC demonstra os seguintes recursos do Kong usando a configuração em kong.yml:

1. **Roteamento:**
* Rotas /products e /categories apontam para o serviço api (http://api:8080).
*Exemplo: /products → api:8080/products.

2. **Balanceamento de Carga:**

* Configurado implicitamente pelo Kong para distribuir tráfego. Para demonstrar, escale o serviço api:
    ```bash
    docker-compose scale api=3

* O Kong distribuirá as requisições entre as três instâncias.

3. **Transformação de Dados:**

* O plugin request-transformer adiciona o cabeçalho X-Transformed-By: Kong às requisições para /categories.
* Exemplo: Verifique os cabeçalhos da resposta com curl -v.

4. **Autenticação:**

* O plugin key-auth exige um cabeçalho apikey em todas as rotas.
* Exemplo: Use apikey: demo-key-123 para o consumidor demo-user.

5. **Cache:**

* O plugin proxy-cache armazena respostas por 60 segundos.
* Exemplo: Requisições GET repetidas para /products retornam dados em cache.

6. **Limitação de Taxa (Rate Limiting):**

* O plugin rate-limiting limita requisições a 5 por minuto por consumidor.
* Exemplo: Exceder 5 requisições em um minuto retorna um erro 429 Too Many Requests.

## Endpoints da API

* GET /products: Lista todos os produtos.
* POST /products: Cria um novo produto (requer corpo JSON com name e category_id).
* GET /categories: Lista todas as categorias.
* POST /categories: Cria uma nova categoria (requer corpo JSON com name).

Exemplo de JSON para POST /products:

{
    "name": "Notebook",
    "category_id": 1
}


Exemplo de JSON para POST /categories:

{
    "name": "Eletrônicos"
}

