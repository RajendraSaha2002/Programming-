#include <iostream>
#include <vector>

// --- Function Prototypes ---

/**
 * @brief Displays the Tic-Tac-Toe board.
 * * @param board A 2D vector representing the game board.
 */
void drawBoard(const std::vector<std::vector<char>>& board);

/**
 * @brief Checks if a player has won the game.
 * * @param board The game board.
 * @param player The character representing the player ('X' or 'O').
 * @return true if the player has won, false otherwise.
 */
bool checkWin(const std::vector<std::vector<char>>& board, char player);

/**
 * @brief Checks if the game is a draw (all cells are filled).
 * * @param board The game board.
 * @return true if the game is a draw, false otherwise.
 */
bool checkDraw(const std::vector<std::vector<char>>& board);

/**
 * @brief The main function to run the Tic-Tac-Toe game.
 */
int main() {
    // Initialize the game board with numbers 1-9
    std::vector<std::vector<char>> board = {
        {'1', '2', '3'},
        {'4', '5', '6'},
        {'7', '8', '9'}
    };
    
    char currentPlayer = 'X';
    int choice;
    bool game_over = false;

    std::cout << "--- Welcome to Tic-Tac-Toe! ---" << std::endl;
    std::cout << "Player 1 is 'X' and Player 2 is 'O'." << std::endl;
    std::cout << "Enter a number from 1 to 9 to make your move." << std::endl;
    std::cout << std::endl;


    // Main game loop
    while (!game_over) {
        // Display the board
        drawBoard(board);

        // Get the current player's move
        std::cout << "Player " << currentPlayer << ", enter your move (1-9): ";
        std::cin >> choice;

        // Convert the choice (1-9) to board coordinates (0-2)
        int row = (choice - 1) / 3;
        int col = (choice - 1) % 3;

        // Check if the chosen cell is valid and not already taken
        if (choice >= 1 && choice <= 9 && board[row][col] != 'X' && board[row][col] != 'O') {
            // Place the player's mark on the board
            board[row][col] = currentPlayer;

            // Check for a win
            if (checkWin(board, currentPlayer)) {
                drawBoard(board);
                std::cout << std::endl << "Congratulations! Player " << currentPlayer << " wins!" << std::endl;
                game_over = true;
            } 
            // Check for a draw
            else if (checkDraw(board)) {
                drawBoard(board);
                std::cout << std::endl << "It's a draw!" << std::endl;
                game_over = true;
            } 
            // Switch to the other player
            else {
                currentPlayer = (currentPlayer == 'X') ? 'O' : 'X';
            }
        } else {
            // Handle invalid input
            std::cout << "Invalid move. Please try again." << std::endl;
            // Clear the input buffer in case of non-integer input
            std::cin.clear();
            std::cin.ignore(10000, '\n');
        }
    }

    std::cout << "--- Game Over! Thanks for playing. ---" << std::endl;

    return 0;
}


// --- Function Definitions ---

void drawBoard(const std::vector<std::vector<char>>& board) {
    std::cout << std::endl;
    std::cout << "     |     |     " << std::endl;
    std::cout << "  " << board[0][0] << "  |  " << board[0][1] << "  |  " << board[0][2] << "  " << std::endl;
    std::cout << "_____|_____|_____" << std::endl;
    std::cout << "     |     |     " << std::endl;
    std::cout << "  " << board[1][0] << "  |  " << board[1][1] << "  |  " << board[1][2] << "  " << std::endl;
    std::cout << "_____|_____|_____" << std::endl;
    std::cout << "     |     |     " << std::endl;
    std::cout << "  " << board[2][0] << "  |  " << board[2][1] << "  |  " << board[2][2] << "  " << std::endl;
    std::cout << "     |     |     " << std::endl;
    std::cout << std::endl;
}

bool checkWin(const std::vector<std::vector<char>>& board, char player) {
    // Check rows for a win
    for (int i = 0; i < 3; ++i) {
        if (board[i][0] == player && board[i][1] == player && board[i][2] == player) {
            return true;
        }
    }

    // Check columns for a win
    for (int i = 0; i < 3; ++i) {
        if (board[0][i] == player && board[1][i] == player && board[2][i] == player) {
            return true;
        }
    }

    // Check diagonals for a win
    if (board[0][0] == player && board[1][1] == player && board[2][2] == player) {
        return true;
    }
    if (board[0][2] == player && board[1][1] == player && board[2][0] == player) {
        return true;
    }

    return false;
}

bool checkDraw(const std::vector<std::vector<char>>& board) {
    // Check if any cell is still empty (contains a number)
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            if (board[i][j] != 'X' && board[i][j] != 'O') {
                return false; // Game is not a draw yet
            }
        }
    }
    // If all cells are filled, it's a draw
    return true;
}
