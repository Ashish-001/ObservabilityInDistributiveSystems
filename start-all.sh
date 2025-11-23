#!/bin/bash

###############################################################################
# Spring Boot Microservices - Complete Startup Script
# This script starts all Docker services and Spring Boot microservices
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# PID file to track running services
PID_FILE="$PROJECT_ROOT/.application.pids"
LOGS_DIR="$PROJECT_ROOT/logs"

###############################################################################
# Helper Functions
###############################################################################

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

print_header() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}\n"
}

###############################################################################
# Prerequisites Check
###############################################################################

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing_deps=()
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing_deps+=("Docker")
    elif ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    else
        print_success "Docker is installed and running"
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
        missing_deps+=("Docker Compose")
    else
        print_success "Docker Compose is available"
    fi
    
    # Check Java
    if ! command -v java &> /dev/null; then
        missing_deps+=("Java")
    else
        local java_version=$(java -version 2>&1 | head -n 1)
        print_success "Java is installed: $java_version"
    fi
    
    # Check Maven
    if ! command -v mvn &> /dev/null; then
        missing_deps+=("Maven")
    else
        local mvn_version=$(mvn -version | head -n 1)
        print_success "Maven is installed: $mvn_version"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    echo ""
}

###############################################################################
# Docker Services Management
###############################################################################

start_docker_services() {
    print_header "Starting Docker Services"
    
    if docker-compose ps | grep -q "Up" 2>/dev/null || docker compose ps | grep -q "Up" 2>/dev/null; then
        print_warning "Some Docker services are already running"
        docker-compose ps 2>/dev/null || docker compose ps
    else
        print_info "Starting Docker services (MySQL, MongoDB, Keycloak, Prometheus, Grafana, Tempo, Loki, Zipkin)..."
        
        if command -v docker-compose &> /dev/null; then
            docker-compose up -d
        else
            docker compose up -d
        fi
        
        if [ $? -eq 0 ]; then
            print_success "Docker services started successfully"
        else
            print_error "Failed to start Docker services"
            exit 1
        fi
    fi
    
    print_info "Waiting for Docker services to be ready..."
    sleep 10
    
    # Wait for key services
    print_info "Checking service health..."
    local services_ready=0
    local max_attempts=30
    
    for i in $(seq 1 $max_attempts); do
        if docker ps | grep -q "mysql.*Up" && \
           docker ps | grep -q "mongodb.*Up" && \
           docker ps | grep -q "grafana.*Up" && \
           docker ps | grep -q "prometheus.*Up"; then
            services_ready=1
            break
        fi
        echo -n "."
        sleep 2
    done
    echo ""
    
    if [ $services_ready -eq 1 ]; then
        print_success "Docker services are ready"
    else
        print_warning "Some Docker services may not be fully ready yet"
    fi
    
    echo ""
}

stop_docker_services() {
    print_header "Stopping Docker Services"
    
    if command -v docker-compose &> /dev/null; then
        docker-compose down
    else
        docker compose down
    fi
    
    print_success "Docker services stopped"
}

###############################################################################
# Spring Boot Services Management
###############################################################################

build_services() {
    print_header "Building Spring Boot Services"
    
    print_info "Building all services with Maven..."
    mvn clean install -DskipTests
    
    if [ $? -eq 0 ]; then
        print_success "All services built successfully"
    else
        print_error "Failed to build services"
        exit 1
    fi
    echo ""
}

check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

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
        print_warning "JAR file not found for $service_name. Building..."
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
    nohup java -jar "$jar_path" > "$LOGS_DIR/$service_name.log" 2>&1 &
    local pid=$!
    echo "$pid:$service_name" >> "$PID_FILE"
    cd "$PROJECT_ROOT"
    
    print_success "$service_name started with PID $pid"
    
    # Wait a bit for the service to start
    sleep 3
}

start_all_services() {
    print_header "Starting Spring Boot Services"
    
    # Create logs directory
    mkdir -p "$LOGS_DIR"
    
    # Clear PID file
    > "$PID_FILE"
    
    # Start services in order (dependencies first)
    print_info "Starting services in dependency order..."
    
    start_service "product-service"
    sleep 2
    
    start_service "inventory-service"
    sleep 2
    
    start_service "order-service"
    sleep 2
    
    start_service "api-gateway"
    sleep 3
    
    echo ""
    print_success "All Spring Boot services started!"
}

stop_all_services() {
    print_header "Stopping Spring Boot Services"
    
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
    print_success "All Spring Boot services stopped"
}

