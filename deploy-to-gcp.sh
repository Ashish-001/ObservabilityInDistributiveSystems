#!/bin/bash

# Script to deploy microservices to Google Cloud Run
# Usage: ./deploy-to-gcp.sh [dockerhub-username] [region] [version]
# Example: ./deploy-to-gcp.sh chauhankumarashu us-central1 latest

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DOCKERHUB_USERNAME=${1:-chauhankumarashu}
REGION=${2:-us-central1}
VERSION=${3:-latest}

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

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install it first:"
    echo "  https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if logged in
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_warning "Not logged in to GCP. Please login:"
    echo "  gcloud auth login"
    exit 1
fi

print_info "=========================================="
print_info "Deploying Microservices to GCP Cloud Run"
print_info "=========================================="
print_info "Docker Hub Username: $DOCKERHUB_USERNAME"
print_info "Region: $REGION"
print_info "Version: $VERSION"
echo ""

# Get project ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    print_error "No GCP project set. Please set it:"
    echo "  gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

print_info "Project ID: $PROJECT_ID"
echo ""

# Services to deploy
SERVICES=("api-gateway" "product-service" "order-service" "inventory-service")

# Ask for database connection details
print_info "Database Configuration Required"
echo ""
read -p "MySQL Host (IP or hostname): " MYSQL_HOST
read -p "MySQL Port [3306]: " MYSQL_PORT
MYSQL_PORT=${MYSQL_PORT:-3306}
read -p "MySQL Root Password: " MYSQL_PASSWORD
read -p "MongoDB URI (e.g., mongodb://user:pass@host:27017/db): " MONGODB_URI

echo ""
print_warning "Make sure your databases are accessible from Cloud Run!"
print_warning "You may need to set up VPC connector or allow public IP access."
echo ""
read -p "Continue with deployment? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Deployment cancelled"
    exit 0
fi

# Deploy each service
for service in "${SERVICES[@]}"; do
    print_info "Deploying $service..."
    
    IMAGE_NAME="$DOCKERHUB_USERNAME/$service:$VERSION"
    
    # Build deployment command based on service
    case $service in
        "api-gateway")
            gcloud run deploy api-gateway \
                --image "$IMAGE_NAME" \
                --platform managed \
                --region "$REGION" \
                --allow-unauthenticated \
                --port 9000 \
                --memory 512Mi \
                --cpu 1 \
                --set-env-vars="SPRING_DATASOURCE_URL=jdbc:mysql://$MYSQL_HOST:$MYSQL_PORT/order_service" \
                --set-env-vars="SPRING_DATASOURCE_USERNAME=root" \
                --set-env-vars="SPRING_DATASOURCE_PASSWORD=$MYSQL_PASSWORD" \
                --set-env-vars="SPRING_DATA_MONGODB_URI=$MONGODB_URI" \
                --set-env-vars="SPRING_PROFILES_ACTIVE=prod" \
                --quiet
            
            if [ $? -eq 0 ]; then
                API_GATEWAY_URL=$(gcloud run services describe api-gateway --region "$REGION" --format 'value(status.url)')
                print_success "$service deployed successfully"
                print_info "URL: $API_GATEWAY_URL"
            else
                print_error "Failed to deploy $service"
            fi
            ;;
            
        "product-service")
            gcloud run deploy product-service \
                --image "$IMAGE_NAME" \
                --platform managed \
                --region "$REGION" \
                --allow-unauthenticated \
                --port 8080 \
                --memory 512Mi \
                --set-env-vars="SPRING_DATA_MONGODB_URI=$MONGODB_URI" \
                --set-env-vars="SPRING_PROFILES_ACTIVE=prod" \
                --quiet
            
            if [ $? -eq 0 ]; then
                PRODUCT_SERVICE_URL=$(gcloud run services describe product-service --region "$REGION" --format 'value(status.url)')
                print_success "$service deployed successfully"
                print_info "URL: $PRODUCT_SERVICE_URL"
            else
                print_error "Failed to deploy $service"
            fi
            ;;
            
        "order-service")
            # Get inventory service URL (will be set after deployment)
            INVENTORY_SERVICE_URL="http://inventory-service-url"  # Will be updated
            
            gcloud run deploy order-service \
                --image "$IMAGE_NAME" \
                --platform managed \
                --region "$REGION" \
                --allow-unauthenticated \
                --port 8081 \
                --memory 512Mi \
                --set-env-vars="SPRING_DATASOURCE_URL=jdbc:mysql://$MYSQL_HOST:$MYSQL_PORT/order_service" \
                --set-env-vars="SPRING_DATASOURCE_USERNAME=root" \
                --set-env-vars="SPRING_DATASOURCE_PASSWORD=$MYSQL_PASSWORD" \
                --set-env-vars="SPRING_PROFILES_ACTIVE=prod" \
                --quiet
            
            if [ $? -eq 0 ]; then
                ORDER_SERVICE_URL=$(gcloud run services describe order-service --region "$REGION" --format 'value(status.url)')
                print_success "$service deployed successfully"
                print_info "URL: $ORDER_SERVICE_URL"
            else
                print_error "Failed to deploy $service"
            fi
            ;;
            
        "inventory-service")
            gcloud run deploy inventory-service \
                --image "$IMAGE_NAME" \
                --platform managed \
                --region "$REGION" \
                --allow-unauthenticated \
                --port 8082 \
                --memory 512Mi \
                --set-env-vars="SPRING_DATASOURCE_URL=jdbc:mysql://$MYSQL_HOST:$MYSQL_PORT/inventory_service" \
                --set-env-vars="SPRING_DATASOURCE_USERNAME=root" \
                --set-env-vars="SPRING_DATASOURCE_PASSWORD=$MYSQL_PASSWORD" \
                --set-env-vars="SPRING_PROFILES_ACTIVE=prod" \
                --quiet
            
            if [ $? -eq 0 ]; then
                INVENTORY_SERVICE_URL=$(gcloud run services describe inventory-service --region "$REGION" --format 'value(status.url)')
                print_success "$service deployed successfully"
                print_info "URL: $INVENTORY_SERVICE_URL"
                
                # Update order-service with inventory URL
                print_info "Updating order-service with inventory-service URL..."
                gcloud run services update order-service \
                    --update-env-vars="INVENTORY_SERVICE_URL=$INVENTORY_SERVICE_URL" \
                    --region "$REGION" \
                    --quiet
            else
                print_error "Failed to deploy $service"
            fi
            ;;
    esac
    
    echo ""
