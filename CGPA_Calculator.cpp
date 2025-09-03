#include <iostream>
#include <vector>
#include <string>

// Function to get a valid integer input from the user
int get_valid_int_input(const std::string& prompt) {
    int value;
    while (true) {
        std::cout << prompt;
        std::cin >> value;

        // Check for invalid input (e.g., non-numeric)
        if (std::cin.fail()) {
            std::cout << "Invalid input. Please enter a number.\n";
            std::cin.clear();
            std::cin.ignore(256, '\n');
        } else {
            std::cin.ignore(256, '\n'); // Clear the buffer
            return value;
        }
    }
}

// Function to get a valid floating-point input from the user
double get_valid_double_input(const std::string& prompt) {
    double value;
    while (true) {
        std::cout << prompt;
        std::cin >> value;

        // Check for invalid input (e.g., non-numeric)
        if (std::cin.fail()) {
            std::cout << "Invalid input. Please enter a number.\n";
            std::cin.clear();
            std::cin.ignore(256, '\n');
        } else {
            std::cin.ignore(256, '\n'); // Clear the buffer
            return value;
        }
    }
}

int main() {
    // Introduction to the user
    std::cout << "----------------------------\n";
    std::cout << "   CGPA Calculator\n";
    std::cout << "----------------------------\n";

    // Get the total number of subjects from the user
    int numSubjects = get_valid_int_input("Enter the number of subjects: ");

    // Variables to store the total weighted grade points and total credit hours
    double totalGradePoints = 0.0;
    double totalCredits = 0.0;

    // Loop through each subject to get its grade and credits
    for (int i = 1; i <= numSubjects; ++i) {
        std::cout << "\n--- Subject " << i << " ---\n";

        // Get the grade point for the current subject
        double gradePoint = get_valid_double_input("Enter grade point (e.g., 4.0 for A, 3.7 for A-): ");

        // Get the credit hours for the current subject
        double creditHours = get_valid_double_input("Enter credit hours: ");

        // Calculate the weighted grade point for this subject
        totalGradePoints += gradePoint * creditHours;

        // Add the credit hours to the total
        totalCredits += creditHours;
    }

    // Calculate the CGPA if totalCredits is not zero to avoid division by zero error
    if (totalCredits > 0) {
        double cgpa = totalGradePoints / totalCredits;
        std::cout.precision(2); // Set precision to 2 decimal places
        std::cout << "\n----------------------------\n";
        std::cout << "Your calculated CGPA is: " << std::fixed << cgpa << "\n";
        std::cout << "----------------------------\n";
    } else {
        std::cout << "\nNo subjects entered. CGPA cannot be calculated.\n";
    }

    return 0;
}
