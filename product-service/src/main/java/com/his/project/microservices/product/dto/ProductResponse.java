package com.his.project.microservices.product.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.math.BigDecimal;

@Schema(description = "Response object containing product information")
public record ProductResponse(
        @Schema(description = "Product ID", example = "507f1f77bcf86cd799439011")
        String id,
        @Schema(description = "Product name", example = "iPhone 15 Pro")
        String name,
        @Schema(description = "Product description", example = "Latest iPhone with A17 Pro chip")
        String description,
        @Schema(description = "Stock Keeping Unit code", example = "IPHONE-15-PRO-256")
        String skuCode,
        @Schema(description = "Product price", example = "999.99")
        BigDecimal price
) {
}
