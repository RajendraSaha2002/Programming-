#include <iostream>
#include <vector>
#include <string>
#include <limits>

// A simple class to represent a Movie
class Movie {
public:
    std::string title;
    std::string showtime;
    int availableSeats;

    Movie(std::string t, std::string s, int seats)
        : title(t), showtime(s), availableSeats(seats) {}

    // Function to display movie information
    void display() const {
        std::cout << "  - " << title << " (" << showtime << ") - Available Seats: " << availableSeats << std::endl;
    }
};

// A class to represent a Ticket reservation
class Ticket {
public:
    std::string movieTitle;
    std::string name;
    int numberOfTickets;

    Ticket(std::string m, std::string n, int num)
        : movieTitle(m), name(n), numberOfTickets(num) {}

    // Function to display ticket information
    void display() const {
        std::cout << "  - Movie: " << movieTitle << ", Tickets: " << numberOfTickets << ", Booked by: " << name << std::endl;
    }
};

// Function to display the main menu
void displayMenu() {
    std::cout << "\n--- Ticket Reservation System ---" << std::endl;
    std::cout << "1. View Available Movies" << std::endl;
    std::cout << "2. Book a Ticket" << std::endl;
    std::cout << "3. View My Booked Tickets" << std::endl;
    std::cout << "4. Exit" << std::endl;
    std::cout << "-------------------------------" << std::endl;
    std::cout << "Enter your choice: ";
}

// Function to clear the input buffer to prevent issues with std::getline
void clearInputBuffer() {
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
}

int main() {
    // A vector to hold our available movies. We'll start with a few predefined ones.
    std::vector<Movie> movies = {
        Movie("Dune: Part Two", "10:00 AM", 50),
        Movie("Oppenheimer", "01:30 PM", 45),
        Movie("Inception", "05:00 PM", 60)
    };

    // A vector to store all the tickets that have been booked.
    std::vector<Ticket> bookedTickets;

    int choice;
    do {
        displayMenu();
        std::cin >> choice;

        // Check for invalid input (e.g., a letter instead of a number)
        if (std::cin.fail()) {
            std::cout << "Invalid input. Please enter a number." << std::endl;
            std::cin.clear(); // Clear the error flag
            clearInputBuffer();
            continue;
        }

        clearInputBuffer(); // Clear the newline character from the buffer

        switch (choice) {
            case 1: {
                std::cout << "\n--- Available Movies ---" << std::endl;
                for (const auto& movie : movies) {
                    movie.display();
                }
                break;
            }
            case 2: {
                std::cout << "\n--- Book a Ticket ---" << std::endl;
                std::cout << "Enter the movie title you want to book: ";
                std::string movieTitle;
                std::getline(std::cin, movieTitle);

                bool found = false;
                for (auto& movie : movies) {
                    if (movie.title == movieTitle) {
                        found = true;
                        std::cout << "How many tickets do you want to book? ";
                        int numTickets;
                        std::cin >> numTickets;

                        if (std::cin.fail() || numTickets <= 0) {
                            std::cout << "Invalid number of tickets." << std::endl;
                            std::cin.clear();
                            clearInputBuffer();
                        } else if (numTickets <= movie.availableSeats) {
                            std::cout << "Enter your name: ";
                            std::string name;
                            clearInputBuffer();
                            std::getline(std::cin, name);

                            movie.availableSeats -= numTickets;
                            bookedTickets.push_back(Ticket(movieTitle, name, numTickets));
                            std::cout << "Booking successful! Enjoy the movie." << std::endl;
                        } else {
                            std::cout << "Not enough seats available for this movie." << std::endl;
                        }
                        break;
                    }
                }
                if (!found) {
                    std::cout << "Movie not found. Please check the title and try again." << std::endl;
                }
                break;
            }
            case 3: {
                std::cout << "\n--- My Booked Tickets ---" << std::endl;
                if (bookedTickets.empty()) {
                    std::cout << "You have no tickets booked yet." << std::endl;
                } else {
                    for (const auto& ticket : bookedTickets) {
                        ticket.display();
                    }
                }
                break;
            }
            case 4: {
                std::cout << "\nExiting system. Goodbye!" << std::endl;
                break;
            }
            default: {
                std::cout << "Invalid choice. Please try again." << std::endl;
                break;
            }
        }
    } while (choice != 4);

    return 0;
}
