# Multi-stage Dockerfile for Spring Boot Microservices
# Stage 1: Build stage
FROM maven:3.9.6-eclipse-temurin-21 AS build

WORKDIR /app

# Copy pom files first for better layer caching
COPY pom.xml .
COPY api-gateway/pom.xml ./api-gateway/
COPY product-service/pom.xml ./product-service/
COPY order-service/pom.xml ./order-service/
COPY inventory-service/pom.xml ./inventory-service/

# Download dependencies (this layer will be cached if pom.xml doesn't change)
# Skip site and javadoc plugins to avoid issues with flexmark dependencies
RUN mvn dependency:go-offline -B -Dmaven.site.skip=true -Dmaven.javadoc.skip=true

# Copy source code
COPY api-gateway/src ./api-gateway/src
COPY product-service/src ./product-service/src
COPY order-service/src ./order-service/src
COPY inventory-service/src ./inventory-service/src

# Build all services
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime stage
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Install bash and curl for startup script and health checks
RUN apk add --no-cache bash curl

# Create directories for logs and services
RUN mkdir -p /app/services /app/logs

# Copy JAR files from build stage
COPY --from=build /app/api-gateway/target/api-gateway-*.jar /app/services/api-gateway.jar
COPY --from=build /app/product-service/target/product-service-*.jar /app/services/product-service.jar
COPY --from=build /app/order-service/target/order-service-*.jar /app/services/order-service.jar
COPY --from=build /app/inventory-service/target/inventory-service-*.jar /app/services/inventory-service.jar

# Copy startup script
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh

# Expose ports for all services
EXPOSE 9000 8080 8081 8082

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:9000/actuator/health || exit 1

# Use startup script as entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]

