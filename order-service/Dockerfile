# Multi-stage Dockerfile for Order Service
FROM maven:3.9.6-eclipse-temurin-21 AS build

WORKDIR /app

# Copy parent pom.xml first
COPY pom.xml ./pom.xml

# Copy all module pom.xml files (Maven needs them to resolve parent)
COPY api-gateway/pom.xml ./api-gateway/pom.xml
COPY product-service/pom.xml ./product-service/pom.xml
COPY order-service/pom.xml ./order-service/pom.xml
COPY inventory-service/pom.xml ./inventory-service/pom.xml

# Download dependencies (this layer will be cached)
RUN mvn dependency:go-offline -B -pl order-service -am

# Copy source code
COPY order-service/src ./order-service/src

# Build the service (retry once on transient network/SSL errors)
RUN mvn clean package -DskipTests -B -pl order-service || \
    (echo "Retrying build after 15s..." && sleep 15 && mvn clean package -DskipTests -B -pl order-service)

# Runtime stage
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Install wget for health checks
RUN apk add --no-cache wget

# Create non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy JAR file
COPY --from=build /app/order-service/target/order-service-*.jar app.jar

# Expose port
EXPOSE 8081

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8081/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

