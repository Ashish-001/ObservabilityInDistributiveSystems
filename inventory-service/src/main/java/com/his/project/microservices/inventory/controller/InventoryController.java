package com.his.project.microservices.inventory.controller;

import com.his.project.microservices.inventory.model.Inventory;
import com.his.project.microservices.inventory.service.InventoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/inventory")
@RequiredArgsConstructor
@Tag(name = "Inventory", description = "Inventory management APIs")
public class InventoryController {
    private final InventoryService inventoryService;

    @GetMapping
    @ResponseStatus(HttpStatus.OK)
    @Operation(
            summary = "Check product availability",
            description = "Checks if the specified product is available in the requested quantity"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Inventory check completed",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(type = "boolean"),
                            examples = {
                                    @ExampleObject(
                                            name = "In Stock",
                                            value = "true",
                                            description = "Product is available in the requested quantity"
                                    ),
                                    @ExampleObject(
                                            name = "Out of Stock",
                                            value = "false",
                                            description = "Product is not available in the requested quantity"
                                    )
                            }
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Bad request - Invalid parameters",
                    content = @Content
            )
    })
    public boolean isInStock(
            @RequestParam
            @Parameter(
                    description = "Product SKU code",
                    example = "IPHONE-15-PRO-256",
                    required = true
            )
            String skuCode,
            @RequestParam
            @Parameter(
                    description = "Requested quantity",
                    example = "2",
                    required = true
            )
            Integer quantity
    ) {
        return inventoryService.isInStock(skuCode, quantity);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(
            summary = "Create inventory entry",
            description = "Creates a new inventory entry for a product with the specified SKU code and quantity"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "201",
                    description = "Inventory entry created successfully"
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Bad request - Invalid input data",
                    content = @Content
            )
    })
    public Inventory createInventory(
            @RequestParam
            @Parameter(
                    description = "Product SKU code",
                    example = "IPHONE-15-PRO-256",
                    required = true
            )
            String skuCode,
            @RequestParam
            @Parameter(
                    description = "Initial quantity",
                    example = "100",
                    required = true
            )
            Integer quantity
    ) {
        return inventoryService.createInventory(skuCode, quantity);
    }
}
