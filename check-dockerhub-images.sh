#!/bin/bash

# Script to check Docker Hub images
# Usage: ./check-dockerhub-images.sh [dockerhub-username]
# Example: ./check-dockerhub-images.sh chauhankumarashu

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOCKERHUB_USERNAME=${1:-chauhankumarashu}

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

print_info "=========================================="
print_info "Checking Docker Hub Images"
print_info "=========================================="
print_info "Docker Hub Username: $DOCKERHUB_USERNAME"
echo ""

# Services to check
SERVICES=("api-gateway" "product-service" "order-service" "inventory-service")

print_info "1. Local Docker Images:"
echo ""
docker images | grep "$DOCKERHUB_USERNAME" || print_warning "No local images found for $DOCKERHUB_USERNAME"
echo ""

print_info "2. Docker Hub URLs:"
echo ""
for service in "${SERVICES[@]}"; do
    echo "  https://hub.docker.com/r/$DOCKERHUB_USERNAME/$service"
done
echo ""

print_info "3. Checking if images exist on Docker Hub..."
echo ""
print_warning "Note: This requires 'docker manifest inspect' which may require authentication"
echo ""

for service in "${SERVICES[@]}"; do
    IMAGE_NAME="$DOCKERHUB_USERNAME/$service:latest"
    print_info "Checking $IMAGE_NAME..."
    
    if docker manifest inspect "$IMAGE_NAME" > /dev/null 2>&1; then
        print_success "✓ $IMAGE_NAME exists on Docker Hub"
        
        # Get image details
        MANIFEST=$(docker manifest inspect "$IMAGE_NAME" 2>/dev/null)
        if echo "$MANIFEST" | grep -q "schemaVersion"; then
            print_info "  Image is available and accessible"
        fi
    else
        print_error "✗ $IMAGE_NAME not found or not accessible"
        print_warning "  Make sure you're logged in: docker login"
        print_warning "  Or check if the image was pushed: ./build-and-push.sh 1.0.0 $DOCKERHUB_USERNAME"
    fi
    echo ""
done

print_info "4. Quick Commands:"
echo ""
echo "  View on Docker Hub:"
echo "    open https://hub.docker.com/r/$DOCKERHUB_USERNAME"
echo ""
echo "  Pull an image:"
echo "    docker pull $DOCKERHUB_USERNAME/api-gateway:latest"
echo ""
echo "  List all tags for a service:"
echo "    curl -s https://hub.docker.com/v2/repositories/$DOCKERHUB_USERNAME/api-gateway/tags/ | jq '.results[].name'"
echo ""

