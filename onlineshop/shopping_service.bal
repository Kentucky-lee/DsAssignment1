import ballerina/grpc;
import ballerina/io;
import ballerina/lang.map;

// Define the service types
type Product record {
    string name;
    string description;
    float price;
    int stock_quantity;
    string sku;
    string status;
};

type Order record {
    string user_id;
    Product[] items;
};

// In-memory storage for products and orders
map<Product> productInventory = {};
map<Order> orders = {};
map<string> ProductCart = {}; // For storing user carts

// gRPC Service Implementation
service "ShoppingService" on new grpc:Listener(9090) {

    // Add a product to the inventory
    remote function addProduct(AddProductRequest req) returns AddProductResponse {
        Product product = {
            name: req.name,
            description: req.description,
            price: req.price,
            stock_quantity: req.stock_quantity,
            sku: req.sku,
            status: req.status
        };
        productInventory[req.sku] = product;
        return {product_code: req.sku};
    }

    // Update a product's details
    remote function updateProduct(UpdateProductRequest req) returns UpdateProductResponse {
        if productInventory.hasKey(req.sku) {
            Product updatedProduct = {
                name: req.name,
                description: req.description,
                price: req.price,
                stock_quantity: req.stock_quantity,
                sku: req.sku,
                status: req.status
            };
            productInventory[req.sku] = updatedProduct;
            return {message: "Product updated successfully"};
        } else {
            return {message: "Product not found"};
        }
    }

    // Remove a product from inventory
    remote function removeProduct(RemoveProductRequest req) returns RemoveProductResponse {
        if productInventory.remove(req.sku) != () {
            return {products: productInventory.toArray()};
        } else {
            return {products: []};
        }
    }

    // List all available products
    remote function listAvailableProducts(Empty req) returns ProductListResponse {
        Product[] availableProducts = [];
        foreach var product in productInventory.values() {
            if product.status == "available" {
                availableProducts.push(product);
            }
        }
        return {products: availableProducts};
    }

    // Search for a product by SKU
    remote function searchProduct(SearchProductRequest req) returns SearchProductResponse {
        if productInventory.hasKey(req.sku) {
            return {product: productInventory[req.sku]};
        } else {
            return {message: "Product not available"};
        }
    }

    // Add a product to the customer's cart
    remote function addToCart(AddToCartRequest req) returns AddToCartResponse {
        if !cart.hasKey(req.user_id) {
            cart[req.user_id] = [];
        }
        Product product = productInventory[req.sku];
        cart[req.user_id].push(product);
        return {message: "Product added to cart"};
    }

    // Place an order for all products in the cart
    remote function placeOrder(PlaceOrderRequest req) returns PlaceOrderResponse {
        if cart.hasKey(req.user_id) && cart[req.user_id].length() > 0 {
            Order newOrder = {user_id: req.user_id, items: cart[req.user_id]};
            orders[req.user_id] = newOrder;
            cart[req.user_id] = [];
            return {message: "Order placed successfully"};
        } else {
            return {message: "Cart is empty"};
        }
    }

    // Admin operation to list all orders
    remote function listAllOrders(Empty req) returns OrderListResponse {
        string[] orderSummaries = [];
        foreach var order in orders.values() {
            string orderSummary = "User " + order.user_id + " ordered: ";
            foreach var item in order.items {
                orderSummary += item.name + ", ";
            }
            orderSummaries.push(orderSummary);
        }
        return {orders: orderSummaries};
    }

    // Streaming for creating multiple users
    remote function createUsers(stream<CreateUserRequest> req) returns CreateUserResponse {
        CreateUserRequest user;
        while req.hasNext() {
            user = check req.next();
            io:println("Created user: ", user.user_id, " (", user.user_type, ")");
        }
        return {message: "Users created successfully"};
    }
}
