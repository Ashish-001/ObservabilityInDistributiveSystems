#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# PID file to track running services
PID_FILE="$PROJECT_ROOT/.application.pids"

# Function to print colored messages
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

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}


# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to wait for a service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
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
    print_warning "$service_name may not be fully ready yet, but continuing..."
    return 1
}

# Function to start Docker services
start_docker_services() {
    print_info "Starting Docker services..."
    
    if docker-compose ps | grep -q "Up"; then
        print_warning "Some Docker services are already running"
    else
        docker-compose up -d
        if [ $? -eq 0 ]; then
            print_success "Docker services started successfully"
            print_info "Waiting for Docker services to be ready..."
            sleep 10
        else
            print_error "Failed to start Docker services"
            exit 1
        fi
    fi
    
    # Wait for key services
    print_info "Waiting for MySQL to be ready..."
    sleep 5
    print_info "Waiting for MongoDB to be ready..."
    sleep 5
}

# Function to build all services
build_services() {
    print_info "Building all Spring Boot services..."
    mvn clean install -DskipTests
    if [ $? -eq 0 ]; then
        print_success "All services built successfully"
    else
        print_error "Failed to build services"
        exit 1
    fi
}

# Function to start a Spring Boot service
start_service() {
    local service_name=$1
    local service_dir="$PROJECT_ROOT/$service_name"
    local jar_file="$service_dir/target/$service_name-*.jar"
    
    if [ ! -d "$service_dir" ]; then
        print_error "Service directory not found: $service_dir"
        return 1
    fi
    
    # Check if service is already running
    local port=""
    case $service_name in
        api-gateway)
            port=9000
            ;;
        product-service)
            port=8080
            ;;
        order-service)
            port=8081
            ;;
        inventory-service)
            port=8082
            ;;
    esac
    
    if [ -n "$port" ] && check_port $port; then
        print_warning "$service_name is already running on port $port"
        return 0
    fi
    
    # Find the JAR file
    local jar_path=$(ls $jar_file 2>/dev/null | head -n 1)
    if [ -z "$jar_path" ]; then
        print_error "JAR file not found for $service_name. Building..."
        cd "$service_dir"
        mvn clean package -DskipTests
        cd "$PROJECT_ROOT"
        jar_path=$(ls $jar_file 2>/dev/null | head -n 1)
        if [ -z "$jar_path" ]; then
            print_error "Failed to build $service_name"
            return 1
        fi
    fi
    
    print_info "Starting $service_name..."
    cd "$service_dir"
    nohup java -jar "$jar_path" > "$PROJECT_ROOT/logs/$service_name.log" 2>&1 &
    local pid=$!
    echo "$pid:$service_name" >> "$PID_FILE"
    cd "$PROJECT_ROOT"
    
    print_success "$service_name started with PID $pid"
    
    # Wait a bit for the service to start
    sleep 3
}


# Function to start all services
start_all_services() {
    print_info "Starting all Spring Boot services..."
    
    # Create logs directory
    mkdir -p "$PROJECT_ROOT/logs"
    
    # Clear PID file
    > "$PID_FILE"
    
    # Start services in order (dependencies first)
    start_service "product-service"
    sleep 2
    
    start_service "inventory-service"
    sleep 2
    
    start_service "order-service"
    sleep 2
    
    start_service "api-gateway"
    sleep 3
    
    print_success "All services started!"
    print_info "Service URLs:"
    echo "  - API Gateway:       http://localhost:9000"
    echo "  - Product Service:   http://localhost:8080"
    echo "  - Order Service:     http://localhost:8081"
    echo "  - Inventory Service: http://localhost:8082"
    echo ""
    print_info "Monitoring URLs:"
    echo "  - Grafana:           http://localhost:3000"
    echo "  - Prometheus:        http://localhost:9090"
    echo "  - Zipkin (Traces):   http://localhost:9411"
    echo "  - Keycloak:          http://localhost:8181"
    echo ""
    print_info "Logs are available in: $PROJECT_ROOT/logs/"
}

