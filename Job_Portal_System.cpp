#include <iostream>
#include <vector>
#include <string>
#include <limits>

// A class to represent a Job listing
class Job {
public:
    std::string title;
    std::string company;
    std::string location;
    std::string description;

    Job(std::string t, std::string c, std::string l, std::string d)
        : title(t), company(c), location(l), description(d) {}

    // Function to display the job details
    void display() const {
        std::cout << "\n-----------------------------------" << std::endl;
        std::cout << "Job Title: " << title << std::endl;
        std::cout << "Company:   " << company << std::endl;
        std::cout << "Location:  " << location << std::endl;
        std::cout << "-----------------------------------" << std::endl;
        std::cout << "Description:\n" << description << std::endl;
        std::cout << "-----------------------------------" << std::endl;
    }
};

// Function to display the main menu options
void displayMenu() {
    std::cout << "\n--- Job Portal System ---" << std::endl;
    std::cout << "1. View All Job Listings" << std::endl;
    std::cout << "2. Post a New Job" << std::endl;
    std::cout << "3. Exit" << std::endl;
    std::cout << "-------------------------" << std::endl;
    std::cout << "Enter your choice: ";
}

// Function to clear the input buffer to prevent issues with std::getline
void clearInputBuffer() {
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
}

int main() {
    // A vector to store all job listings
    std::vector<Job> jobs;

    // Add some initial dummy data
    jobs.push_back(Job("Software Engineer", "Tech Solutions Inc.", "New York, NY", "Seeking a skilled software engineer with 3+ years of experience in C++."));
    jobs.push_back(Job("Product Manager", "Innovate Corp.", "San Francisco, CA", "Looking for a product manager to lead our new mobile app development."));

    int choice;
    do {
        displayMenu();
        std::cin >> choice;

        if (std::cin.fail()) {
            std::cout << "Invalid input. Please enter a number." << std::endl;
            std::cin.clear();
            clearInputBuffer();
            continue;
        }

        clearInputBuffer();

        switch (choice) {
            case 1: {
                std::cout << "\n--- All Job Listings ---" << std::endl;
                if (jobs.empty()) {
                    std::cout << "No jobs available at the moment." << std::endl;
                } else {
                    for (const auto& job : jobs) {
                        job.display();
                    }
                }
                break;
            }
            case 2: {
                std::cout << "\n--- Post a New Job ---" << std::endl;
                std::string title, company, location, description;

                std::cout << "Enter Job Title: ";
                std::getline(std::cin, title);

                std::cout << "Enter Company Name: ";
                std::getline(std::cin, company);

                std::cout << "Enter Location: ";
                std::getline(std::cin, location);

                std::cout << "Enter Job Description (end with a blank line):" << std::endl;
                std::string line;
                while (std::getline(std::cin, line) && !line.empty()) {
                    description += line + "\n";
                }
                
                jobs.push_back(Job(title, company, location, description));
                std::cout << "Job posted successfully!" << std::endl;
                break;
            }
            case 3: {
                std::cout << "\nExiting system. Goodbye!" << std::endl;
                break;
            }
            default: {
                std::cout << "Invalid choice. Please try again." << std::endl;
                break;
            }
        }
    } while (choice != 3);

    return 0;
}
