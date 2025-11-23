package com.his.project.microservices.gateway.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenAPIConfig {

    @Bean
    public OpenAPI apiGatewayAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Microservices API Gateway - Unified API Documentation")
                        .description("""
                                Complete API documentation for all microservices.
                                
                                **Available Services:**
                                - **Product Service** - Manage products (MongoDB)
                                - **Order Service** - Handle order processing (MySQL)
                                - **Inventory Service** - Manage inventory and stock (MySQL)
                                
                                Use the dropdown above to switch between services or view the unified API documentation.
                                All APIs are accessible through the API Gateway at port 9000.
                                """)
                        .version("v1.0.0")
                        .contact(new Contact()
                                .name("Microservices Team")
                                .email("api@microservices.com"))
                        .license(new License()
                                .name("Apache 2.0")
                                .url("https://www.apache.org/licenses/LICENSE-2.0.html")))
                .servers(List.of(
                        new Server()
                                .url("http://localhost:9000")
                                .description("API Gateway - Production"),
                        new Server()
                                .url("http://localhost:8080")
                                .description("Product Service - Direct Access"),
                        new Server()
                                .url("http://localhost:8081")
                                .description("Order Service - Direct Access"),
                        new Server()
                                .url("http://localhost:8082")
                                .description("Inventory Service - Direct Access")
                ));
    }
}

