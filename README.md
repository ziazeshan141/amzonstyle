# Amazon-style Microservices Demo

A clean-room learning project that imitates a large e-commerce microservice architecture. It is **not Amazon.com source code** and is not affiliated with Amazon.

## Services

| Service | Port | Purpose |
|---|---:|---|
| frontend | 3000 | Store UI |
| api-gateway | 8080 | Single API entry point |
| auth-service | 3001 | Register/login/JWT |
| user-service | 3002 | Customer profile |
| product-service | 3003 | Product CRUD |
| catalog-service | 3004 | Category catalog |
| search-service | 3005 | Product search |
| cart-service | 3006 | Shopping carts |
| order-service | 3007 | Checkout orchestration |
| payment-service | 3008 | Mock payment |
| inventory-service | 3009 | Stock/reservations |
| shipping-service | 3010 | Mock shipment/tracking |
| review-service | 3011 | Product reviews |
| recommendation-service | 3012 | Demo recommendations |
| notification-service | 3013 | Demo notifications |

## Run locally

```bash
docker compose up --build
```

Open `http://localhost:3000`.

Gateway health: `http://localhost:8080/health`

## Example API calls

```bash
curl http://localhost:8080/api/products
curl "http://localhost:8080/api/search?q=headphones"

curl -X POST http://localhost:8080/api/carts/1/items   -H "Content-Type: application/json"   -d '{"productId":"p1","quantity":2}'

curl -X POST http://localhost:8080/api/orders   -H "Content-Type: application/json"   -d '{"userId":"1","email":"demo@example.com","address":{"line1":"King Fahd Road","city":"Riyadh"}}'
```

## Kubernetes

1. Build/push each image to your registry.
2. Replace `YOUR_ECR_REPO` in `kubernetes/base/workloads.yaml`.
3. Replace the example JWT secret.
4. Install an NGINX Ingress Controller if you want to use the included ingress.
5. Apply:

```bash
kubectl apply -k kubernetes/base
```

## Terraform (AWS starter)

The Terraform folder creates a VPC, EKS cluster, managed node group, and ECR repositories. Review versions and AWS costs before applying.

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Important limitations

This project deliberately uses in-memory data inside most services so the architecture is easy to understand. For a production-style next phase, give each stateful service its own database, add Kafka/RabbitMQ, Redis, OpenSearch, observability, secret management, CI/CD, retries/circuit breakers, and authentication/authorization at the gateway.
