# Step-by-Step GCP Deployment Guide

## ✅ Prerequisites Check

Your Docker images are already on Docker Hub:
- ✅ chauhankumarashu/api-gateway:latest
- ✅ chauhankumarashu/product-service:latest
- ✅ chauhankumarashu/order-service:latest
- ✅ chauhankumarashu/inventory-service:latest

---

## Step 1: Install Google Cloud SDK

### 1.1 Install gcloud CLI

**macOS:**
```bash
# Download and install
curl https://sdk.cloud.google.com | bash

# Restart your shell or run:
exec -l $SHELL

# Initialize
gcloud init
```

**Or use Homebrew:**
```bash
brew install --cask google-cloud-sdk
gcloud init
```

**Verify installation:**
```bash
gcloud --version
```

---

## Step 2: Set Up GCP Project

### 2.1 Login to Google Cloud

```bash
gcloud auth login
```

This will open a browser window. Sign in with your Google account.

### 2.2 Create or Select a Project

```bash
# Option A: Create a new project
gcloud projects create microservices-project-$(date +%s) --name="Microservices Project"

# Option B: Use existing project
gcloud projects list
gcloud config set project YOUR_PROJECT_ID
```

**Set the project:**
```bash
# Replace with your actual project ID
gcloud config set project microservices-project-XXXXX
```

### 2.3 Enable Billing

**Important:** Cloud Run requires billing to be enabled.

1. Go to: https://console.cloud.google.com/billing
2. Link a billing account to your project
3. Or use the free trial ($300 credit for 90 days)

### 2.4 Enable Required APIs

```bash
# Enable Cloud Run API
gcloud services enable run.googleapis.com

# Enable Cloud SQL API (for managed databases)
gcloud services enable sqladmin.googleapis.com

# Enable Cloud Build API (optional)
gcloud services enable cloudbuild.googleapis.com

# Verify APIs are enabled
gcloud services list --enabled
```

---

## Step 3: Set Up Databases

You have two options:

### Option A: Use Cloud SQL (Recommended for Production)

#### 3.1 Create MySQL Instance

```bash
# Create MySQL instance (takes 5-10 minutes)
gcloud sql instances create microservices-mysql \
  --database-version=MYSQL_8_0 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --root-password=mysql \
  --storage-type=SSD \
  --storage-size=20GB \
  --storage-auto-increase
```

**Note:** `db-f1-micro` is the smallest/cheapest tier (~$7/month). For production, consider `db-n1-standard-1`.

#### 3.2 Create Databases

```bash
# Create databases
gcloud sql databases create order_service --instance=microservices-mysql
gcloud sql databases create inventory_service --instance=microservices-mysql
gcloud sql databases create keycloak --instance=microservices-mysql

# Verify
gcloud sql databases list --instance=microservices-mysql
```

#### 3.3 Get MySQL Connection Details

```bash
# Get the connection name (you'll need this)
gcloud sql instances describe microservices-mysql --format="value(connectionName)"

# Get the public IP
gcloud sql instances describe microservices-mysql --format="value(ipAddresses[0].ipAddress)"
```

**Save these values:**
- Connection Name: `microservices-project-XXXXX:us-central1:microservices-mysql`
- Public IP: `XX.XX.XX.XX`
- Root Password: `mysql` (or what you set)

#### 3.4 Set Up MongoDB

Cloud SQL doesn't support MongoDB. Options:

**Option 1: MongoDB Atlas (Easiest - Free tier available)**
1. Sign up at https://www.mongodb.com/cloud/atlas
2. Create a free cluster
3. Get connection string (looks like: `mongodb+srv://user:pass@cluster.mongodb.net/product-service`)

**Option 2: Deploy MongoDB on Compute Engine**
```bash
# Create a small VM
gcloud compute instances create mongodb-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=cos-stable \
  --image-project=cos-cloud \
  --boot-disk-size=20GB

# SSH and install MongoDB
gcloud compute ssh mongodb-vm --zone=us-central1-a
# Then install MongoDB on the VM
```

**For now, let's use MongoDB Atlas (recommended).**

---

## Step 4: Deploy Microservices to Cloud Run

### 4.1 Quick Deploy (Automated Script)

```bash
# Run the deployment script
./deploy-to-gcp.sh chauhankumarashu us-central1 latest
```

The script will:
1. Ask for MySQL connection details
2. Ask for MongoDB URI
3. Deploy all 4 services
4. Configure service URLs automatically

