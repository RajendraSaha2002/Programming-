#include <iostream>
#include <vector>
#include <string>
#include <limits>

// A struct to represent an item in the inventory
struct Item {
    std::string name;
    int quantity;
    double price;
};

// Function to get a valid integer input from the user
int get_valid_int() {
    int value;
    while (!(std::cin >> value)) {
        std::cout << "Invalid input. Please enter a number: ";
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    }
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    return value;
}

// Function to get a valid double input from the user
double get_valid_double() {
    double value;
    while (!(std::cin >> value)) {
        std::cout << "Invalid input. Please enter a number: ";
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    }
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    return value;
}

// Function to add a new item to the inventory
void addItem(std::vector<Item>& inventory) {
    Item newItem;
    std::cout << "Enter item name: ";
    std::getline(std::cin, newItem.name);
    std::cout << "Enter quantity: ";
    newItem.quantity = get_valid_int();
    std::cout << "Enter price: $";
    newItem.price = get_valid_double();

    inventory.push_back(newItem);
    std::cout << "Item added successfully!\n";
}

// Function to display all items in the inventory
void displayInventory(const std::vector<Item>& inventory) {
    if (inventory.empty()) {
        std::cout << "Inventory is empty.\n";
        return;
    }

    std::cout << "\n-------------------\n";
    std::cout << "  Current Inventory\n";
    std::cout << "-------------------\n";
    for (const auto& item : inventory) {
        std::cout << "Name: " << item.name
                  << " | Quantity: " << item.quantity
                  << " | Price: $" << item.price << "\n";
    }
    std::cout << "-------------------\n";
}

// Function to update the quantity and/or price of an existing item
void updateItem(std::vector<Item>& inventory) {
    if (inventory.empty()) {
        std::cout << "Inventory is empty. No items to update.\n";
        return;
    }

    std::string nameToUpdate;
    std::cout << "Enter the name of the item to update: ";
    std::getline(std::cin, nameToUpdate);

    // Find the item by name
    bool found = false;
    for (auto& item : inventory) {
        if (item.name == nameToUpdate) {
            std::cout << "Item found. Enter new quantity: ";
            item.quantity = get_valid_int();
            std::cout << "Enter new price: $";
            item.price = get_valid_double();
            std::cout << "Item updated successfully!\n";
            found = true;
            break;
        }
    }

    if (!found) {
        std::cout << "Item '" << nameToUpdate << "' not found.\n";
    }
}

// Function to remove an item from the inventory
void removeItem(std::vector<Item>& inventory) {
    if (inventory.empty()) {
        std::cout << "Inventory is empty. No items to remove.\n";
        return;
    }

    std::string nameToRemove;
    std::cout << "Enter the name of the item to remove: ";
    std::getline(std::cin, nameToRemove);

    // Find the item and remove it
    bool found = false;
    for (size_t i = 0; i < inventory.size(); ++i) {
        if (inventory[i].name == nameToRemove) {
            inventory.erase(inventory.begin() + i);
            std::cout << "Item removed successfully!\n";
            found = true;
            break;
        }
    }

    if (!found) {
        std::cout << "Item '" << nameToRemove << "' not found.\n";
    }
}

int main() {
    std::vector<Item> inventory;
    char choice;

    while (true) {
        // Display the main menu
        std::cout << "\n--- Inventory Management System ---\n";
        std::cout << "1. Add Item\n";
        std::cout << "2. Display Inventory\n";
        std::cout << "3. Update Item\n";
        std::cout << "4. Remove Item\n";
        std::cout << "5. Exit\n";
        std::cout << "Enter your choice: ";
        std::cin >> choice;

        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');

        // Handle user choice
        switch (choice) {
            case '1':
                addItem(inventory);
                break;
            case '2':
                displayInventory(inventory);
                break;
            case '3':
                updateItem(inventory);
                break;
            case '4':
                removeItem(inventory);
                break;
            case '5':
                std::cout << "Exiting program. Goodbye!\n";
                return 0;
            default:
                std::cout << "Invalid choice. Please try again.\n";
        }
    }

    return 0;
}
