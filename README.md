# Spring Boot Microservices

A microservices application built with Spring Boot 3, featuring Product, Order, and Inventory services with comprehensive API documentation.

## Services Overview

- **Product Service** - Manages product information (MongoDB)
- **Order Service** - Handles order processing (MySQL)
- **Inventory Service** - Manages inventory and stock checks (MySQL)
- **API Gateway** - Single entry point using Spring Cloud Gateway MVC

## Tech Stack

- Spring Boot 3
- Spring Cloud Gateway MVC
- MongoDB (Product Service)
- MySQL (Order & Inventory Services)
- SpringDoc OpenAPI 3 (Swagger/OpenAPI Documentation)
- Resilience4j (Circuit Breaker)
- Micrometer & Prometheus (Metrics)
- Zipkin (Distributed Tracing)
- Loki (Log Aggregation)

## API Documentation with Swagger/OpenAPI

This project includes comprehensive Swagger/OpenAPI documentation for all microservices with examples that you can test directly from the Swagger UI.

### Accessing Swagger UI

#### Via API Gateway (Recommended)
The API Gateway provides a unified Swagger UI interface that aggregates all microservices APIs:

**URL:** http://localhost:9000/swagger-ui.html

The Swagger UI provides a dropdown menu at the top where you can select between:
- **All Services (Unified)** - Combined view of all APIs from Product, Order, and Inventory services in one place
- **Product Service** - Product management APIs only
- **Order Service** - Order management APIs only
- **Inventory Service** - Inventory management APIs only

**Features:**
- ✅ **Unified View** - See all APIs from all services in a single, organized view
- ✅ **Service Tags** - Each API is tagged with its service name for easy identification
- ✅ **Interactive Testing** - Test any API directly from the Swagger UI with "Try it out"
- ✅ **Filtering & Search** - Filter and search APIs across all services
- ✅ **Request Duration** - See how long each API call takes
- ✅ **Multiple Views** - Switch between unified and individual service views

#### Individual Service Swagger UIs
You can also access each service's Swagger UI directly:

- **Product Service:** http://localhost:8080/swagger-ui.html
- **Order Service:** http://localhost:8081/swagger-ui.html
- **Inventory Service:** http://localhost:8082/swagger-ui.html

### API Documentation Endpoints

#### Via API Gateway
- **Unified API Docs (All Services):** http://localhost:9000/api-docs
- **Product Service Docs:** http://localhost:9000/aggregate/product-service/v3/api-docs
- **Order Service Docs:** http://localhost:9000/aggregate/order-service/v3/api-docs
- **Inventory Service Docs:** http://localhost:9000/aggregate/inventory-service/v3/api-docs

#### Direct Service Endpoints
- **Product Service Docs:** http://localhost:8080/api-docs
- **Order Service Docs:** http://localhost:8081/api-docs
- **Inventory Service Docs:** http://localhost:8082/api-docs

### Available APIs

#### 1. Product Service APIs

**Base URL:** `/api/product`

##### Create Product
- **Method:** `POST`
- **Endpoint:** `/api/product`
- **Description:** Creates a new product with the provided details
- **Request Body Example:**
```json
{
  "name": "iPhone 15 Pro",
  "description": "Latest iPhone with A17 Pro chip",
  "skuCode": "IPHONE-15-PRO-256",
  "price": 999.99
}
```
- **Response Example (201 Created):**
```json
{
  "id": "507f1f77bcf86cd799439011",
  "name": "iPhone 15 Pro",
  "description": "Latest iPhone with A17 Pro chip",
  "skuCode": "IPHONE-15-PRO-256",
  "price": 999.99
}
```

##### Get All Products
- **Method:** `GET`
- **Endpoint:** `/api/product`
- **Description:** Retrieves a list of all available products
- **Response Example (200 OK):**
```json
[
  {
    "id": "507f1f77bcf86cd799439011",
    "name": "iPhone 15 Pro",
    "description": "Latest iPhone with A17 Pro chip",
    "skuCode": "IPHONE-15-PRO-256",
    "price": 999.99
  },
  {
    "id": "507f1f77bcf86cd799439012",
    "name": "Samsung Galaxy S24",
    "description": "Flagship Android smartphone",
    "skuCode": "SAMSUNG-S24-256",
    "price": 899.99
  }
]
```

#### 2. Order Service APIs

**Base URL:** `/api/order`

##### Place Order
- **Method:** `POST`
- **Endpoint:** `/api/order`
- **Description:** Creates a new order for the specified product with user details
- **Request Body Example:**
```json
{
  "skuCode": "IPHONE-15-PRO-256",
  "price": 999.99,
  "quantity": 2,
  "userDetails": {
    "email": "john.doe@example.com",
    "firstName": "John",
    "lastName": "Doe"
  }
}
```
- **Response Example (201 Created):**
```
Order Placed Successfully
```
- **Error Response (400 Bad Request):**
```
Product is out of stock
```
- **Fallback Response (503 Service Unavailable):**
```
Oops! Something went wrong, please order after some time!
```

#### 3. Inventory Service APIs

**Base URL:** `/api/inventory`