**When prompted, enter:**
- MySQL Host: The public IP from Step 3.3
- MySQL Port: `3306`
- MySQL Root Password: `mysql` (or your password)
- MongoDB URI: Your MongoDB Atlas connection string

### 4.2 Manual Deploy (If you prefer step-by-step)

#### Deploy API Gateway

```bash
gcloud run deploy api-gateway \
  --image chauhankumarashu/api-gateway:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 9000 \
  --memory 512Mi \
  --cpu 1 \
  --set-env-vars="SPRING_DATASOURCE_URL=jdbc:mysql://<MYSQL_IP>:3306/order_service" \
  --set-env-vars="SPRING_DATASOURCE_USERNAME=root" \
  --set-env-vars="SPRING_DATASOURCE_PASSWORD=mysql" \
  --set-env-vars="SPRING_DATA_MONGODB_URI=<YOUR_MONGODB_URI>" \
  --set-env-vars="SPRING_PROFILES_ACTIVE=prod"
```

#### Deploy Product Service

```bash
gcloud run deploy product-service \
  --image chauhankumarashu/product-service:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --set-env-vars="SPRING_DATA_MONGODB_URI=<YOUR_MONGODB_URI>" \
  --set-env-vars="SPRING_PROFILES_ACTIVE=prod"
```

#### Deploy Inventory Service

```bash
gcloud run deploy inventory-service \
  --image chauhankumarashu/inventory-service:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8082 \
  --memory 512Mi \
  --set-env-vars="SPRING_DATASOURCE_URL=jdbc:mysql://<MYSQL_IP>:3306/inventory_service" \
  --set-env-vars="SPRING_DATASOURCE_USERNAME=root" \
  --set-env-vars="SPRING_DATASOURCE_PASSWORD=mysql" \
  --set-env-vars="SPRING_PROFILES_ACTIVE=prod"
```

#### Deploy Order Service

```bash
# First, get inventory-service URL
INVENTORY_URL=$(gcloud run services describe inventory-service --region us-central1 --format 'value(status.url)')

gcloud run deploy order-service \
  --image chauhankumarashu/order-service:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8081 \
  --memory 512Mi \
  --set-env-vars="SPRING_DATASOURCE_URL=jdbc:mysql://<MYSQL_IP>:3306/order_service" \
  --set-env-vars="SPRING_DATASOURCE_USERNAME=root" \
  --set-env-vars="SPRING_DATASOURCE_PASSWORD=mysql" \
  --set-env-vars="INVENTORY_SERVICE_URL=$INVENTORY_URL" \
  --set-env-vars="SPRING_PROFILES_ACTIVE=prod"
```

#### Update API Gateway with Service URLs

```bash
# Get all service URLs
PRODUCT_URL=$(gcloud run services describe product-service --region us-central1 --format 'value(status.url)')
ORDER_URL=$(gcloud run services describe order-service --region us-central1 --format 'value(status.url)')
INVENTORY_URL=$(gcloud run services describe inventory-service --region us-central1 --format 'value(status.url)')

# Update API Gateway
gcloud run services update api-gateway \
  --update-env-vars="PRODUCT_SERVICE_URL=$PRODUCT_URL" \
  --update-env-vars="ORDER_SERVICE_URL=$ORDER_URL" \
  --update-env-vars="INVENTORY_SERVICE_URL=$INVENTORY_URL" \
  --region us-central1
```

---

## Step 5: Configure Database Access

### 5.1 Allow Cloud Run to Access Cloud SQL

```bash
# Get your project number
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)")

# Get Cloud SQL connection name
CONNECTION_NAME=$(gcloud sql instances describe microservices-mysql --format="value(connectionName)")

# Add Cloud SQL connection to each service
gcloud run services update api-gateway \
  --add-cloudsql-instances=$CONNECTION_NAME \
  --region us-central1

gcloud run services update order-service \
  --add-cloudsql-instances=$CONNECTION_NAME \
  --region us-central1

gcloud run services update inventory-service \
  --add-cloudsql-instances=$CONNECTION_NAME \
  --region us-central1
```

### 5.2 Update Connection Strings

After adding Cloud SQL connection, update the connection strings to use Unix socket:

```bash
# Update to use Unix socket instead of IP
gcloud run services update api-gateway \
  --update-env-vars="SPRING_DATASOURCE_URL=jdbc:mysql:///order_service?cloudSqlInstance=$CONNECTION_NAME&socketFactory=com.google.cloud.sql.mysql.SocketFactory" \
  --region us-central1
```

**Note:** You'll need to add the Cloud SQL Socket Factory dependency to your services for this to work.