done

# Update API Gateway with service URLs
print_info "Updating API Gateway with service URLs..."

PRODUCT_SERVICE_URL=$(gcloud run services describe product-service --region "$REGION" --format 'value(status.url)' 2>/dev/null || echo "")
ORDER_SERVICE_URL=$(gcloud run services describe order-service --region "$REGION" --format 'value(status.url)' 2>/dev/null || echo "")
INVENTORY_SERVICE_URL=$(gcloud run services describe inventory-service --region "$REGION" --format 'value(status.url)' 2>/dev/null || echo "")

if [ -n "$PRODUCT_SERVICE_URL" ] && [ -n "$ORDER_SERVICE_URL" ] && [ -n "$INVENTORY_SERVICE_URL" ]; then
    gcloud run services update api-gateway \
        --update-env-vars="PRODUCT_SERVICE_URL=$PRODUCT_SERVICE_URL" \
        --update-env-vars="ORDER_SERVICE_URL=$ORDER_SERVICE_URL" \
        --update-env-vars="INVENTORY_SERVICE_URL=$INVENTORY_SERVICE_URL" \
        --region "$REGION" \
        --quiet
    
    print_success "API Gateway updated with service URLs"
else
    print_warning "Could not retrieve all service URLs. Please update API Gateway manually."
fi

echo ""
print_success "=========================================="
print_success "Deployment Complete!"
print_success "=========================================="
echo ""
print_info "Service URLs:"
gcloud run services list --region "$REGION" --format="table(SERVICE,URL)" 2>/dev/null || echo "Run: gcloud run services list --region $REGION"
echo ""
print_info "Test your deployment:"
API_GATEWAY_URL=$(gcloud run services describe api-gateway --region "$REGION" --format 'value(status.url)' 2>/dev/null || echo "N/A")
echo "  curl $API_GATEWAY_URL/actuator/health"
echo ""

