#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <limits> // Required for numeric_limits

// --- Data Structures ---

struct Car {
    std::string plateNumber;
    std::string make;
    std::string model;
    double pricePerDay;
    bool isAvailable;
};

// --- Function Prototypes ---

/**
 * @brief Loads car data from the "cars.txt" file into a vector.
 * @return A vector of Car objects.
 */
std::vector<Car> loadCars();

/**
 * @brief Saves the current list of cars to the "cars.txt" file.
 * @param cars The vector of cars to save.
 */
void saveCars(const std::vector<Car>& cars);

/**
 * @brief Displays all available cars to the user.
 * @param cars The vector of cars.
 */
void displayAvailableCars(const std::vector<Car>& cars);

/**
 * @brief Handles the process of a customer renting a car.
 * @param cars A reference to the vector of cars to be updated.
 */
void rentCar(std::vector<Car>& cars);

/**
 * @brief Handles the process of a customer returning a car.
 * @param cars A reference to the vector of cars to be updated.
 */
void returnCar(std::vector<Car>& cars);

/**
 * @brief The main function to run the Car Rental System.
 */
int main() {
    std::vector<Car> cars = loadCars();
    int choice;

    // --- Create a default car list if the file doesn't exist ---
    if (cars.empty()) {
        cars = {
            {"WB01AB1234", "Toyota", "Camry", 50.0, true},
            {"WB02CD5678", "Honda", "Civic", 45.0, true},
            {"WB03EF9012", "Ford", "Mustang", 80.0, true},
            {"WB04GH3456", "Maruti", "Swift", 30.0, true},
            {"WB05IJ7890", "Hyundai", "i20", 35.0, true}
        };
        saveCars(cars); // Save the initial list
    }


    do {
        std::cout << "\n--- Car Rental System Menu ---" << std::endl;
        std::cout << "1. View Available Cars" << std::endl;
        std::cout << "2. Rent a Car" << std::endl;
        std::cout << "3. Return a Car" << std::endl;
        std::cout << "4. Exit" << std::endl;
        std::cout << "------------------------------" << std::endl;
        std::cout << "Enter your choice: ";
        
        std::cin >> choice;

        // --- Input validation ---
        if (std::cin.fail()) {
            std::cout << "Invalid input. Please enter a number." << std::endl;
            std::cin.clear();
            std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
            continue;
        }
        
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n'); // Consume the rest of the line

        switch (choice) {
            case 1:
                displayAvailableCars(cars);
                break;
            case 2:
                rentCar(cars);
                break;
            case 3:
                returnCar(cars);
                break;
            case 4:
                std::cout << "Thank you for using the Car Rental System. Goodbye!" << std::endl;
                break;
            default:
                std::cout << "Invalid choice. Please try again." << std::endl;
        }
    } while (choice != 4);

    return 0;
}

// --- Function Definitions ---

std::vector<Car> loadCars() {
    std::vector<Car> cars;
    std::ifstream file("cars.txt");
    if (!file.is_open()) {
        // File doesn't exist yet, will be created on first save.
        return cars;
    }

    Car tempCar;
    while (file >> tempCar.plateNumber >> tempCar.make >> tempCar.model >> tempCar.pricePerDay >> tempCar.isAvailable) {
        cars.push_back(tempCar);
    }

    file.close();
    return cars;
}

void saveCars(const std::vector<Car>& cars) {
    std::ofstream file("cars.txt");
    if (!file.is_open()) {
        std::cout << "Error: Could not open file to save car data." << std::endl;
        return;
    }

    for (const auto& car : cars) {
        file << car.plateNumber << " " << car.make << " " << car.model << " " << car.pricePerDay << " " << car.isAvailable << std::endl;
    }

    file.close();
}

void displayAvailableCars(const std::vector<Car>& cars) {
    std::cout << "\n--- Available Cars for Rent ---" << std::endl;
    bool anyAvailable = false;
    for (const auto& car : cars) {
        if (car.isAvailable) {
            std::cout << "Plate Number: " << car.plateNumber
                      << ", Make: " << car.make
                      << ", Model: " << car.model
                      << ", Price per day: $" << car.pricePerDay << std::endl;
            anyAvailable = true;
        }
    }
    if (!anyAvailable) {
        std::cout << "Sorry, no cars are available for rent at the moment." << std::endl;
    }
}

void rentCar(std::vector<Car>& cars) {
    std::string plateNumber;
    std::cout << "\n--- Rent a Car ---" << std::endl;
    displayAvailableCars(cars);
    std::cout << "\nEnter the plate number of the car you want to rent: ";
    std::getline(std::cin, plateNumber);

    bool carFound = false;
    for (auto& car : cars) {
        if (car.plateNumber == plateNumber && car.isAvailable) {
            car.isAvailable = false;
            saveCars(cars); // Update the file
            std::cout << "You have successfully rented the " << car.make << " " << car.model << "." << std::endl;
            std::cout << "Please return it on time." << std::endl;
            carFound = true;
            break;
        }
    }

    if (!carFound) {
        std::cout << "Error: Car not found or is not available. Please check the plate number." << std::endl;
    }
}

void returnCar(std::vector<Car>& cars) {
    std::string plateNumber;
    int rentalDays;

    std::cout << "\n--- Return a Car ---" << std::endl;
    std::cout << "Enter the plate number of the car you are returning: ";
    std::getline(std::cin, plateNumber);

    bool carFound = false;
    for (auto& car : cars) {
        if (car.plateNumber == plateNumber && !car.isAvailable) {
            std::cout << "Enter the number of days you rented the car: ";
            std::cin >> rentalDays;
            
            if (std::cin.fail() || rentalDays <= 0) {
                std::cout << "Invalid number of days." << std::endl;
                std::cin.clear();
                std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
                return;
            }
            std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');


            double totalCost = rentalDays * car.pricePerDay;
            std::cout << "Thank you for returning the " << car.make << " " << car.model << "." << std::endl;
            std::cout << "Your total rental cost is: $" << totalCost << std::endl;

            car.isAvailable = true;
            saveCars(cars); // Update the file
            carFound = true;
            break;
        }
    }

    if (!carFound) {
        std::cout << "Error: Car not found or it was not rented out. Please check the plate number." << std::endl;
    }
}