##### Check Product Availability
- **Method:** `GET`
- **Endpoint:** `/api/inventory`
- **Description:** Checks if the specified product is available in the requested quantity
- **Query Parameters:**
  - `skuCode` (required): Product SKU code (e.g., "IPHONE-15-PRO-256")
  - `quantity` (required): Requested quantity (e.g., 2)
- **Example Request:**
```
GET /api/inventory?skuCode=IPHONE-15-PRO-256&quantity=2
```
- **Response Example (200 OK):**
  - `true` - Product is available in the requested quantity
  - `false` - Product is not available in the requested quantity

### Testing APIs from Swagger UI

1. **Open Swagger UI:** Navigate to http://localhost:9000/swagger-ui.html
2. **Select a View:** Use the dropdown at the top to select:
   - **"All Services (Unified)"** - To see all APIs from all services together
   - **Individual Service** - To see APIs from a specific service only
3. **Expand an API:** Click on any API endpoint to expand it
4. **View Examples:** Each API includes request/response examples
5. **Try it Out:** Click the "Try it out" button
6. **Fill Request Data:** Use the provided examples or enter your own data
7. **Execute:** Click "Execute" to send the request
8. **View Response:** See the response with status code and body

**Tip:** Use the unified view to see all available APIs at once, or switch to individual services for a focused view.

### Configuration

#### API Gateway Configuration
The API Gateway is configured in `api-gateway/src/main/resources/application.properties`:

```properties
springdoc.swagger-ui.path=/swagger-ui.html
springdoc.api-docs.path=/api-docs
springdoc.swagger-ui.operationsSorter=method
springdoc.swagger-ui.tagsSorter=alpha
springdoc.swagger-ui.tryItOutEnabled=true
springdoc.swagger-ui.filter=true
springdoc.swagger-ui.displayRequestDuration=true
# Configure multiple service APIs
springdoc.swagger-ui.urls[0].name=All Services (Unified)
springdoc.swagger-ui.urls[0].url=/api-docs
springdoc.swagger-ui.urls[1].name=Product Service
springdoc.swagger-ui.urls[1].url=/aggregate/product-service/v3/api-docs
springdoc.swagger-ui.urls[2].name=Order Service
springdoc.swagger-ui.urls[2].url=/aggregate/order-service/v3/api-docs
springdoc.swagger-ui.urls[3].name=Inventory Service
springdoc.swagger-ui.urls[3].url=/aggregate/inventory-service/v3/api-docs
```

**Unified API Aggregator:**
The API Gateway includes a `SwaggerAggregatorController` that automatically fetches and combines OpenAPI specifications from all microservices into a single unified view. This allows you to see all APIs from Product, Order, and Inventory services in one place, with each API tagged by its service name.

#### Service Ports
- **API Gateway:** 9000
- **Product Service:** 8080
- **Order Service:** 8081
- **Inventory Service:** 8082

### Troubleshooting

#### Only Seeing One Service in Swagger UI
If you only see one service (e.g., Inventory) in the Swagger UI dropdown:

1. **Check Service Status:** Ensure all services are running:
   ```bash
   # Check if services are accessible
   curl http://localhost:8080/api-docs  # Product Service
   curl http://localhost:8081/api-docs  # Order Service
   curl http://localhost:8082/api-docs  # Inventory Service
   ```

2. **Verify API Gateway Routes:** Check that the gateway can reach all services:
   ```bash
   curl http://localhost:9000/aggregate/product-service/v3/api-docs
   curl http://localhost:9000/aggregate/order-service/v3/api-docs
   curl http://localhost:9000/aggregate/inventory-service/v3/api-docs
   ```

3. **Check Service Logs:** Look for connection errors or routing issues

4. **Restart Services:** Restart all services and the API Gateway

#### APIs Not Loading
- Ensure all services are running and accessible
- Check firewall settings
- Verify the service URLs in `application.properties` are correct
- Check that the API Gateway routes are properly configured

#### CORS Issues
If you encounter CORS errors, the API Gateway's `SecurityConfig` allows all necessary endpoints. Ensure the security configuration includes:
- `/swagger-ui.html`
- `/swagger-ui/**`
- `/v3/api-docs/**`
- `/aggregate/**`
- `/api/product`, `/api/order`, `/api/inventory`

### Dependencies

All services use **SpringDoc OpenAPI 3** for Swagger documentation:

```xml
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
    <version>2.5.0</version>
</dependency>
<dependency>
    <groupId>org.springdoc</groupId>
    <artifactId>springdoc-openapi-starter-webmvc-api</artifactId>
    <version>2.5.0</version>
</dependency>
```

### Features

✅ **Comprehensive API Documentation** - All endpoints are documented with descriptions  
✅ **Unified Swagger UI** - View all APIs from all services in a single, unified interface  
✅ **Request/Response Examples** - Every API includes example data you can use  
✅ **Interactive Testing** - Test APIs directly from Swagger UI with "Try it out"  
✅ **Multiple Service Views** - Switch between unified view and individual service views  
✅ **Service Tagging** - Each API is tagged with its service name for easy identification  
✅ **Filtering & Search** - Filter and search APIs across all services  
✅ **OpenAPI 3.0 Compliant** - Standard OpenAPI specification  
✅ **Schema Documentation** - All DTOs are documented with field descriptions and examples
