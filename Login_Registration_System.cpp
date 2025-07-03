#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <limits>

// --- Function Prototypes ---

/**
 * @brief Displays the main menu.
 */
void showMenu();

/**
 * @brief Handles the user registration process.
 */
void registerUser();

/**
 * @brief Handles the user login process.
 * @return true if login is successful, false otherwise.
 */
bool loginUser();

/**
 * @brief The main function to run the login/registration system.
 */
int main() {
    int choice;

    do {
        showMenu();
        std::cout << "Enter your choice: ";
        std::cin >> choice;
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n'); // Clear input buffer

        switch (choice) {
            case 1:
                registerUser();
                break;
            case 2:
                if (loginUser()) {
                    std::cout << "\n--- Welcome! You are now logged in. ---" << std::endl;
                    // You can add functionality for logged-in users here.
                    // For now, we'll just log them out to return to the menu.
                    std::cout << "--- Logging you out. ---" << std::endl;
                }
                break;
            case 3:
                std::cout << "Thank you for using the system. Goodbye!" << std::endl;
                break;
            default:
                std::cout << "Invalid choice. Please try again." << std::endl;
                break;
        }
    } while (choice != 3);

    return 0;
}

// --- Function Definitions ---

void showMenu() {
    std::cout << "\n--- Main Menu ---" << std::endl;
    std::cout << "1. Register" << std::endl;
    std::cout << "2. Login" << std::endl;
    std::cout << "3. Exit" << std::endl;
    std::cout << "-----------------" << std::endl;
}

void registerUser() {
    std::string username, password;

    std::cout << "\n--- User Registration ---" << std::endl;
    std::cout << "Enter a new username: ";
    std::getline(std::cin, username);

    std::cout << "Enter a new password: ";
    std::getline(std::cin, password);

    // --- Check if username already exists ---
    std::ifstream file_in("userdata.txt");
    std::string stored_username, stored_password;
    bool username_exists = false;
    while (file_in >> stored_username >> stored_password) {
        if (username == stored_username) {
            username_exists = true;
            break;
        }
    }
    file_in.close();

    if (username_exists) {
        std::cout << "\nError: Username already exists. Please try a different username." << std::endl;
    } else {
        // --- Store new user credentials ---
        // Open the file in append mode to add the new user at the end.
        std::ofstream file_out("userdata.txt", std::ios::app); 
        if (file_out.is_open()) {
            file_out << username << " " << password << std::endl;
            file_out.close();
            std::cout << "\nRegistration successful!" << std::endl;
        } else {
            std::cout << "\nError: Could not open file for writing." << std::endl;
        }
    }
}

bool loginUser() {
    std::string username, password;

    std::cout << "\n--- User Login ---" << std::endl;
    std::cout << "Enter username: ";
    std::getline(std::cin, username);

    std::cout << "Enter password: ";
    std::getline(std::cin, password);

    std::ifstream file_in("userdata.txt");
    std::string stored_username, stored_password;
    bool login_success = false;

    if (!file_in.is_open()) {
        std::cout << "\nError: Could not open user data file. No users registered yet?" << std::endl;
        return false;
    }

    // Read the file and check for matching credentials
    while (file_in >> stored_username >> stored_password) {
        if (username == stored_username && password == stored_password) {
            login_success = true;
            break;
        }
    }

    file_in.close();

    if (login_success) {
        std::cout << "\nLogin successful!" << std::endl;
        return true;
    } else {
        std::cout << "\nError: Invalid username or password." << std::endl;
        return false;
    }
}
