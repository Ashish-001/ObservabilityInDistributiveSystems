#!/bin/bash
# Check what JVM thread metrics are exposed by each service and in Prometheus.
# Run with stack up (e.g. docker compose up -d). Uses host ports: 9000, 8080, 8081, 8082, 9090.
set -e
echo "=== JVM thread metrics from each service /actuator/prometheus ==="
for name in "api-gateway:9000" "product-service:8080" "order-service:8081" "inventory-service:8082"; do
  echo "--- $name ---"
  curl -s "http://localhost:${name#*:}/actuator/prometheus" 2>/dev/null | grep -E "^jvm_threads" || echo "(none or endpoint unreachable)"
done
echo ""
echo "=== Prometheus: series matching jvm_threads (run when Prometheus has scraped) ==="
echo "In Prometheus UI (http://localhost:9090) run: {__name__=~\"jvm_threads.*\"}"
echo "Or: jvm_threads_live and jvm_threads_current"
