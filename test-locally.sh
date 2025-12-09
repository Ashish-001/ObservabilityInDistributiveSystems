#!/bin/bash

# Script to test microservices locally
# This script provides options to test with Docker Hub images or build locally

# Don't exit on error - we want to handle errors gracefully
set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

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

# Check if Docker is running
check_docker() {
    local retries=3
    local count=0
    
    while [ $count -lt $retries ]; do
        if docker info > /dev/null 2>&1; then
            print_success "Docker is running"
            return 0
        fi
        
        count=$((count + 1))
        if [ $count -lt $retries ]; then
            print_warning "Docker is not running. Waiting 2 seconds... (attempt $count/$retries)"
            sleep 2
        fi
    done
    
    print_error "Docker is not running. Please start Docker Desktop and try again."
    print_info "On macOS: Open Docker Desktop application"
    exit 1
}

# Verify Docker is still running (call before critical operations)
verify_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker daemon stopped during execution!"
        print_info "Please start Docker Desktop and run the script again."
        exit 1
    fi
}

# Check if port is used by Docker container
is_docker_port() {
    local port=$1
    # Check if any Docker container is using this port
    if docker ps --format "{{.Ports}}" 2>/dev/null | grep -q ":$port->"; then
        return 0
    fi
    return 1
}

