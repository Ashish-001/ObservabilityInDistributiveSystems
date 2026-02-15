#!/bin/bash
# Quick checks to see why requests might be failing
set -e
echo "=== 1. Gateway health (should be 200, not 401) ==="
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:9000/actuator/health || true
echo ""
echo "=== 2. Gateway products (should be 200) ==="
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://localhost:9000/api/product || true
echo ""
echo "=== 3. Inventory check (should be 200) ==="
curl -s -o /dev/null -w "HTTP %{http_code}\n" "http://localhost:9000/api/inventory?skuCode=SKU001&quantity=1" || true
echo ""
echo "=== 4. API Gateway container image (check if latest) ==="
docker inspect api-gateway --format '{{.Config.Image}}' 2>/dev/null || true
echo ""
echo "=== 5. Recent API Gateway logs (last 15 lines) ==="
docker logs api-gateway --tail 15 2>&1 || true