# Function to stop all services
stop_all_services() {
    print_info "Stopping all Spring Boot services..."
    
    if [ ! -f "$PID_FILE" ]; then
        print_warning "No PID file found. Services may not be running."
        return
    fi
    
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local pid=$(echo "$line" | cut -d: -f1)
            local service=$(echo "$line" | cut -d: -f2)
            
            if kill -0 "$pid" 2>/dev/null; then
                print_info "Stopping $service (PID: $pid)..."
                kill "$pid"
                sleep 1
                if kill -0 "$pid" 2>/dev/null; then
                    print_warning "Force killing $service..."
                    kill -9 "$pid"
                fi
                print_success "$service stopped"
            else
                print_warning "$service (PID: $pid) is not running"
            fi
        fi
    done < "$PID_FILE"
    
    rm -f "$PID_FILE"
    print_success "All services stopped"
}

# Function to stop Docker services
stop_docker_services() {
    print_info "Stopping Docker services..."
    docker-compose down
    print_success "Docker services stopped"
}

# Function to show status
show_status() {
    print_info "Application Status:"
    echo ""
    
    echo "Docker Services:"
    docker-compose ps
    echo ""
    
    echo "Spring Boot Services:"
    if [ -f "$PID_FILE" ]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                local pid=$(echo "$line" | cut -d: -f1)
                local service=$(echo "$line" | cut -d: -f2)
                if kill -0 "$pid" 2>/dev/null; then
                    echo "  ✓ $service (PID: $pid) - Running"
                else
                    echo "  ✗ $service (PID: $pid) - Not running"
                fi
            fi
        done < "$PID_FILE"
    else
        echo "  No services tracked"
    fi
    echo ""
    
    echo "Port Status:"
    for port in 9000 8080 8081 8082; do
        local service_name=""
        case $port in
            9000) service_name="API Gateway" ;;
            8080) service_name="Product Service" ;;
            8081) service_name="Order Service" ;;
            8082) service_name="Inventory Service" ;;
        esac
        if check_port $port; then
            echo "  ✓ Port $port ($service_name) - In use"
        else
            echo "  ✗ Port $port ($service_name) - Available"
        fi
    done
}

# Function to show logs
show_logs() {
    local service=$1
    if [ -z "$service" ]; then
        print_error "Please specify a service name"
        echo "Available services: api-gateway, product-service, order-service, inventory-service"
        return 1
    fi
    
    local log_file="$PROJECT_ROOT/logs/$service.log"
    if [ -f "$log_file" ]; then
        tail -f "$log_file"
    else
        print_error "Log file not found: $log_file"
    fi
}

# Main script logic
case "${1:-start}" in
    start)
        check_docker
        start_docker_services
        build_services
        start_all_services
        ;;
    stop)
        stop_all_services
        read -p "Do you want to stop Docker services as well? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            stop_docker_services
        fi
        ;;
    restart)
        check_docker
        stop_all_services
        sleep 2
        start_docker_services
        start_all_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    build)
        build_services
        ;;
    docker-start)
        check_docker
        start_docker_services
        ;;
    docker-stop)
        stop_docker_services
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|build|docker-start|docker-stop}"
        echo ""
        echo "Commands:"
        echo "  start         - Start Docker services and all Spring Boot services"
        echo "  stop          - Stop all Spring Boot services (optionally Docker services)"
        echo "  restart       - Restart all services"
        echo "  status        - Show status of all services"
        echo "  logs <service> - Show logs for a specific service"
        echo "  build         - Build all Spring Boot services"
        echo "  docker-start  - Start only Docker services"
        echo "  docker-stop   - Stop only Docker services"
        echo ""
        echo "Available services for logs:"
        echo "  api-gateway, product-service, order-service, inventory-service"
        echo ""
        echo "Examples:"
        echo "  $0 start"
        echo "  $0 logs order-service"
        echo "  $0 status"
        exit 1
        ;;
esac

