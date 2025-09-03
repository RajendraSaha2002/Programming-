#include <iostream>
#include <cmath>
#include <iomanip>

int main() {
    double num1, num2, result;
    char operation;
    bool running = true;

    // Set output precision for the results
    std::cout << std::fixed << std::setprecision(4);

    while (running) {
        // Display the menu of operations to the user
        std::cout << "\n-------------------------------------\n";
        std::cout << "   C++ Scientific Calculator\n";
        std::cout << "-------------------------------------\n";
        std::cout << "Available Operations:\n";
        std::cout << "+ (Addition)\n";
        std::cout << "- (Subtraction)\n";
        std::cout << "* (Multiplication)\n";
        std::cout << "/ (Division)\n";
        std::cout << "s (Sine)\n";
        std::cout << "c (Cosine)\n";
        std::cout << "t (Tangent)\n";
        std::cout << "q (Square Root)\n";
        std::cout << "p (Power)\n";
        std::cout << "l (Logarithm, base e)\n";
        std::cout << "x (Exit)\n";
        std::cout << "-------------------------------------\n";

        // Prompt the user for their choice
        std::cout << "Enter your choice: ";
        std::cin >> operation;

        // Use a switch statement to handle different operations
        switch (operation) {
            case '+':
                std::cout << "Enter first number: ";
                std::cin >> num1;
                std::cout << "Enter second number: ";
                std::cin >> num2;
                result = num1 + num2;
                std::cout << "Result: " << result << std::endl;
                break;

            case '-':
                std::cout << "Enter first number: ";
                std::cin >> num1;
                std::cout << "Enter second number: ";
                std::cin >> num2;
                result = num1 - num2;
                std::cout << "Result: " << result << std::endl;
                break;

            case '*':
                std::cout << "Enter first number: ";
                std::cin >> num1;
                std::cout << "Enter second number: ";
                std::cin >> num2;
                result = num1 * num2;
                std::cout << "Result: " << result << std::endl;
                break;

            case '/':
                std::cout << "Enter first number: ";
                std::cin >> num1;
                std::cout << "Enter second number: ";
                std::cin >> num2;
                if (num2 != 0) {
                    result = num1 / num2;
                    std::cout << "Result: " << result << std::endl;
                } else {
                    std::cout << "Error! Division by zero is not allowed.\n";
                }
                break;

            case 's': // Sine
                std::cout << "Enter an angle in radians: ";
                std::cin >> num1;
                result = sin(num1);
                std::cout << "Result: " << result << std::endl;
                break;
            
            case 'c': // Cosine
                std::cout << "Enter an angle in radians: ";
                std::cin >> num1;
                result = cos(num1);
                std::cout << "Result: " << result << std::endl;
                break;

            case 't': // Tangent
                std::cout << "Enter an angle in radians: ";
                std::cin >> num1;
                result = tan(num1);
                std::cout << "Result: " << result << std::endl;
                break;

            case 'q': // Square Root
                std::cout << "Enter a number: ";
                std::cin >> num1;
                if (num1 >= 0) {
                    result = sqrt(num1);
                    std::cout << "Result: " << result << std::endl;
                } else {
                    std::cout << "Error! Cannot calculate the square root of a negative number.\n";
                }
                break;

            case 'p': // Power
                std::cout << "Enter the base number: ";
                std::cin >> num1;
                std::cout << "Enter the exponent: ";
                std::cin >> num2;
                result = pow(num1, num2);
                std::cout << "Result: " << result << std::endl;
                break;

            case 'l': // Natural Logarithm
                std::cout << "Enter a number: ";
                std::cin >> num1;
                if (num1 > 0) {
                    result = log(num1);
                    std::cout << "Result: " << result << std::endl;
                } else {
                    std::cout << "Error! Cannot calculate the natural logarithm of a non-positive number.\n";
                }
                break;

            case 'x': // Exit
                running = false;
                std::cout << "Exiting the calculator. Goodbye!\n";
                break;

            default:
                std::cout << "Invalid operation. Please try again.\n";
                // Clear the input buffer to prevent infinite loops on bad input
                std::cin.clear();
                std::cin.ignore(256, '\n');
                break;
        }
    }

    return 0;
}
