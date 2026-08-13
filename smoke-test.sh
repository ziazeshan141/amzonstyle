#!/usr/bin/env sh
set -e
curl -fsS http://localhost:8080/health
curl -fsS http://localhost:8080/api/products
curl -fsS -X POST http://localhost:8080/api/carts/1/items -H 'Content-Type: application/json' -d '{"productId":"p1","quantity":1}'
curl -fsS -X POST http://localhost:8080/api/orders -H 'Content-Type: application/json' -d '{"userId":"1","email":"demo@example.com","address":{"line1":"King Fahd Road","city":"Riyadh"}}'
echo "Smoke test passed"