# Check and free up ports
check_ports() {
    print_info "Checking if ports are available..."
    PORTS=(8080 8081 8082 9000)
    PORTS_IN_USE=()
    DOCKER_PORTS=()
    JAVA_PORTS=()
    
    for port in "${PORTS[@]}"; do
        if lsof -ti :$port > /dev/null 2>&1; then
            PORTS_IN_USE+=($port)
            # Check if it's a Docker container
            if is_docker_port $port; then
                DOCKER_PORTS+=($port)
            else
                JAVA_PORTS+=($port)
            fi
        fi
    done
    
    if [ ${#PORTS_IN_USE[@]} -gt 0 ]; then
        # If ports are used by Docker containers, that's fine - we'll stop them with docker-compose
        if [ ${#DOCKER_PORTS[@]} -gt 0 ]; then
            print_info "Ports ${DOCKER_PORTS[*]} are used by Docker containers (will be stopped)"
        fi
        
        # Handle Java processes
        if [ ${#JAVA_PORTS[@]} -gt 0 ]; then
            print_warning "Ports ${JAVA_PORTS[*]} are in use by local processes. Attempting to free them..."
            if [ -f "stop-local-services.sh" ]; then
                ./stop-local-services.sh
            else
                # Manual cleanup - only kill Java processes
                for port in "${JAVA_PORTS[@]}"; do
                    PIDS=$(lsof -ti :$port 2>/dev/null)
                    for pid in $PIDS; do
                        # Only kill Java processes, not Docker processes
                        if ps -p $pid -o comm= 2>/dev/null | grep -qi "java"; then
                            print_info "Stopping Java process on port $port (PID: $pid)..."
                            kill $pid 2>/dev/null || kill -9 $pid 2>/dev/null
                        else
                            print_warning "Skipping non-Java process on port $port (PID: $pid)"
                        fi
                    done
                done
                sleep 2
            fi
        fi
        
        # Verify Java ports are free (Docker ports will be handled by docker-compose)
        for port in "${JAVA_PORTS[@]}"; do
            if lsof -ti :$port > /dev/null 2>&1; then
                # Check if it's still a Java process or if it's now Docker
                PIDS=$(lsof -ti :$port 2>/dev/null)
                IS_JAVA=false
                for pid in $PIDS; do
                    if ps -p $pid -o comm= 2>/dev/null | grep -qi "java"; then
                        IS_JAVA=true
                        break
                    fi
                done
                if [ "$IS_JAVA" = true ]; then
                    print_error "Port $port is still in use by a Java process. Please stop it manually."
                    exit 1
                elif is_docker_port $port; then
                    print_info "Port $port is now used by Docker (OK)"
                fi
            fi
        done
        
        if [ ${#DOCKER_PORTS[@]} -gt 0 ]; then
            print_info "Docker containers using ports will be stopped/restarted by docker-compose"
        fi
        
        print_success "Ports check completed"
        
        # Verify Docker is still running after port cleanup
        verify_docker
    else
        print_success "All ports are available"
    fi
}

# Build images locally
build_local() {
    print_info "Building all microservices locally..."
    
    verify_docker
    
    SERVICES=("api-gateway" "product-service" "order-service" "inventory-service")
    FAILED=0
    
    for service in "${SERVICES[@]}"; do
        print_info "Building $service..."
        
        # Verify Docker before each build
        verify_docker
        
        if docker build -f "$service/Dockerfile" -t "chauhankumarashu/$service:local" . 2>&1; then
            print_success "$service built successfully"
        else
            print_error "Failed to build $service"
            # Check if Docker stopped
            if ! docker info > /dev/null 2>&1; then
                print_error "Docker daemon stopped during build!"
                print_info "Please start Docker Desktop and try again."
                return 1
            fi
            FAILED=$((FAILED + 1))
        fi
    done
    
    if [ $FAILED -eq 0 ]; then
        print_success "All services built successfully!"
        return 0
    else
        print_error "$FAILED service(s) failed to build"
        return 1
    fi
}

# Update docker-compose to use local images
use_local_images() {
    print_info "Updating docker-compose.yml to use local images..."
    
    # Create a temporary docker-compose file with local images
    sed 's/chauhankumarashu\/\(.*\):latest/chauhankumarashu\/\1:local/g' docker-compose.yml > docker-compose.local.yml
    
    print_success "Created docker-compose.local.yml with local images"
    echo "Use: docker-compose -f docker-compose.local.yml up"
}

# Test with Docker Hub images
test_with_dockerhub() {
    verify_docker
    print_info "Checking for images..."
    
    # Check if local images exist first
    if docker images | grep -q "chauhankumarashu/api-gateway:local"; then
        print_info "Using local images..."
        verify_docker
        docker-compose up -d
        return
    fi
    
    # Try Docker Hub
    print_info "Trying Docker Hub images..."
    verify_docker
    docker pull chauhankumarashu/api-gateway:latest 2>/dev/null || {
        print_warning "Images not found. Building locally..."
        build_local
        verify_docker
        docker-compose up -d
        return
    }
    
    verify_docker
    docker-compose up -d
}

# Start services
start_services() {
    local compose_file=${1:-docker-compose.yml}
    
    check_ports
    
    # Verify Docker is still running after port cleanup
    verify_docker
    
    # Build images if they don't exist
    if ! docker images | grep -q "chauhankumarashu/api-gateway:local"; then
        print_info "Local images not found. Building..."
        if ! build_local; then
            print_error "Failed to build images"
            return 1
        fi
    fi
    
    # Verify Docker before starting services
    verify_docker
    
    print_info "Starting infrastructure services first (databases, monitoring)..."
    # Start infrastructure first - don't fail if some are already running
    if ! docker-compose -f "$compose_file" up -d mysql mongodb keycloak-mysql keycloak prometheus zipkin loki grafana tempo 2>&1; then
        verify_docker
        print_warning "Some infrastructure services may have failed to start"
    fi
    
    print_info "Waiting for infrastructure to be ready..."
    sleep 15
    
    # Check if infrastructure is actually running
    verify_docker
    print_info "Verifying infrastructure services..."
    if ! docker-compose -f "$compose_file" ps mysql mongodb | grep -q "Up"; then
        print_warning "Some infrastructure services may not be running. They will auto-restart."
    fi
    
    print_info "Starting microservices..."
    # Verify Docker before starting microservices
    verify_docker
    
    # Then start microservices
    if ! docker-compose -f "$compose_file" up -d api-gateway product-service order-service inventory-service 2>&1; then
        verify_docker
        print_error "Failed to start some services"
        print_info "Check logs with: docker-compose logs"
        return 1
    fi
    
    print_info "Waiting for services to be ready..."
    sleep 15
    
    # Check service health (don't fail if health checks fail)
    check_health || true
    
    print_success "Services started! They may take a minute to fully initialize."
    return 0
}

# Check service health
check_health() {
    print_info "Checking service health..."
    echo ""
    
    if [ -f "check-health.sh" ]; then
        ./check-health.sh
    else
        SERVICES=(
            "API Gateway:9000"
            "Product Service:8080"
            "Order Service:8081"
            "Inventory Service:8082"
        )
        
        for service_info in "${SERVICES[@]}"; do
            IFS=':' read -r name port <<< "$service_info"
            if curl -s "http://localhost:$port/actuator/health" > /dev/null 2>&1; then
                print_success "$name is healthy"
            else
                print_warning "$name is not ready yet (this is normal, it may take a minute)"
            fi
        done
    fi
}

# Show service URLs
show_urls() {
    echo ""
    print_success "=========================================="
    print_success "Services are running!"
    print_success "=========================================="
    echo ""
    print_info "Microservices:"
    echo "  - API Gateway:       http://localhost:9000"
    echo "  - Product Service:   http://localhost:8080"
    echo "  - Order Service:     http://localhost:8081"
    echo "  - Inventory Service: http://localhost:8082"
    echo ""
    print_info "Monitoring:"
    echo "  - Grafana:           http://localhost:3000"
    echo "  - Prometheus:        http://localhost:9090"
    echo "  - Zipkin:            http://localhost:9411"
    echo "  - Keycloak:          http://localhost:8181"
    echo ""
    print_info "API Documentation:"
    echo "  - Swagger UI:         http://localhost:9000/swagger-ui.html"
    echo ""
    print_info "Health Checks:"
    echo "  - API Gateway:       http://localhost:9000/actuator/health"
    echo "  - Product Service:   http://localhost:8080/actuator/health"
    echo "  - Order Service:     http://localhost:8081/actuator/health"
    echo "  - Inventory Service: http://localhost:8082/actuator/health"
    echo ""
}

# Stop services
stop_services() {
    local compose_file=${1:-docker-compose.yml}
    
    # Verify Docker is running before stopping
    if ! docker info > /dev/null 2>&1; then
        print_warning "Docker is not running. Services may already be stopped."
        return 0
    fi
    
    print_info "Stopping all services..."
    
    # Stop services gracefully (don't remove volumes to avoid issues)
    if docker-compose -f "$compose_file" stop 2>&1; then
        print_success "All services stopped"
        
        # Verify Docker is still running after stop
        sleep 1
        if docker info > /dev/null 2>&1; then
            print_info "Docker is still running"
        else
            print_warning "Docker stopped after service shutdown (this may be normal if Docker Desktop auto-pauses)"
        fi
    else
        print_warning "Some services may have failed to stop gracefully"
        # Verify Docker is still running
        if docker info > /dev/null 2>&1; then
            print_info "Docker is still running"
        else
            print_error "Docker stopped during service shutdown!"
            print_info "Please restart Docker Desktop"
        fi
    fi
}

# View logs
view_logs() {
    local service=$1
    local compose_file=${2:-docker-compose.yml}
    
    if [ -z "$service" ]; then
        print_info "Showing logs for all services..."
        docker-compose -f "$compose_file" logs -f
    else
        print_info "Showing logs for $service..."
        docker-compose -f "$compose_file" logs -f "$service"
    fi
}

# Main menu
main() {
    check_docker
    
    case "${1:-menu}" in
        build)
            build_local
            use_local_images
            ;;
        start)
            if [ -f "docker-compose.local.yml" ]; then
                if start_services "docker-compose.local.yml"; then
                    show_urls
                else
                    print_error "Failed to start services. Check logs with: docker-compose logs"
                    exit 1
                fi
            else
                test_with_dockerhub
                if start_services; then
                    show_urls
                else
                    print_error "Failed to start services. Check logs with: docker-compose logs"
                    exit 1
                fi
            fi
            ;;
        stop)
            if [ -f "docker-compose.local.yml" ]; then
                stop_services "docker-compose.local.yml"
            else
                stop_services
            fi
            ;;
        logs)
            if [ -f "docker-compose.local.yml" ]; then
                view_logs "$2" "docker-compose.local.yml"
            else
                view_logs "$2"
            fi
            ;;
        health)
            check_health
            ;;
        clean)
            print_info "Cleaning up..."
            
            # Verify Docker is running
            if ! docker info > /dev/null 2>&1; then
                print_warning "Docker is not running. Skipping cleanup."
                return 0
            fi
            
            docker-compose down -v 2>/dev/null || true
            docker-compose -f docker-compose.local.yml down -v 2>/dev/null || true
            
            # Verify Docker is still running before prune
            if docker info > /dev/null 2>&1; then
                docker system prune -f
                print_success "Cleanup completed"
            else
                print_warning "Docker stopped during cleanup. Skipping system prune."
            fi
            ;;
        menu|*)
            echo "Usage: $0 {build|start|stop|logs|health|clean}"
            echo ""
            echo "Commands:"
            echo "  build   - Build all microservices locally"
            echo "  start   - Start all services (builds locally if Docker Hub images not found)"
            echo "  stop    - Stop all services"
            echo "  logs    - View logs (optionally specify service name)"
            echo "  health  - Check health of all services"
            echo "  clean   - Stop services and clean up"
            echo ""
            echo "Examples:"
            echo "  $0 build              # Build all services locally"
            echo "  $0 start              # Start all services"
            echo "  $0 logs api-gateway   # View API Gateway logs"
            echo "  $0 health             # Check service health"
            echo "  $0 stop               # Stop all services"
            ;;
    esac
}

main "$@"

