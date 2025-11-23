package com.his.project.microservices.gateway.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@RestController
@RequestMapping("/api-docs")
public class SwaggerAggregatorController {

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    
    @Value("${product.service.url}")
    private String productServiceUrl;
    
    @Value("${order.service.url}")
    private String orderServiceUrl;
    
    @Value("${inventory.service.url}")
    private String inventoryServiceUrl;

    public SwaggerAggregatorController() {
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> getAggregatedApiDocs() {
        try {
            Map<String, Object> aggregated = new LinkedHashMap<>();
            
            // Set OpenAPI version
            aggregated.put("openapi", "3.0.1");
            
            // Set unified info
            Map<String, Object> info = new LinkedHashMap<>();
            info.put("title", "Microservices API Gateway - All Services");
            info.put("description", "Unified API documentation for all microservices. This combines APIs from Product, Order, and Inventory services.");
            info.put("version", "v1.0.0");
            aggregated.put("info", info);
            
            // Set server
            List<Map<String, String>> servers = new ArrayList<>();
            servers.add(Map.of("url", "http://localhost:9000", "description", "API Gateway"));
            aggregated.put("servers", servers);
            
            // Aggregate paths from all services
            Map<String, Object> allPaths = new LinkedHashMap<>();
            
            // Get Product Service APIs
            addServicePaths(productServiceUrl, allPaths, "Product Service");
            
            // Get Order Service APIs
            addServicePaths(orderServiceUrl, allPaths, "Order Service");
            
            // Get Inventory Service APIs
            addServicePaths(inventoryServiceUrl, allPaths, "Inventory Service");
            
            aggregated.put("paths", allPaths);
            
            // Aggregate components (schemas, etc.)
            Map<String, Object> components = new LinkedHashMap<>();
            Map<String, Object> schemas = new LinkedHashMap<>();
            
            addServiceComponents(productServiceUrl, schemas);
            addServiceComponents(orderServiceUrl, schemas);
            addServiceComponents(inventoryServiceUrl, schemas);
            
            if (!schemas.isEmpty()) {
                components.put("schemas", schemas);
                aggregated.put("components", components);
            }
            
            return ResponseEntity.ok(aggregated);
            
        } catch (Exception e) {
            // Fallback: return a simple structure if aggregation fails
            Map<String, Object> fallback = new LinkedHashMap<>();
            fallback.put("openapi", "3.0.1");
            Map<String, Object> info = new LinkedHashMap<>();
            info.put("title", "Microservices API Gateway");
            info.put("description", "Use the dropdown above to select individual services");
            info.put("version", "v1.0.0");
            fallback.put("info", info);
            fallback.put("servers", List.of(Map.of("url", "http://localhost:9000")));
            fallback.put("paths", new LinkedHashMap<>());
            return ResponseEntity.ok(fallback);
        }
    }
    
    private void addServicePaths(String serviceUrl, Map<String, Object> allPaths, String serviceName) {
        try {
            String apiDocsUrl = serviceUrl + "/api-docs";
            Map<String, Object> serviceApi = restTemplate.getForObject(apiDocsUrl, Map.class);
            
            if (serviceApi != null && serviceApi.containsKey("paths")) {
                @SuppressWarnings("unchecked")
                Map<String, Object> servicePaths = (Map<String, Object>) serviceApi.get("paths");
                
                if (servicePaths != null) {
                    servicePaths.forEach((path, pathItemObj) -> {
                        try {
                            // Parse path item and add service tag
                            if (pathItemObj instanceof Map) {
                                @SuppressWarnings("unchecked")
                                Map<String, Object> pathItem = (Map<String, Object>) pathItemObj;
                                
                                // Add service name as tag to all operations
                                pathItem.forEach((method, operation) -> {
                                    if (operation instanceof Map) {
                                        @SuppressWarnings("unchecked")
                                        Map<String, Object> opMap = (Map<String, Object>) operation;
                                        
                                        @SuppressWarnings("unchecked")
                                        List<String> tags = (List<String>) opMap.getOrDefault("tags", new ArrayList<>());
                                        if (!tags.contains(serviceName)) {
                                            tags.add(serviceName);
                                        }
                                        opMap.put("tags", tags);
                                    }
                                });
                            }
                            
                            // Add path (prefix with service name if needed to avoid conflicts)
                            allPaths.put(path, pathItemObj);
                        } catch (Exception e) {
                            // Skip this path if there's an error
                        }
                    });
                }
            }
        } catch (Exception e) {
            // Silently skip if service is not available
            System.err.println("Could not fetch API docs from " + serviceName + ": " + e.getMessage());
        }
    }
    
    private void addServiceComponents(String serviceUrl, Map<String, Object> allSchemas) {
        try {
            String apiDocsUrl = serviceUrl + "/api-docs";
            Map<String, Object> serviceApi = restTemplate.getForObject(apiDocsUrl, Map.class);
            
            if (serviceApi != null && serviceApi.containsKey("components")) {
                @SuppressWarnings("unchecked")
                Map<String, Object> components = (Map<String, Object>) serviceApi.get("components");
                
                if (components != null && components.containsKey("schemas")) {
                    @SuppressWarnings("unchecked")
                    Map<String, Object> schemas = (Map<String, Object>) components.get("schemas");
                    
                    if (schemas != null) {
                        allSchemas.putAll(schemas);
                    }
                }
            }
        } catch (Exception e) {
            // Silently skip if service is not available
        }
    }
}