###############################################################################
# Status and Information
###############################################################################

show_status() {
    print_header "Application Status"
    
    echo "Docker Services:"
    if command -v docker-compose &> /dev/null; then
        docker-compose ps
    else
        docker compose ps
    fi
    echo ""
    
    echo "Spring Boot Services:"
    if [ -f "$PID_FILE" ]; then
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                local pid=$(echo "$line" | cut -d: -f1)
                local service=$(echo "$line" | cut -d: -f2)
                if kill -0 "$pid" 2>/dev/null; then
                    echo -e "  ${GREEN}✓${NC} $service (PID: $pid) - Running"
                else
                    echo -e "  ${RED}✗${NC} $service (PID: $pid) - Not running"
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
            echo -e "  ${GREEN}✓${NC} Port $port ($service_name) - In use"
        else
            echo -e "  ${RED}✗${NC} Port $port ($service_name) - Available"
        fi
    done
    echo ""
}

show_urls() {
    print_header "Service URLs"
    
    echo -e "${CYAN}Microservices:${NC}"
    echo "  - API Gateway:       http://localhost:9000"
    echo "  - Product Service:    http://localhost:8080"
    echo "  - Order Service:      http://localhost:8081"
    echo "  - Inventory Service:  http://localhost:8082"
    echo ""
    
    echo -e "${CYAN}Monitoring & Observability:${NC}"
    echo "  - Grafana:           http://localhost:3000"
    echo "  - Prometheus:         http://localhost:9090"
    echo "  - Zipkin (Traces):    http://localhost:9411"
    echo "  - Keycloak:           http://localhost:8181"
    echo ""
    
    echo -e "${CYAN}Actuator Endpoints:${NC}"
    echo "  - API Gateway:       http://localhost:9000/actuator"
    echo "  - Product Service:    http://localhost:8080/actuator"
    echo "  - Order Service:      http://localhost:8081/actuator"
    echo "  - Inventory Service:  http://localhost:8082/actuator"
    echo ""
    
    echo -e "${CYAN}Grafana Dashboards:${NC}"
    echo "  - Spring Boot Statistics: http://localhost:3000/d/sOae4vCnk/spring-boot-statistics"
    echo "  - Spring Actuator Metrics: http://localhost:3000/d/spring-actuator/spring-actuator-metrics"
    echo ""
    
    echo -e "${CYAN}Logs:${NC}"
    echo "  - Logs directory: $LOGS_DIR"
    echo ""
}

###############################################################################
# Main Functions
###############################################################################

start_all() {
    print_header "Starting Complete Microservices Stack"
    
    check_prerequisites
    start_docker_services
    build_services
    start_all_services
    
    echo ""
    print_success "=========================================="
    print_success "All services started successfully!"
    print_success "=========================================="
    echo ""
    
    show_urls
    show_status
}

stop_all() {
    print_header "Stopping Complete Microservices Stack"
    
    stop_all_services
    
    read -p "Do you want to stop Docker services as well? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        stop_docker_services
    fi
    
    print_success "All services stopped"
}

restart_all() {
    print_header "Restarting Complete Microservices Stack"
    
    stop_all_services
    sleep 2
    start_docker_services
    start_all_services
    
    print_success "All services restarted"
    show_urls
}

###############################################################################
# Main Script Logic
###############################################################################

case "${1:-start}" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    status)
        show_status
        show_urls
        ;;
    build)
        check_prerequisites
        build_services
        ;;
    docker-start)
        check_prerequisites
        start_docker_services
        ;;
    docker-stop)
        stop_docker_services
        ;;
    logs)
        local service=$2
        if [ -z "$service" ]; then
            print_error "Please specify a service name"
            echo "Available services: api-gateway, product-service, order-service, inventory-service"
            exit 1
        fi
        
        local log_file="$LOGS_DIR/$service.log"
        if [ -f "$log_file" ]; then
            tail -f "$log_file"
        else
            print_error "Log file not found: $log_file"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|build|docker-start|docker-stop|logs <service>}"
        echo ""
        echo "Commands:"
        echo "  start          - Start everything (Docker + Spring Boot services)"
        echo "  stop           - Stop all services (optionally Docker services)"
        echo "  restart        - Restart all services"
        echo "  status         - Show status of all services"
        echo "  build          - Build all Spring Boot services"
        echo "  docker-start   - Start only Docker services"
        echo "  docker-stop    - Stop only Docker services"
        echo "  logs <service> - Show logs for a specific service"
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

