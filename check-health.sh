#!/bin/bash

# Script to check health of all microservices endpoints

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Services to check (name:url format)
SERVICES=(
    "API Gateway:http://localhost:9000/actuator/health"
    "Product Service:http://localhost:8080/actuator/health"
    "Order Service:http://localhost:8081/actuator/health"
    "Inventory Service:http://localhost:8082/actuator/health"
)

# Monitoring services
MONITORING=(
    "Grafana:http://localhost:3000/api/health"
    "Prometheus:http://localhost:9090/-/healthy"
    "Zipkin:http://localhost:9411/health"
)

check_endpoint() {
    local name=$1
    local url=$2
    local timeout=${3:-5}
    
    # Try to get health status
    response=$(curl -s -w "\n%{http_code}" --max-time $timeout "$url" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" = "200" ]; then
        # Check if response contains "UP" or status
        if echo "$body" | grep -qi "\"status\":\"UP\"" || echo "$body" | grep -qi "\"status\":\"up\"" || echo "$body" | grep -qi "UP"; then
            print_success "$name: Healthy (HTTP $http_code)"
            return 0
        else
            # If we got 200 but can't parse, assume it's OK
            print_success "$name: Responding (HTTP $http_code)"
            return 0
        fi
    elif [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        # Authentication required - endpoint exists but needs auth
        print_warning "$name: Requires authentication (HTTP $http_code) - Endpoint exists"
        return 0
    elif [ "$http_code" = "000" ]; then
        print_error "$name: Not reachable (Connection failed)"
        return 1
    elif [ "$http_code" = "404" ]; then
        print_error "$name: Endpoint not found (HTTP $http_code)"
        return 1
    else
        print_error "$name: Unhealthy (HTTP $http_code)"
        return 1
    fi
}

check_all_services() {
    echo ""
    print_info "=========================================="
    print_info "Checking Microservices Health"
    print_info "=========================================="
    echo ""
    
    local healthy=0
    local total=0
    
    for service_info in "${SERVICES[@]}"; do
        IFS=':' read -r name url <<< "$service_info"
        total=$((total + 1))
        if check_endpoint "$name" "$url"; then
            healthy=$((healthy + 1))
        fi
        echo ""
    done
    
    echo ""
    print_info "=========================================="
    print_info "Checking Monitoring Services"
    print_info "=========================================="
    echo ""
    
    for service_info in "${MONITORING[@]}"; do
        IFS=':' read -r name url <<< "$service_info"
        total=$((total + 1))
        if check_endpoint "$name" "$url"; then
            healthy=$((healthy + 1))
        fi
        echo ""
    done
    
    echo ""
    print_info "=========================================="
    print_info "Summary: $healthy/$total services healthy"
    print_info "=========================================="
    echo ""
    
    if [ $healthy -eq $total ]; then
        print_success "All services are healthy! 🎉"
        return 0
    else
        print_warning "Some services are not healthy"
        return 1
    fi
}

# Check if services are running in Docker
check_docker_services() {
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
        if docker-compose ps 2>/dev/null | grep -q "Up" || docker compose ps 2>/dev/null | grep -q "Up"; then
            print_info "Docker services are running"
            return 0
        fi
    fi
    return 1
}

# Main
main() {
    echo ""
    print_info "Health Check for Microservices"
    echo ""
    
    # Check if Docker services are running
    if check_docker_services; then
        print_info "Checking services in Docker containers..."
    else
        print_warning "Docker services may not be running"
        print_info "Start services with: ./test-locally.sh start"
        echo ""
    fi
    
    check_all_services
}

main "$@"

