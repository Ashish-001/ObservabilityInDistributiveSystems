# Spring Boot Microservices Project

A comprehensive microservices application built with Spring Boot 3, featuring Product, Order, and Inventory services with full observability, containerization, and cloud deployment capabilities.

## 📋 Table of Contents

- [Services Overview](#services-overview)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [Local Testing](#local-testing)
- [Docker Deployment](#docker-deployment)
- [API Documentation](#api-documentation)
- [Monitoring & Observability](#monitoring--observability)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Common Tasks](#common-tasks)

## 🏗️ Services Overview

- **Product Service** - Manages product information (MongoDB)
- **Order Service** - Handles order processing (MySQL)
- **Inventory Service** - Manages inventory and stock checks (MySQL)
- **API Gateway** - Single entry point using Spring Cloud Gateway MVC

## 🛠️ Tech Stack

- **Framework**: Spring Boot 3, Spring Cloud Gateway MVC
- **Databases**: MongoDB (Product Service), MySQL (Order & Inventory Services)
- **Documentation**: SpringDoc OpenAPI 3 (Swagger/OpenAPI)
- **Resilience**: Resilience4j (Circuit Breaker)
- **Observability**: 
  - Micrometer & Prometheus (Metrics)
  - Zipkin (Distributed Tracing)
  - Loki (Log Aggregation)
  - Grafana (Visualization)
- **Security**: Keycloak (OAuth2/OIDC)
- **Containerization**: Docker, Docker Compose

## 🚀 Quick Start

### Prerequisites

- Java 21
- Maven 3.9+
- Docker & Docker Compose

### Start Everything

```bash
# One command to start everything (builds images if needed)
./test-locally.sh start
```

That's it! All services will start automatically.

### Other Commands

```bash
./test-locally.sh build    # Build Docker images
./test-locally.sh stop     # Stop all services
./test-locally.sh logs     # View logs
./test-locally.sh health   # Check service health
```

### Option 3: Run Services Without Docker (Java directly)

```bash
# Start infrastructure (databases, monitoring)
docker-compose up -d mysql mongodb prometheus grafana zipkin loki keycloak

# Build services
mvn clean install -DskipTests

# Run services manually
java -jar api-gateway/target/api-gateway-*.jar &
java -jar product-service/target/product-service-*.jar &
java -jar order-service/target/order-service-*.jar &
java -jar inventory-service/target/inventory-service-*.jar &
```

## 🧪 Local Testing

### Main Commands

```bash
# Start everything (builds images if needed)
./test-locally.sh start

# Check health
./test-locally.sh health
# Or use dedicated health check script
./check-health.sh

# View logs
./test-locally.sh logs              # All services
./test-locally.sh logs api-gateway  # Specific service

# Stop services
./test-locally.sh stop

# Clean up everything
./test-locally.sh clean
```

### If Ports Are In Use

```bash
# Free up ports (stops local Java processes)
./stop-local-services.sh

# Then start
./test-locally.sh start
```

### Service URLs (Local)

- **API Gateway**: http://localhost:9000
- **Product Service**: http://localhost:8080
- **Order Service**: http://localhost:8081
- **Inventory Service**: http://localhost:8082
- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090
- **Zipkin**: http://localhost:9411
- **Keycloak**: http://localhost:8181
- **Swagger UI**: http://localhost:9000/swagger-ui.html

## 🐳 Docker Deployment

### Build Images

```bash
# Build all services locally
./test-locally.sh build

# Or push to Docker Hub
./build-and-push.sh 1.0.0 chauhankumarashu
```

### Run with Docker Compose

```bash
# Start all services
./test-locally.sh start

# Or manually
docker-compose up -d
```


## 📚 API Documentation

### Swagger UI

Access unified Swagger UI via API Gateway:
- **URL**: http://localhost:9000/swagger-ui.html

Features:
- ✅ Unified view of all services
- ✅ Service-specific views
- ✅ Interactive API testing
- ✅ Request/response examples

### API Endpoints

#### Product Service

```bash
# Get all products
GET http://localhost:8080/api/products

# Get product by ID
GET http://localhost:8080/api/products/{id}

# Create product
POST http://localhost:8080/api/products
Content-Type: application/json

{
  "name": "iPhone 15 Pro",
  "description": "Latest iPhone",
  "skuCode": "IPHONE-15-PRO-256",
  "price": 999.99
}
```

#### Order Service

```bash
# Create order
POST http://localhost:8081/api/orders
Content-Type: application/json

{
  "orderLineItemsDtoList": [
    {
      "skuCode": "SKU001",
      "price": 100.00,
      "quantity": 2
    }
  ]
}
```

#### Inventory Service

```bash
# Check inventory
GET http://localhost:8082/api/inventory?skuCode=SKU001&quantity=2
```

### API Gateway Routes

All services are accessible through the gateway:
- `/product-service/api/*` → Product Service
- `/order-service/api/*` → Order Service
- `/inventory-service/api/*` → Inventory Service

## 📊 Monitoring & Observability

### Prometheus

- **URL**: http://localhost:9090
- **Metrics Path**: `/actuator/prometheus` on each service
- Automatically scrapes all microservices

### Grafana

- **URL**: http://localhost:3000
- Pre-configured dashboards:
  - Spring Boot Statistics
  - Spring Actuator Metrics
- Data source: Prometheus

### Zipkin

- **URL**: http://localhost:9411
- View distributed traces across services
- Track request flow through microservices

### Loki

- Log aggregation from all services
- Integrated with Grafana for log visualization

## 📁 Project Structure

```
microservices-project/
├── api-gateway/
│   ├── Dockerfile
│   └── src/
├── product-service/
│   ├── Dockerfile
│   └── src/
├── order-service/
│   ├── Dockerfile
│   └── src/
├── inventory-service/
│   ├── Dockerfile
│   └── src/
├── docker/
│   ├── grafana/
│   ├── prometheus/
│   ├── tempo/
│   └── keycloak/
├── docker-compose.yml            # Docker Compose configuration
├── test-locally.sh              # ⭐ Main script: build, start, stop, logs
├── check-health.sh              # Check health of all API endpoints
├── build-and-push.sh            # Push images to Docker Hub
├── deploy-to-gcp.sh             # Deploy to GCP Cloud Run (automated)
├── docker-compose.gcp.yml       # Docker Compose config for GCP VM
├── stop-local-services.sh       # Helper: free up ports
└── README.md                    # This file
```

## 🔧 Troubleshooting

### Port Already in Use

```bash
# Check what's using the port
lsof -i :8080

# Stop local services
./stop-local-services.sh

# Or kill specific process
kill <PID>
```

### Services Not Starting

```bash
# Check Docker logs
docker-compose logs api-gateway

# Check if databases are ready
docker-compose ps mysql mongodb

# Restart services
docker-compose restart
```

### Database Connection Issues

```bash
# Check database containers
docker-compose logs mysql
docker-compose logs mongodb

# Verify connection
docker-compose exec mysql mysql -uroot -pmysql -e "SHOW DATABASES;"
```

### Images Not Found

```bash
# Build locally
./test-locally.sh build

# Use local images
docker-compose -f docker-compose.local.yml up -d
```

### Docker Compose Issues

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs api-gateway

# Restart a service
docker-compose restart api-gateway

# Rebuild and restart
docker-compose up -d --build api-gateway
```

### Health Checks Failing

```bash
# Wait for services to start (30-60 seconds)
sleep 30

# Check health endpoints
curl http://localhost:9000/actuator/health

# Check logs for errors
docker-compose logs | grep -i error
```

## 🔐 Configuration

### Environment Variables

Services can be configured via environment variables:

- `SPRING_DATASOURCE_URL` - MySQL connection URL
- `SPRING_DATA_MONGODB_URI` - MongoDB connection URL
- `SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI` - Keycloak issuer
- `MANAGEMENT_ZIPKIN_TRACING_ENDPOINT` - Zipkin endpoint
- `LOKI_URL` - Loki logging endpoint

### Service Ports

- API Gateway: 9000
- Product Service: 8080
- Order Service: 8081
- Inventory Service: 8082

## 📝 Common Tasks

### Update and Redeploy

```bash
# 1. Build new version locally
./test-locally.sh build

# 2. Restart services
docker-compose restart api-gateway

# Or rebuild and restart
docker-compose up -d --build api-gateway
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api-gateway
```

### Scale Services

```bash
# Scale a service (edit docker-compose.yml or use)
docker-compose up -d --scale product-service=3
```

## ☁️ GCP Deployment Guide

This guide walks you through deploying your microservices to Google Cloud Platform using Docker Hub images.

### Quick Deploy (Automated)

```bash
# 1. Push images to Docker Hub
./build-and-push.sh 1.0.0 chauhankumarashu

# 2. Deploy to GCP Cloud Run (interactive script)
./deploy-to-gcp.sh chauhankumarashu us-central1 latest
```

The deployment script will:
- Prompt for database connection details
- Deploy all 4 microservices to Cloud Run
- Configure service URLs automatically
- Display all service endpoints

**For detailed manual steps, see below.**

### Prerequisites

- Google Cloud account with billing enabled
- Docker Hub account
- `gcloud` CLI installed ([Install Guide](https://cloud.google.com/sdk/docs/install))
- Docker installed and running locally

### Step 1: Push Images to Docker Hub

#### 1.1 Login to Docker Hub

```bash
docker login
# Enter your Docker Hub username and password
```

#### 1.2 Build and Push All Images

```bash
# Build and push all services with version tag
./build-and-push.sh 1.0.0 chauhankumarashu

# Replace 'chauhankumarashu' with your Docker Hub username
# Replace '1.0.0' with your desired version
```

This will:
- Build all 4 microservices (api-gateway, product-service, order-service, inventory-service)
- Tag them with version and `latest`
- Push to Docker Hub: `chauhankumarashu/<service-name>:1.0.0` and `:latest`

**Expected Output:**
```
[INFO] Building api-gateway...
[SUCCESS] api-gateway built successfully
[INFO] Pushing api-gateway to Docker Hub...
[SUCCESS] api-gateway pushed to Docker Hub
...
```

#### 1.3 Verify Images on Docker Hub

Visit https://hub.docker.com/r/chauhankumarashu/ and verify all 4 images are present.

---

### Step 2: Set Up GCP Project

#### 2.1 Create GCP Project

```bash
# Login to GCP
gcloud auth login

# Create a new project (or use existing)
gcloud projects create microservices-project --name="Microservices Project"

# Set as active project
gcloud config set project microservices-project

# Enable billing (required for Cloud Run and Cloud SQL)
# Do this via Console: https://console.cloud.google.com/billing
```

#### 2.2 Enable Required APIs

```bash
# Enable Cloud Run API
gcloud services enable run.googleapis.com

# Enable Cloud SQL API (for managed databases)
gcloud services enable sqladmin.googleapis.com

# Enable Cloud Build API (optional, for CI/CD)
gcloud services enable cloudbuild.googleapis.com

# Enable Container Registry API (if using GCR instead of Docker Hub)
gcloud services enable containerregistry.googleapis.com
```

---

### Step 3: Deploy Infrastructure (Databases)

#### Option A: Use Cloud SQL (Recommended for Production)

##### 3.1 Create MySQL Instance

```bash
# Create MySQL instance
gcloud sql instances create microservices-mysql \
  --database-version=MYSQL_8_0 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --root-password=mysql \
  --storage-type=SSD \
  --storage-size=20GB

# Create databases
gcloud sql databases create order_service --instance=microservices-mysql
gcloud sql databases create inventory_service --instance=microservices-mysql
gcloud sql databases create keycloak --instance=microservices-mysql
```

##### 3.2 Create MongoDB (Cloud SQL doesn't support MongoDB)

For MongoDB, you have two options:

**Option 1: Use MongoDB Atlas (Recommended)**
- Sign up at https://www.mongodb.com/cloud/atlas
- Create a free cluster
- Get connection string

**Option 2: Deploy MongoDB on Compute Engine**
```bash
# Create VM instance
gcloud compute instances create mongodb-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=cos-stable \
  --image-project=cos-cloud

# SSH and install MongoDB
gcloud compute ssh mongodb-vm --zone=us-central1-a
# Then install MongoDB on the VM
```

#### Option B: Use Docker Compose on Compute Engine (Simpler Setup)

Deploy all infrastructure using Docker Compose on a VM:

```bash
# Create VM with Docker pre-installed
gcloud compute instances create microservices-vm \
  --zone=us-central1-a \
  --machine-type=e2-standard-4 \
  --image-family=cos-stable \
  --image-project=cos-cloud \
  --boot-disk-size=50GB \
  --tags=http-server,https-server

# Allow HTTP/HTTPS traffic
gcloud compute firewall-rules create allow-http-https \
  --allow tcp:80,tcp:443,tcp:9000,tcp:8080,tcp:8081,tcp:8082,tcp:3000,tcp:9090,tcp:9411 \
  --source-ranges 0.0.0.0/0 \
  --target-tags http-server,https-server
```

---

### Step 4: Deploy Microservices

#### Option A: Deploy to Cloud Run (Serverless - Recommended)

Cloud Run is perfect for microservices - auto-scaling, pay-per-use, no server management.

##### 4.1 Deploy API Gateway

```bash
gcloud run deploy api-gateway \
  --image chauhankumarashu/api-gateway:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 9000 \
  --memory 512Mi \
  --cpu 1 \
  --set-env-vars="SPRING_PROFILES_ACTIVE=prod" \
  --set-env-vars="SPRING_DATASOURCE_URL=jdbc:mysql://<mysql-ip>:3306/order_service" \
  --set-env-vars="SPRING_DATA_MONGODB_URI=mongodb://<mongodb-ip>:27017/product-service"
```

##### 4.2 Deploy Product Service

```bash
gcloud run deploy product-service \
  --image chauhankumarashu/product-service:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --set-env-vars="SPRING_DATA_MONGODB_URI=mongodb://<mongodb-ip>:27017/product-service"
```

##### 4.3 Deploy Order Service

```bash
gcloud run deploy order-service \
  --image chauhankumarashu/order-service:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8081 \
  --memory 512Mi \
  --set-env-vars="SPRING_DATASOURCE_URL=jdbc:mysql://<mysql-ip>:3306/order_service" \
  --set-env-vars="SPRING_DATASOURCE_USERNAME=root" \
  --set-env-vars="SPRING_DATASOURCE_PASSWORD=mysql" \
  --set-env-vars="INVENTORY_SERVICE_URL=http://inventory-service-url"
```

##### 4.4 Deploy Inventory Service

```bash
gcloud run deploy inventory-service \
  --image chauhankumarashu/inventory-service:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8082 \
  --memory 512Mi \
  --set-env-vars="SPRING_DATASOURCE_URL=jdbc:mysql://<mysql-ip>:3306/inventory_service" \
  --set-env-vars="SPRING_DATASOURCE_USERNAME=root" \
  --set-env-vars="SPRING_DATASOURCE_PASSWORD=mysql"
```

**Get Service URLs:**
```bash
# Get all service URLs
gcloud run services list --region us-central1
```

#### Option B: Deploy on Compute Engine with Docker Compose

##### 4.1 SSH to VM

```bash
gcloud compute ssh microservices-vm --zone=us-central1-a
```

##### 4.2 Install Docker Compose

```bash
# On the VM
sudo apt-get update
sudo apt-get install -y docker-compose
```

##### 4.3 Create docker-compose.yml for GCP

Create a `docker-compose.gcp.yml` file on the VM:

```yaml
version: '4'
services:
  mongodb:
    image: mongo:7.0.5
    # ... (same as local)
  
  mysql:
    image: mysql:8.3.0
    # ... (same as local)
  
  api-gateway:
    image: chauhankumarashu/api-gateway:latest
    ports:
      - "9000:9000"
    # ... (same as local)
  
  product-service:
    image: chauhankumarashu/product-service:latest
    # ... (same as local)
  
  order-service:
    image: chauhankumarashu/order-service:latest
    # ... (same as local)
  
  inventory-service:
    image: chauhankumarashu/inventory-service:latest
    # ... (same as local)
```

##### 4.4 Start Services

```bash
docker-compose -f docker-compose.gcp.yml up -d
```

---

### Step 5: Configure Networking

#### 5.1 Update Service URLs

After deployment, update environment variables with actual service URLs:

```bash
# Get Cloud Run service URLs
API_GATEWAY_URL=$(gcloud run services describe api-gateway --region us-central1 --format 'value(status.url)')
PRODUCT_SERVICE_URL=$(gcloud run services describe product-service --region us-central1 --format 'value(status.url)')
ORDER_SERVICE_URL=$(gcloud run services describe order-service --region us-central1 --format 'value(status.url)')
INVENTORY_SERVICE_URL=$(gcloud run services describe inventory-service --region us-central1 --format 'value(status.url)')

# Update API Gateway with service URLs
gcloud run services update api-gateway \
  --update-env-vars="PRODUCT_SERVICE_URL=$PRODUCT_SERVICE_URL" \
  --update-env-vars="ORDER_SERVICE_URL=$ORDER_SERVICE_URL" \
  --update-env-vars="INVENTORY_SERVICE_URL=$INVENTORY_SERVICE_URL"
```

#### 5.2 Set Up VPC Connector (for Cloud SQL)

```bash
# Create VPC connector
gcloud compute networks vpc-access connectors create microservices-connector \
  --region=us-central1 \
  --subnet=default \
  --min-instances=2 \
  --max-instances=3

# Update services to use VPC connector
gcloud run services update api-gateway \
  --vpc-connector=microservices-connector \
  --vpc-egress=all-traffic
```

---

### Step 6: Deploy Monitoring (Optional)

#### 6.1 Deploy Prometheus

```bash
gcloud run deploy prometheus \
  --image prom/prometheus:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 9090 \
  --memory 1Gi
```

#### 6.2 Deploy Grafana

```bash
gcloud run deploy grafana \
  --image grafana/grafana:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 3000 \
  --memory 512Mi
```

---

### Step 7: Verify Deployment

#### 7.1 Check Service Status

```bash
# List all Cloud Run services
gcloud run services list --region us-central1

# Check logs
gcloud run services logs read api-gateway --region us-central1
```

#### 7.2 Test Endpoints

```bash
# Get API Gateway URL
API_URL=$(gcloud run services describe api-gateway --region us-central1 --format 'value(status.url)')

# Test health endpoint
curl $API_URL/actuator/health

# Test API
curl $API_URL/product-service/api/products
```

---

### Step 8: Set Up Custom Domain (Optional)

```bash
# Map custom domain to Cloud Run service
gcloud run domain-mappings create \
  --service api-gateway \
  --domain api.yourdomain.com \
  --region us-central1
```

---

### Quick Reference Commands

```bash
# View all services
gcloud run services list

# View service details
gcloud run services describe api-gateway --region us-central1

# View logs
gcloud run services logs read api-gateway --region us-central1 --limit 50

# Update service
gcloud run services update api-gateway \
  --image chauhankumarashu/api-gateway:1.0.1 \
  --region us-central1

# Delete service
gcloud run services delete api-gateway --region us-central1
```

---

### Cost Estimation

**Cloud Run (Pay-per-use):**
- Free tier: 2 million requests/month
- After free tier: ~$0.40 per million requests
- Memory/CPU: ~$0.0000025 per GB-second

**Cloud SQL:**
- db-f1-micro: ~$7/month
- db-n1-standard-1: ~$25/month

**Estimated Monthly Cost (Small Scale):**
- 4 Cloud Run services: $0-20/month (depending on traffic)
- Cloud SQL: $7-25/month
- Total: ~$10-50/month

---

### Troubleshooting

#### Services Not Starting

```bash
# Check logs
gcloud run services logs read api-gateway --region us-central1

# Check service status
gcloud run services describe api-gateway --region us-central1
```

#### Database Connection Issues

- Verify Cloud SQL instance is running
- Check firewall rules allow connections
- Verify connection string format
- Check database credentials

#### Image Pull Errors

```bash
# Verify image exists on Docker Hub
docker pull chauhankumarashu/api-gateway:latest

# Re-push if needed
./build-and-push.sh 1.0.0 chauhankumarashu
```

---

## 🎯 Next Steps

1. **Set up CI/CD**: Automate build and deployment
2. **Configure Monitoring Alerts**: Set up Prometheus/Grafana alerts
3. **Database Backups**: Implement backup strategy
4. **Performance Tuning**: Optimize resource limits and JVM settings
5. **Set up Load Balancing**: Use Cloud Load Balancer for high availability

## 📖 Additional Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Spring Cloud Gateway](https://spring.io/projects/spring-cloud-gateway)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 🤝 Support

For issues:
- Check service logs: `docker-compose logs`
- Review troubleshooting section above

---

**Built with ❤️ using Spring Boot 3**
