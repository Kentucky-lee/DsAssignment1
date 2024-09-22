import ballerina/grpc;
import ballerina/io;

public function main() returns error? {
    grpc:Client shoppingClient = check new ("http://localhost:9090", []);

    // Example: Admin adds a product
    AddProductRequest req = {
        name: "Laptop",
        description: "A high-performance laptop",
        price: 1200.50,
        stock_quantity: 10,
        sku: "SKU123",
        status: "available"
    };
    AddProductResponse response = check shoppingClient->addProduct(req);
    io:println("Product added with code: ", response.product_code);

    // Example: Customer lists available products
    ProductListResponse products = check shoppingClient->listAvailableProducts({});
    io:println("Available products:");
    foreach var product in products.products {
        io:println(" - ", product.name);
    }

    check shoppingClient.close();
}
