import ballerina/grpc;
import ballerina/io;

// Type Definitions
type Product record {
    string name;
    string description;
    float price;
    int stock_quantity;
    string sku;
    string status; // "available" or "out of stock"
};

type ProductListResponse record {
    Product[] products;
};

type AddProductRequest record {
    string name;
    string description;
    float price;
    int stock_quantity;
    string sku;
    string status; // "available" or "out of stock"
};

type AddProductResponse record {
    string product_code;
};

type CreateUserRequest record {
    string user_id;
    string user_type; // "customer" or "admin"
};

type CreateUserResponse record {
    string message;
};

type UpdateProductRequest record {
    string sku;
    string name;
    string description;
    float price;
    int stock_quantity;
    string status; // "available" or "out of stock"
};

type UpdateProductResponse record {
    string message;
};

type RemoveProductRequest record {
    string sku;
};

type RemoveProductResponse record {
    Product[] products; // List of remaining products after removal
};

type SearchProductRequest record {
    string sku;
};

type SearchProductResponse record {
    Product product; // Product details if found
    string message; // Message if not found
};

type AddToCartRequest record {
    string user_id;
    string sku;
};

type AddToCartResponse record {
    string message;
};

type PlaceOrderRequest record {
    string user_id;
};

type PlaceOrderResponse record {
    string message;
};

type Empty record {};

// gRPC Service Implementation
service /shopping on new grpc:Listener(8080) {

    // In-memory storage for products and carts
    map<Product> productInventory = {};
    map<string> cart = {};
    map<string> userType = {};

    resource function post addProduct(AddProductRequest req) returns AddProductResponse {
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

    resource function post createUsers(stream CreateUserRequest req) returns CreateUserResponse {
        // Handle user creation logic
        CreateUserRequest user;
        while (req.hasNext()) {
            user = check req.next();
            userType[user.user_id] = user.user_type;
            io:println("User created: ", user.user_id, " as ", user.user_type);
        }
        return {message: "Users created successfully."};
    }

    resource function post updateProduct(UpdateProductRequest req) returns UpdateProductResponse {
        if (productInventory.hasKey(req.sku)) {
            Product product = {
                name: req.name,
                description: req.description,
                price: req.price,
                stock_quantity: req.stock_quantity,
                sku: req.sku,
                status: req.status
            };
            productInventory[req.sku] = product;
            return {message: "Product updated successfully."};
        } else {
            return {message: "Product not found."};
        }
    }

    resource function post removeProduct(RemoveProductRequest req) returns RemoveProductResponse {
        if (productInventory.remove(req.sku) != ()) {
            return listAvailableProducts();
        } else {
            return {products: []}; // No products removed
        }
    }

    resource function post listAvailableProducts(Empty req) returns ProductListResponse {
        Product[] availableProducts = [];
        foreach var product in productInventory.values() {
            if (product.status == "available") {
                availableProducts.push(product);
            }
        }
        return {products: availableProducts};
    }

    resource function post searchProduct(SearchProductRequest req) returns SearchProductResponse {
        if (productInventory.hasKey(req.sku)) {
            Product product = productInventory[req.sku];
            return {product: product, message: ""}; // Product found
        } else {
            return {product: {}, message: "Product not available."}; // Not found
        }
    }

    resource function post addToCart(AddToCartRequest req) returns AddToCartResponse {
        if (!cart.hasKey(req.user_id)) {
            cart[req.user_id] = "";
        }
        cart[req.user_id] += req.sku + ",";
        return {message: "Product added to cart."};
    }

    resource function post placeOrder(PlaceOrderRequest req) returns PlaceOrderResponse {
        string items = cart[req.user_id];
        if (items == "") {
            return {message: "Cart is empty."};
        } else {
            cart[req.user_id] = ""; // Clear cart after order
            return {message: "Order placed for items: " + items};
        }
    }
}
