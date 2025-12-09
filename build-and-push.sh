#!/bin/bash

# Script to build and push all microservices to Docker Hub
# Usage: ./build-and-push.sh [version] [dockerhub-username]
# Example: ./build-and-push.sh 1.0.0 chauhankumarashu

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
VERSION=${1:-latest}
DOCKERHUB_USERNAME=${2:-chauhankumarashu}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Services to build
SERVICES=("api-gateway" "product-service" "order-service" "inventory-service")

print_info "=========================================="
print_info "Building and Pushing Microservices"
print_info "=========================================="
print_info "Version: $VERSION"
print_info "Docker Hub Username: $DOCKERHUB_USERNAME"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    print_warning "Not logged in to Docker Hub. Attempting to login..."
    docker login
fi

cd "$PROJECT_ROOT"

# Build and push each service
for service in "${SERVICES[@]}"; do
    print_info "Building $service..."
    
    SERVICE_DIR="$PROJECT_ROOT/$service"
    IMAGE_NAME="$DOCKERHUB_USERNAME/$service:$VERSION"
    IMAGE_NAME_LATEST="$DOCKERHUB_USERNAME/$service:latest"
    
    if [ ! -d "$SERVICE_DIR" ]; then
        print_error "Service directory not found: $SERVICE_DIR"
        continue
    fi
    
    # Build from project root to access parent pom.xml
    cd "$PROJECT_ROOT"
    docker build -f "$SERVICE_DIR/Dockerfile" -t "$IMAGE_NAME" -t "$IMAGE_NAME_LATEST" .
    
    if [ $? -eq 0 ]; then
        print_success "$service built successfully"
        
        print_info "Pushing $service to Docker Hub..."
        docker push "$IMAGE_NAME"
        docker push "$IMAGE_NAME_LATEST"
        
        if [ $? -eq 0 ]; then
            print_success "$service pushed to Docker Hub"
        else
            print_error "Failed to push $service"
        fi
    else
        print_error "Failed to build $service"
    fi
    
    echo ""
done

print_success "=========================================="
print_success "All services built and pushed!"
print_success "=========================================="
echo ""
print_info "Images pushed:"
for service in "${SERVICES[@]}"; do
    echo "  - $DOCKERHUB_USERNAME/$service:$VERSION"
    echo "  - $DOCKERHUB_USERNAME/$service:latest"
done

