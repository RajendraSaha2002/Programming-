#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <limits> // Required for numeric_limits

// --- Function Prototypes ---

/**
 * @brief Displays the current content of the text buffer.
 * @param buffer The vector of strings representing the file content.
 * @param filename The name of the file being edited.
 */
void displayBuffer(const std::vector<std::string>& buffer, const std::string& filename);

/**
 * @brief Loads the content of a file into the text buffer.
 * @param filename The name of the file to load.
 * @param buffer A reference to the vector of strings to be filled.
 */
void loadFile(const std::string& filename, std::vector<std::string>& buffer);

/**
 * @brief Saves the content of the text buffer to a file.
 * @param filename The name of the file to save to.
 * @param buffer The vector of strings to be saved.
 */
void saveFile(const std::string& filename, const std::vector<std::string>& buffer);

/**
 * @brief The main function to run the text editor.
 */
int main() {
    std::string filename;
    std::vector<std::string> buffer;

    std::cout << "--- Simple Console Text Editor ---" << std::endl;
    std::cout << "Enter the filename to open or create (e.g., mydocument.txt): ";
    std::getline(std::cin, filename);

    // Load the file if it exists
    loadFile(filename, buffer);

    std::cout << "\n--- Editing: " << filename << " ---" << std::endl;
    std::cout << "Type text and press Enter to add a new line." << std::endl;
    std::cout << "Type ':wq' on a new line and press Enter to save and quit." << std::endl;
    std::cout << "------------------------------------------" << std::endl;

    std::string line;
    while (true) {
        displayBuffer(buffer, filename);
        std::cout << "> "; // Prompt for new line
        std::getline(std::cin, line);

        if (line == ":wq") {
            break; // Exit the editing loop
        }

        buffer.push_back(line);
    }

    // Save the file and exit
    saveFile(filename, buffer);
    std::cout << "\nFile saved successfully. Goodbye!" << std::endl;

    return 0;
}

// --- Function Definitions ---

void displayBuffer(const std::vector<std::string>& buffer, const std::string& filename) {
    // Clear the console screen (platform-specific)
    #ifdef _WIN32
        system("cls");
    #else
        system("clear"); // For Linux/macOS
    #endif

    std::cout << "--- Editing: " << filename << " --- (Type ':wq' to save and quit)" << std::endl;
    std::cout << "----------------------------------------------------------------" << std::endl;
    
    // Display the content with line numbers
    for (size_t i = 0; i < buffer.size(); ++i) {
        std::cout << i + 1 << " | " << buffer[i] << std::endl;
    }
    std::cout << "----------------------------------------------------------------" << std::endl;
}

void loadFile(const std::string& filename, std::vector<std::string>& buffer) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cout << "\nFile '" << filename << "' not found. A new file will be created upon saving." << std::endl;
        return;
    }

    std::string line;
    while (std::getline(file, line)) {
        buffer.push_back(line);
    }

    file.close();
    std::cout << "\nSuccessfully loaded '" << filename << "'." << std::endl;
}

void saveFile(const std::string& filename, const std::vector<std::string>& buffer) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file '" << filename << "' for writing." << std::endl;
        return;
    }

    for (const auto& line : buffer) {
        file << line << std::endl;
    }

    file.close();
}
