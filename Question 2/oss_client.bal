import ballerina/grpc;
import ballerina/io;

public function main() {
    // Create gRPC client
    ShoppingServiceClient client = check ShoppingServiceClient->create("http://localhost:8080");

    // Example: Call the addProduct method
    AddProductRequest addProductRequest = {name: "Sample Product", description: "This is a sample product", 
                                           price: 19.99, stock_quantity: 100, sku: "SKU123", status: "available"};
    AddProductResponse response = check client->addProduct(addProductRequest);
    io:println("Product added with code: ", response.product_code);
    
    // Implement additional client calls as needed
}
