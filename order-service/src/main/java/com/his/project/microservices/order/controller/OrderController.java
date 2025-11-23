package com.his.project.microservices.order.controller;

import com.his.project.microservices.order.dto.OrderRequest;
import com.his.project.microservices.order.service.OrderService;
import groovy.util.logging.Slf4j;
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

import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/api/order")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Order", description = "Order management APIs")
public class OrderController {

    private final OrderService orderService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(
            summary = "Place a new order",
            description = "Creates a new order for the specified product with user details",
            requestBody = @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Order details",
                    required = true,
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = OrderRequest.class),
                            examples = @ExampleObject(
                                    name = "Example Order",
                                    value = "{\n" +
                                            "  \"skuCode\": \"IPHONE-15-PRO-256\",\n" +
                                            "  \"price\": 999.99,\n" +
                                            "  \"quantity\": 2,\n" +
                                            "  \"userDetails\": {\n" +
                                            "    \"email\": \"john.doe@example.com\",\n" +
                                            "    \"firstName\": \"John\",\n" +
                                            "    \"lastName\": \"Doe\"\n" +
                                            "  }\n" +
                                            "}"
                            )
                    )
            )
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "201",
                    description = "Order placed successfully",
                    content = @Content(
                            mediaType = "text/plain",
                            examples = @ExampleObject(
                                    name = "Success Response",
                                    value = "Order Placed Successfully"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Bad request - Invalid order data or product out of stock",
                    content = @Content(
                            mediaType = "text/plain",
                            examples = @ExampleObject(
                                    name = "Error Response",
                                    value = "Product is out of stock"
                            )
                    )
            ),
            @ApiResponse(
                    responseCode = "503",
                    description = "Service unavailable - Fallback response",
                    content = @Content(
                            mediaType = "text/plain",
                            examples = @ExampleObject(
                                    name = "Fallback Response",
                                    value = "Oops! Something went wrong, please order after some time!"
                            )
                    )
            )
    })
    public String placeOrder(@RequestBody OrderRequest orderRequest) {
        orderService.placeOrder(orderRequest);
        return "Order Placed Successfully";
    }

    public CompletableFuture<String> fallbackMethod(OrderRequest orderRequest, RuntimeException runtimeException) {
        return CompletableFuture.supplyAsync(() -> "Oops! Something went wrong, please order after some time!");
    }
}
