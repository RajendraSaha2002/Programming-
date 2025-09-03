#include <iostream>
#include <string>
#include <cstdlib>
#include <ctime>
#include <limits>

// Function to get the computer's choice
std::string getComputerChoice() {
    int move = rand() % 3;
    if (move == 0) {
        return "rock";
    } else if (move == 1) {
        return "paper";
    } else {
        return "scissors";
    }
}

// Function to determine the winner
std::string determineWinner(std::string playerChoice, std::string computerChoice) {
    if (playerChoice == computerChoice) {
        return "tie";
    }
    if ((playerChoice == "rock" && computerChoice == "scissors") ||
        (playerChoice == "paper" && computerChoice == "rock") ||
        (playerChoice == "scissors" && computerChoice == "paper")) {
        return "player";
    }
    return "computer";
}

int main() {
    // Seed the random number generator
    srand(static_cast<unsigned int>(time(0)));

    int playerScore = 0;
    int computerScore = 0;
    std::string playerChoice;

    std::cout << "Welcome to Rock, Paper, Scissors!" << std::endl;

    while (true) {
        std::cout << "\nEnter your choice (rock, paper, scissors) or 'quit' to exit: ";
        std::cin >> playerChoice;

        if (playerChoice == "quit") {
            break;
        }

        if (playerChoice != "rock" && playerChoice != "paper" && playerChoice != "scissors") {
            std::cout << "Invalid choice. Please try again." << std::endl;
            continue;
        }

        std::string computerChoice = getComputerChoice();
        std::cout << "Computer chose: " << computerChoice << std::endl;

        std::string winner = determineWinner(playerChoice, computerChoice);

        if (winner == "player") {
            playerScore++;
            std::cout << "You win this round!" << std::endl;
        } else if (winner == "computer") {
            computerScore++;
            std::cout << "Computer wins this round!" << std::endl;
        } else {
            std::cout << "It's a tie!" << std::endl;
        }

        std::cout << "Score: Player " << playerScore << " - " << "Computer " << computerScore << std::endl;
    }

    std::cout << "\nFinal Score: Player " << playerScore << " - " << "Computer " << computerScore << std::endl;
    std::cout << "Thanks for playing!" << std::endl;

    return 0;
}