**For now, using the public IP is simpler (but less secure).**

---

## Step 6: Verify Deployment

### 6.1 List All Services

```bash
gcloud run services list --region us-central1
```

### 6.2 Get Service URLs

```bash
# Get API Gateway URL
gcloud run services describe api-gateway --region us-central1 --format 'value(status.url)'

# Test health endpoint
API_URL=$(gcloud run services describe api-gateway --region us-central1 --format 'value(status.url)')
curl $API_URL/actuator/health
```

### 6.3 Check Logs

```bash
# View logs for a service
gcloud run services logs read api-gateway --region us-central1 --limit 50

# Follow logs in real-time
gcloud run services logs tail api-gateway --region us-central1
```

### 6.4 Test API Endpoints

```bash
# Get API Gateway URL
API_URL=$(gcloud run services describe api-gateway --region us-central1 --format 'value(status.url)')

# Test health
curl $API_URL/actuator/health

# Test products endpoint
curl $API_URL/product-service/api/products

# Test Swagger UI
open $API_URL/swagger-ui.html
```

---

## Step 7: Set Up Monitoring (Optional)

### 7.1 Deploy Prometheus

```bash
gcloud run deploy prometheus \
  --image prom/prometheus:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 9090 \
  --memory 1Gi \
  --set-env-vars="PROMETHEUS_CONFIG_PATH=/etc/prometheus/prometheus.yml"
```

### 7.2 Deploy Grafana

```bash
gcloud run deploy grafana \
  --image grafana/grafana:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 3000 \
  --memory 512Mi \
  --set-env-vars="GF_SECURITY_ADMIN_USER=admin" \
  --set-env-vars="GF_SECURITY_ADMIN_PASSWORD=admin"
```

---

## Step 8: Common Commands

### View Services
```bash
gcloud run services list --region us-central1
```

### View Service Details
```bash
gcloud run services describe api-gateway --region us-central1
```

### View Logs
```bash
gcloud run services logs read api-gateway --region us-central1
```

### Update Service
```bash
gcloud run services update api-gateway \
  --image chauhankumarashu/api-gateway:1.0.1 \
  --region us-central1
```

### Delete Service
```bash
gcloud run services delete api-gateway --region us-central1
```

### Scale Service
```bash
gcloud run services update api-gateway \
  --min-instances 1 \
  --max-instances 10 \
  --region us-central1
```

---

## Troubleshooting

### Services Not Starting

```bash
# Check logs
gcloud run services logs read api-gateway --region us-central1

# Check service status
gcloud run services describe api-gateway --region us-central1
```

### Database Connection Issues

1. Verify Cloud SQL instance is running:
   ```bash
   gcloud sql instances describe microservices-mysql
   ```

2. Check firewall rules (Cloud SQL should allow connections from Cloud Run)

3. Verify connection string format

4. Check database credentials

### Image Pull Errors

```bash
# Verify image exists
docker pull chauhankumarashu/api-gateway:latest

# Re-push if needed
./build-and-push.sh 1.0.0 chauhankumarashu
```

### Permission Errors

```bash
# Make sure you have the right permissions
gcloud projects get-iam-policy $(gcloud config get-value project)

# Add yourself as owner (if needed)
gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member="user:YOUR_EMAIL@gmail.com" \
  --role="roles/owner"
```

---

## Cost Estimation

**Cloud Run:**
- Free tier: 2 million requests/month
- After free tier: ~$0.40 per million requests
- Memory/CPU: ~$0.0000025 per GB-second

**Cloud SQL:**
- db-f1-micro: ~$7/month
- db-n1-standard-1: ~$25/month

**Estimated Monthly Cost (Small Scale):**
- 4 Cloud Run services: $0-20/month (depending on traffic)
- Cloud SQL: $7-25/month
- **Total: ~$10-50/month**

---

## Next Steps

1. ✅ Set up custom domain
2. ✅ Configure SSL certificates
3. ✅ Set up CI/CD pipeline
4. ✅ Configure monitoring alerts
5. ✅ Set up database backups
6. ✅ Implement auto-scaling

---

## Quick Reference

**Your Docker Hub Images:**
- chauhankumarashu/api-gateway:latest
- chauhankumarashu/product-service:latest
- chauhankumarashu/order-service:latest
- chauhankumarashu/inventory-service:latest

**Deployment Command:**
```bash
./deploy-to-gcp.sh chauhankumarashu us-central1 latest
```

**View Services:**
```bash
gcloud run services list --region us-central1
```

