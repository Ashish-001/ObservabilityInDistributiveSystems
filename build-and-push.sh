#!/bin/bash
set -e

# Usage: ./build-and-push-multiarch.sh [version] [dockerhub-username]
# Example: ./build-and-push-multiarch.sh 1.0.0 chauhankumarashu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION=${1:-latest}
DOCKERHUB_USERNAME=${2:-chauhankumarashu}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SERVICES=("api-gateway" "product-service" "order-service" "inventory-service")
PLATFORMS="linux/amd64,linux/arm64"

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

print_info "=========================================="
print_info "Building & Pushing MULTI-ARCH Microservices"
print_info "=========================================="
print_info "Version: $VERSION"
print_info "Docker Hub Username: $DOCKERHUB_USERNAME"
print_info "Platforms: $PLATFORMS"
echo ""

# Check docker
if ! docker info > /dev/null 2>&1; then
  print_error "Docker is not running."
  exit 1
fi

# Login
if ! docker info | grep -q "Username"; then
  print_warning "Not logged in. Running docker login..."
  docker login
fi

# Enable QEMU (needed when building non-native arch, e.g. amd64 on arm)
print_info "Setting up QEMU for cross-platform builds..."
docker run --privileged --rm tonistiigi/binfmt --install all >/dev/null

# Ensure buildx builder exists and is used
BUILDER_NAME="multiarch-builder"
if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
  print_info "Creating buildx builder: $BUILDER_NAME"
  docker buildx create --name "$BUILDER_NAME" --use
else
  print_info "Using existing buildx builder: $BUILDER_NAME"
  docker buildx use "$BUILDER_NAME"
fi

# Bootstrap builder
docker buildx inspect --bootstrap >/dev/null

cd "$PROJECT_ROOT"

for service in "${SERVICES[@]}"; do
  SERVICE_DIR="$PROJECT_ROOT/$service"
  if [ ! -d "$SERVICE_DIR" ]; then
    print_error "Service directory not found: $SERVICE_DIR"
    continue
  fi

  IMAGE_VERSION="$DOCKERHUB_USERNAME/$service:$VERSION"
  IMAGE_LATEST="$DOCKERHUB_USERNAME/$service:latest"

  print_info "Building & pushing multi-arch: $service"
  print_info "-> $IMAGE_VERSION"
  print_info "-> $IMAGE_LATEST"

  # Multi-arch build + push (no local image needed)
  docker buildx build \
    --platform "$PLATFORMS" \
    -f "$SERVICE_DIR/Dockerfile" \
    -t "$IMAGE_VERSION" \
    -t "$IMAGE_LATEST" \
    --push \
    "$PROJECT_ROOT"

  print_success "$service pushed as multi-arch ✅"
  echo ""
done

print_success "=========================================="
print_success "All services built & pushed (multi-arch) ✅"
print_success "=========================================="

print_info "Verify manifests (example):"
print_info "docker buildx imagetools inspect $DOCKERHUB_USERNAME/product-service:latest"
