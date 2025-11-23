# Quick Fix - API Gateway Security Update

## Problem
The API Gateway is requiring authentication for `/api/product` endpoint, but we want GET requests to be public.

## Solution
I've updated the security configuration. Now you need to **restart the API Gateway**:

### Option 1: Restart using the run script
```bash
./run-application.sh stop
./run-application.sh start
```

### Option 2: Restart just the API Gateway
1. Find the API Gateway process:
   ```bash
   ps aux | grep api-gateway
   ```

2. Kill it:
   ```bash
   kill <PID>
   ```

3. Rebuild and restart:
   ```bash
   cd api-gateway
   mvn clean package -DskipTests
   java -jar target/api-gateway-0.0.1-SNAPSHOT.jar
   ```

## What Changed
- ✅ `/api/product` GET requests are now public (no login required)
- ✅ `/api/inventory` is now public
- ✅ CORS configured for `http://localhost:4200`
- ✅ POST to `/api/product` still requires authentication (for adding products)

## After Restart
1. Refresh your browser (hard refresh: Ctrl+Shift+R)
2. Products should load automatically
3. You can login to add products
4. New products will appear in the list

