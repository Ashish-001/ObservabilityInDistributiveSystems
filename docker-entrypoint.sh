#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to wait for a service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=60
    local attempt=1
    
    print_info "Waiting for $service_name to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1 || curl -s "$url/actuator/health" > /dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    echo ""
    print_warning "$service_name may not be fully ready yet"
    return 1
}

# Function to start a service
start_service() {
    local service_name=$1
    local jar_file="/app/services/$service_name.jar"
    local log_file="/app/logs/$service_name.log"
    
    if [ ! -f "$jar_file" ]; then
        print_error "JAR file not found: $jar_file"
        return 1
    fi
    
    # Build Java command with system properties from environment variables
    local java_opts=""
    
    case $service_name in
        product-service)
            # MongoDB connection
            if [ -n "$SPRING_DATA_MONGODB_URI" ]; then
                java_opts="$java_opts -Dspring.data.mongodb.uri=$SPRING_DATA_MONGODB_URI"
            fi
            # Loki URL
            if [ -n "$LOKI_URL" ]; then
                java_opts="$java_opts -Dloki.url=$LOKI_URL"
            fi
            # Zipkin endpoint
            if [ -n "$MANAGEMENT_ZIPKIN_TRACING_ENDPOINT" ]; then
                java_opts="$java_opts -Dmanagement.zipkin.tracing.endpoint=$MANAGEMENT_ZIPKIN_TRACING_ENDPOINT"
            fi
            ;;
        order-service)
            # MySQL connection
            if [ -n "$ORDER_SERVICE_SPRING_DATASOURCE_URL" ]; then
                java_opts="$java_opts -Dspring.datasource.url=$ORDER_SERVICE_SPRING_DATASOURCE_URL"
            fi
            # Loki URL
            if [ -n "$LOKI_URL" ]; then
                java_opts="$java_opts -Dloki.url=$LOKI_URL"
            fi
            # Zipkin endpoint
            if [ -n "$MANAGEMENT_ZIPKIN_TRACING_ENDPOINT" ]; then
                java_opts="$java_opts -Dmanagement.zipkin.tracing.endpoint=$MANAGEMENT_ZIPKIN_TRACING_ENDPOINT"
            fi
            ;;
        inventory-service)
            # MySQL connection
            if [ -n "$INVENTORY_SERVICE_SPRING_DATASOURCE_URL" ]; then
                java_opts="$java_opts -Dspring.datasource.url=$INVENTORY_SERVICE_SPRING_DATASOURCE_URL"
            fi
            # Loki URL
            if [ -n "$LOKI_URL" ]; then
                java_opts="$java_opts -Dloki.url=$LOKI_URL"
            fi
            # Zipkin endpoint
            if [ -n "$MANAGEMENT_ZIPKIN_TRACING_ENDPOINT" ]; then
                java_opts="$java_opts -Dmanagement.zipkin.tracing.endpoint=$MANAGEMENT_ZIPKIN_TRACING_ENDPOINT"
            fi
            ;;
        api-gateway)
            # Keycloak issuer URI
            if [ -n "$SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI" ]; then
                java_opts="$java_opts -Dspring.security.oauth2.resourceserver.jwt.issuer-uri=$SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI"
            fi
            # Loki URL
            if [ -n "$LOKI_URL" ]; then
                java_opts="$java_opts -Dloki.url=$LOKI_URL"
            fi
            # Zipkin endpoint
            if [ -n "$MANAGEMENT_ZIPKIN_TRACING_ENDPOINT" ]; then
                java_opts="$java_opts -Dmanagement.zipkin.tracing.endpoint=$MANAGEMENT_ZIPKIN_TRACING_ENDPOINT"
            fi
            ;;
    esac
    
    print_info "Starting $service_name..."
    java $java_opts -jar "$jar_file" > "$log_file" 2>&1 &
    local pid=$!
    echo $pid > "/app/logs/$service_name.pid"
    print_success "$service_name started with PID $pid"
    
    # Wait a bit for the service to initialize
    sleep 3
}

# Function to stop a service
stop_service() {
    local service_name=$1
    local pid_file="/app/logs/$service_name.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_info "Stopping $service_name (PID: $pid)..."
            kill "$pid" 2>/dev/null || true
            sleep 2
            if kill -0 "$pid" 2>/dev/null; then
                print_warning "Force killing $service_name..."
                kill -9 "$pid" 2>/dev/null || true
            fi
            print_success "$service_name stopped"
        fi
        rm -f "$pid_file"
    fi
}

# Cleanup function
cleanup() {
    print_info "Shutting down services..."
    stop_service "product-service"
    stop_service "inventory-service"
    stop_service "order-service"
    stop_service "api-gateway"
    print_success "All services stopped"
    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGTERM SIGINT

# Create logs directory
mkdir -p /app/logs

print_info "=========================================="
print_info "Starting Spring Boot Microservices"
print_info "=========================================="
echo ""

# Start services in dependency order
start_service "product-service"
start_service "inventory-service"
start_service "order-service"
start_service "api-gateway"

echo ""
print_success "=========================================="
print_success "All services started!"
print_success "=========================================="
echo ""
print_info "Service URLs:"
echo "  - API Gateway:       http://localhost:9000"
echo "  - Product Service:   http://localhost:8080"
echo "  - Order Service:     http://localhost:8081"
echo "  - Inventory Service: http://localhost:8082"
echo ""
print_info "Logs are available in: /app/logs/"
echo ""

# Wait for services to be ready
wait_for_service "http://localhost:8080/actuator/health" "Product Service"
wait_for_service "http://localhost:8082/actuator/health" "Inventory Service"
wait_for_service "http://localhost:8081/actuator/health" "Order Service"
wait_for_service "http://localhost:9000/actuator/health" "API Gateway"

echo ""
print_success "All services are ready!"
echo ""

# Keep the container running and monitor services
while true; do
    sleep 10
    # Check if any service has died
    for service in product-service inventory-service order-service api-gateway; do
        pid_file="/app/logs/$service.pid"
        if [ -f "$pid_file" ]; then
            pid=$(cat "$pid_file")
            if ! kill -0 "$pid" 2>/dev/null; then
                print_error "$service has stopped unexpectedly!"
                # Optionally restart it
                start_service "$service"
            fi
        fi
    done
done

