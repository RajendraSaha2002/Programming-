#include <iostream>
#include <vector>
#include <conio.h>
#include <windows.h>
#include <chrono>
#include <thread>

// Global variables for game state
bool gameOver;
const int width = 20;
const int height = 20;
int x, y, fruitX, fruitY, score;
std::vector<int> tailX, tailY;
int nTail;
enum eDirection { STOP = 0, LEFT, RIGHT, UP, DOWN };
eDirection dir;

// Function to move the cursor to a specific position on the console
void gotoxy(int x, int y) {
    COORD coord;
    coord.X = x;
    coord.Y = y;
    SetConsoleCursorPosition(GetStdHandle(STD_OUTPUT_HANDLE), coord);
}

// Function to initialize the game
void Setup() {
    gameOver = false;
    dir = STOP;
    x = width / 2;
    y = height / 2;
    fruitX = rand() % width;
    fruitY = rand() % height;
    score = 0;
    nTail = 0;
}

// Function to draw the game board and all elements
void Draw() {
    // Clear the console screen
    system("cls");

    // Draw top border
    for (int i = 0; i < width + 2; i++)
        std::cout << "#";
    std::cout << std::endl;

    // Draw game area and side borders
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
                    std::cout << " "; // Empty space
            }

            if (j == width - 1)
                std::cout << "#"; // Right border
        }
        std::cout << std::endl;
    }

    // Draw bottom border
    for (int i = 0; i < width + 2; i++)
        std::cout << "#";
    std::cout << std::endl;

    // Display the score
    std::cout << "Score: " << score << std::endl;
}

// Function to handle user input
void Input() {
    // Check if a key has been pressed
    if (_kbhit()) {
        switch (_getch()) {
            case 'a':
                dir = LEFT;
                break;
            case 'd':
                dir = RIGHT;
                break;
            case 'w':
                dir = UP;
                break;
            case 's':
                dir = DOWN;
                break;
            case 'x':
                gameOver = true;
                break;
        }
    }
}

// Function to update game logic
void Logic() {
    // Store the previous position of the snake's head
    int prevX = tailX[0];
    int prevY = tailY[0];
    int prev2X, prev2Y;
    tailX[0] = x;
    tailY[0] = y;

    // Move the rest of the tail
    for (int i = 1; i < nTail; i++) {
        prev2X = tailX[i];
        prev2Y = tailY[i];
        tailX[i] = prevX;
        tailY[i] = prevY;
        prevX = prev2X;
        prevY = prev2Y;
    }

    // Update the snake's head position based on direction
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

    // Check for collision with walls
    if (x >= width || x < 0 || y >= height || y < 0) {
        gameOver = true;
    }

    // Check for collision with the tail
    for (int i = 0; i < nTail; i++) {
        if (tailX[i] == x && tailY[i] == y) {
            gameOver = true;
        }
    }

    // Check if the snake ate the fruit
    if (x == fruitX && y == fruitY) {
        score += 10;
        fruitX = rand() % width;
        fruitY = rand() % height;
        nTail++;
        tailX.push_back(0);
        tailY.push_back(0);
    }
}

int main() {
    Setup();
    while (!gameOver) {
        Draw();
        Input();
        Logic();
        // Slow down the game loop (using Windows Sleep to avoid std::this_thread issue)
        Sleep(100);
    }
    std::cout << "Game Over!" << std::endl;
    return 0;
}
