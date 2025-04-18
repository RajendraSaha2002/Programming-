#include <iostream>
#include <vector>
using namespace std;

// Product class
class Product {
private:
    int id;
    string name;
    float price;

public:
    Product(int pid, string pname, float pprice)
        : id(pid), name(pname), price(pprice) {}

    int getId() const { return id; }
    string getName() const { return name; }
    float getPrice() const { return price; }

    void display() const {
        cout << "ID: " << id << ", Name: " << name << ", Price: $" << price << endl;
    }
};

// CartItem class
class CartItem {
private:
    Product product;
    int quantity;

public:
    CartItem(Product p, int qty) : product(p), quantity(qty) {}

    float getTotalPrice() const {
        return product.getPrice() * quantity;
    }

    void display() const {
        cout << product.getName() << " x " << quantity
             << " = $" << getTotalPrice() << endl;
    }
};

// ShoppingCart class
class ShoppingCart {
private:
    vector<CartItem> items;

public:
    void addItem(Product p, int qty) {
        items.push_back(CartItem(p, qty));
    }

    void showCart() const {
        if (items.empty()) {
            cout << "Cart is empty.\n";
            return;
        }

        float total = 0;
        cout << "Items in Cart:\n";
        for (const auto& item : items) {
            item.display();
            total += item.getTotalPrice();
        }
        cout << "-------------------------\n";
        cout << "Total Amount: $" << total << "\n";
    }
};

// Main Program
int main() {
    // Sample Products
    vector<Product> productList = {
        Product(1, "Dell XPS 13", 899.99),
        Product(2, "Samsung Galaxy S25 Ultra", 1499.50),
        Product(3, "Boat Nirvana", 99.99),
        Product(4, "Asus Gaming Mechanical Keyboard", 45.00),
        Product(5, "Hp Wireless Mouse", 25.50)
    };

    ShoppingCart cart;
    int choice, qty;

    while (true) {
        cout << "\n--- Product List ---\n";
        for (const auto& p : productList)
            p.display();

        cout << "\nEnter Product ID to add to cart (0 to checkout): ";
        cin >> choice;

        if (choice == 0) break;

        bool found = false;
        for (const auto& p : productList) {
            if (p.getId() == choice) {
                cout << "Enter quantity: ";
                cin >> qty;
                cart.addItem(p, qty);
                found = true;
                break;
            }
        }

        if (!found)
            cout << "Invalid product ID!\n";
    }

    cout << "\n--- Your Cart ---\n";
    cart.showCart();

    return 0;
}
