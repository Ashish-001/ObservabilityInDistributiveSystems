package com.his.project.microservices.product.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;

@Schema(description = "Request object for creating a product")
public record ProductRequest(
        @Schema(description = "Product ID (optional, auto-generated if not provided)", example = "507f1f77bcf86cd799439011")
        String id,
        @Schema(description = "Product name", example = "iPhone 15 Pro", required = true)
        String name,
        @Schema(description = "Product description", example = "Latest iPhone with A17 Pro chip", required = true)
        String description,
        @Schema(description = "Stock Keeping Unit code", example = "IPHONE-15-PRO-256", required = true)
        String skuCode,
        @Schema(description = "Product price", example = "999.99", required = true)
        BigDecimal price
) {
}
