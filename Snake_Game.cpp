#include <iostream>
#include <vector>
#include <conio.h>    // For _kbhit() and _getch() on Windows
#include <windows.h>  // For Sleep() and console functions on Windows

// --- Global Game Settings & Variables ---

bool gameOver;
const int width = 40;  // Width of the game area
const int height = 20; // Height of the game area
int x, y;              // Snake head coordinates
int fruitX, fruitY;    // Fruit coordinates
int score;
std::vector<int> tailX, tailY; // Snake tail coordinates
int nTail;             // Length of the tail

// Enum for managing player direction
enum eDirection { STOP = 0, LEFT, RIGHT, UP, DOWN };
eDirection dir;

// --- Function Prototypes ---

/**
 * @brief Sets up the initial state of the game.
 */
void Setup();

/**
 * @brief Draws the game board, snake, and fruit to the console.
 */
void Draw();

/**
 * @brief Handles user keyboard input for controlling the snake.
 */
void Input();

/**
 * @brief Updates the game state, including snake movement and collision detection.
 */
void Logic();

/**
 * @brief The main function to run the Snake game.
 */
int main() {
    Setup();
    while (!gameOver) {
        Draw();
        Input();
        Logic();
        Sleep(100); // Slows down the game speed
    }
    return 0;
}

// --- Function Definitions ---

void Setup() {
    gameOver = false;
    dir = STOP;
    x = width / 2;
    y = height / 2;
    fruitX = rand() % width;
    fruitY = rand() % height;
    score = 0;
    nTail = 0;
    tailX.clear();
    tailY.clear();
}

void Draw() {
    // Clear the console screen (Windows specific)
    system("cls"); 

    // Draw the top border
    for (int i = 0; i < width + 2; i++)
        std::cout << "#";
    std::cout << std::endl;

    for (int i = 0; i < height; i++) {
        for (int j = 0; j < width; j++) {
            if (j == 0)
                std::cout << "#"; // Left border

            if (i == y && j == x)
                std::cout << "O"; // Snake head
            else if (i == fruitY && j == fruitX)
                std::cout << "F"; // Fruit
            else {
                bool printTail = false;
                for (int k = 0; k < nTail; k++) {
                    if (tailX[k] == j && tailY[k] == i) {
                        std::cout << "o"; // Snake tail
                        printTail = true;
                    }
                }
                if (!printTail)
                    std::cout << " ";
            }

            if (j == width - 1)
                std::cout << "#"; // Right border
        }
        std::cout << std::endl;
    }

    // Draw the bottom border
    for (int i = 0; i < width + 2; i++)
        std::cout << "#";
    std::cout << std::endl;

    // Display the score
    std::cout << "Score:" << score << std::endl;
}

void Input() {
    // Check if a key has been pressed (Windows specific)
    if (_kbhit()) {
        switch (_getch()) { // Get the character of the pressed key
            case 'a':
                if (dir != RIGHT) dir = LEFT;
                break;
            case 'd':
                if (dir != LEFT) dir = RIGHT;
                break;
            case 'w':
                if (dir != DOWN) dir = UP;
                break;
            case 's':
                if (dir != UP) dir = DOWN;
                break;
            case 'x':
                gameOver = true;
                break;
        }
    }
}

void Logic() {
    // --- Update tail positions ---
    int prevX = tailX.empty() ? x : tailX[0];
    int prevY = tailY.empty() ? y : tailY[0];
    int prev2X, prev2Y;
    if (!tailX.empty()) {
        tailX[0] = x;
        tailY[0] = y;
    } else if (nTail > 0) { // First segment of tail
        tailX.push_back(x);
        tailY.push_back(y);
    }

    for (int i = 1; i < nTail; i++) {
        prev2X = tailX[i];
        prev2Y = tailY[i];
        tailX[i] = prevX;
        tailY[i] = prevY;
        prevX = prev2X;
        prevY = prev2Y;
    }

    // --- Update head position based on direction ---
    switch (dir) {
        case LEFT:
            x--;
            break;
        case RIGHT:
            x++;
            break;
        case UP:
            y--;
            break;
        case DOWN:
            y++;
            break;
        default:
            break;
    }

    // --- Collision Detection ---

    // Wall collision
    if (x >= width || x < 0 || y >= height || y < 0) {
        gameOver = true;
        std::cout << "\n--- Game Over! You hit the wall. ---" << std::endl;
        std::cout << "Final Score: " << score << std::endl;
    }

    // Self collision
    for (int i = 0; i < nTail; i++) {
        if (tailX[i] == x && tailY[i] == y) {
            gameOver = true;
            std::cout << "\n--- Game Over! You bit your own tail. ---" << std::endl;
            std::cout << "Final Score: " << score << std::endl;
        }
    }

    // Fruit collision
    if (x == fruitX && y == fruitY) {
        score += 10;
        fruitX = rand() % width;
        fruitY = rand() % height;
        nTail++;
        // Add a new tail segment at the current head position
        if (nTail > tailX.size()) {
             tailX.push_back(x);
             tailY.push_back(y);
        }
    }
}
