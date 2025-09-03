
#include <iostream>
#include <vector>
#include <string>
#include <limits>

// A struct to represent a contact with a name and phone number
struct Contact {
    std::string name;
    std::string phoneNumber;
};

// Function to get a valid string input from the user
std::string get_line_input(const std::string& prompt) {
    std::string input;
    std::cout << prompt;
    std::getline(std::cin, input);
    return input;
}

// Function to add a new contact to the phonebook
void addContact(std::vector<Contact>& phonebook) {
    Contact newContact;
    std::cout << "--- Add New Contact ---\n";
    newContact.name = get_line_input("Enter contact name: ");
    newContact.phoneNumber = get_line_input("Enter phone number: ");
    phonebook.push_back(newContact);
    std::cout << "Contact '" << newContact.name << "' added successfully!\n";
}

// Function to display all contacts in the phonebook
void displayContacts(const std::vector<Contact>& phonebook) {
    if (phonebook.empty()) {
        std::cout << "\nPhonebook is currently empty.\n";
        return;
    }

    std::cout << "\n--- All Contacts ---\n";
    for (size_t i = 0; i < phonebook.size(); ++i) {
        std::cout << i + 1 << ". Name: " << phonebook[i].name
                  << ", Phone: " << phonebook[i].phoneNumber << "\n";
    }
    std::cout << "---------------------\n";
}

// Function to search for a contact by name
void searchContact(const std::vector<Contact>& phonebook) {
    std::string nameToSearch;
    std::cout << "--- Search Contact ---\n";
    nameToSearch = get_line_input("Enter name to search: ");

    bool found = false;
    for (const auto& contact : phonebook) {
        if (contact.name == nameToSearch) {
            std::cout << "Contact Found!\n";
            std::cout << "Name: " << contact.name << ", Phone: " << contact.phoneNumber << "\n";
            found = true;
            break;
        }
    }
    
    if (!found) {
        std::cout << "Contact '" << nameToSearch << "' not found.\n";
    }
}

// Function to delete a contact by name
void deleteContact(std::vector<Contact>& phonebook) {
    std::string nameToDelete;
    std::cout << "--- Delete Contact ---\n";
    nameToDelete = get_line_input("Enter name to delete: ");

    bool found = false;
    for (size_t i = 0; i < phonebook.size(); ++i) {
        if (phonebook[i].name == nameToDelete) {
            phonebook.erase(phonebook.begin() + i);
            std::cout << "Contact '" << nameToDelete << "' deleted successfully!\n";
            found = true;
            break;
        }
    }

    if (!found) {
        std::cout << "Contact '" << nameToDelete << "' not found.\n";
    }
}

int main() {
    std::vector<Contact> phonebook;
    int choice;

    // Clear the input buffer to prevent issues with initial getline
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');

    while (true) {
        // Display the main menu
        std::cout << "\n--- Phonebook Application ---\n";
        std::cout << "1. Add a new contact\n";
        std::cout << "2. Display all contacts\n";
        std::cout << "3. Search for a contact\n";
        std::cout << "4. Delete a contact\n";
        std::cout << "5. Exit\n";
        std::cout << "Enter your choice: ";
        
        // Read the choice as an integer
        std::cin >> choice;

        // Check for invalid input (e.g., letters)
        if (std::cin.fail()) {
            std::cout << "Invalid input. Please enter a number from 1-5.\n";
            std::cin.clear();
            std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
            continue;
        }

        // Clear the remaining newline character from the input buffer
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');

        // Handle the user's choice
        switch (choice) {
            case 1:
                addContact(phonebook);
                break;
            case 2:
                displayContacts(phonebook);
                break;
            case 3:
                searchContact(phonebook);
                break;
            case 4:
                deleteContact(phonebook);
                break;
            case 5:
                std::cout << "Exiting the application. Goodbye!\n";
                return 0;
            default:
                std::cout << "Invalid choice. Please try again.\n";
        }
    }

    return 0;
}
