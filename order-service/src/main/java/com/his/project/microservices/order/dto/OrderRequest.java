package com.his.project.microservices.order.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;

@Schema(description = "Request object for placing an order")
public record OrderRequest(
        @Schema(description = "Order ID (optional, auto-generated if not provided)", example = "1")
        Long id,
        @Schema(description = "Order number (optional, auto-generated if not provided)", example = "ORD-2024-001")
        String orderNumber,
        @Schema(description = "Product SKU code", example = "IPHONE-15-PRO-256", required = true)
        String skuCode,
        @Schema(description = "Product price per unit", example = "999.99", required = true)
        BigDecimal price,
        @Schema(description = "Quantity of products to order", example = "2", required = true)
        Integer quantity,
        @Schema(description = "User details for the order", required = true)
        UserDetails userDetails
) {
    @Schema(description = "User details for order placement")
    public record UserDetails(
            @Schema(description = "User email address", example = "john.doe@example.com", required = true)
            String email,
            @Schema(description = "User first name", example = "John", required = true)
            String firstName,
            @Schema(description = "User last name", example = "Doe", required = true)
            String lastName
    ) {}
}


