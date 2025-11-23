package com.his.project.microservices.product.controller;

import com.his.project.microservices.product.dto.ProductRequest;
import com.his.project.microservices.product.dto.ProductResponse;
import com.his.project.microservices.product.service.ProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/product")
@RequiredArgsConstructor
@Tag(name = "Product", description = "Product management APIs")
public class ProductController {

    private final ProductService productService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(
            summary = "Create a new product",
            description = "Creates a new product with the provided details",
            requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Product details",
                    required = true,
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = ProductRequest.class),
                            examples = @ExampleObject(
                                    name = "Example Product",
                                    value = "{\n" +
                                            "  \"name\": \"iPhone 15 Pro\",\n" +
                                            "  \"description\": \"Latest iPhone with A17 Pro chip\",\n" +
                                            "  \"skuCode\": \"IPHONE-15-PRO-256\",\n" +
                                            "  \"price\": 999.99\n" +
                                            "}"
                            )
                    )
            )
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "201",
                    description = "Product created successfully",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = ProductResponse.class),
                            examples = @ExampleObject(
                                    name = "Success Response",
                                    value = "{\n" +
                                            "  \"id\": \"507f1f77bcf86cd799439011\",\n" +
                                            "  \"name\": \"iPhone 15 Pro\",\n" +
                                            "  \"description\": \"Latest iPhone with A17 Pro chip\",\n" +
                                            "  \"skuCode\": \"IPHONE-15-PRO-256\",\n" +
                                            "  \"price\": 999.99\n" +
                                            "}"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Bad request - Invalid input data",
                    content = @Content
            )
    })
    public ProductResponse createProduct(@RequestBody ProductRequest productRequest) {
        return productService.createProduct(productRequest);
    }

    @GetMapping
    @ResponseStatus(HttpStatus.OK)
    @Operation(
            summary = "Get all products",
            description = "Retrieves a list of all available products"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Products retrieved successfully",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = ProductResponse.class),
                            examples = @ExampleObject(
                                    name = "Success Response",
                                    value = "[\n" +
                                            "  {\n" +
                                            "    \"id\": \"507f1f77bcf86cd799439011\",\n" +
                                            "    \"name\": \"iPhone 15 Pro\",\n" +
                                            "    \"description\": \"Latest iPhone with A17 Pro chip\",\n" +
                                            "    \"skuCode\": \"IPHONE-15-PRO-256\",\n" +
                                            "    \"price\": 999.99\n" +
                                            "  },\n" +
                                            "  {\n" +
                                            "    \"id\": \"507f1f77bcf86cd799439012\",\n" +
                                            "    \"name\": \"Samsung Galaxy S24\",\n" +
                                            "    \"description\": \"Flagship Android smartphone\",\n" +
                                            "    \"skuCode\": \"SAMSUNG-S24-256\",\n" +
                                            "    \"price\": 899.99\n" +
                                            "  }\n" +
                                            "]"
                            )
                    )
            )
    })
    public List<ProductResponse> getAllProducts() {
        return productService.getAllProducts();
    }
}
