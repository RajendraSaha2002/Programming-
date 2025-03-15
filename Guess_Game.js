// Generate a random number between 1 and 100
let randomNumber = Math.floor(Math.random() * 100) + 1;
let attempts = 0;

function checkGuess() {
    let userGuess = document.getElementById("guessInput").value;
    let message = document.getElementById("message");
    let attemptsDisplay = document.getElementById("attempts");

    // Convert input to a number
    userGuess = Number(userGuess);

    if (userGuess < 1 || userGuess > 100 || isNaN(userGuess)) {
        message.textContent = "Please enter a valid number between 1 and 100!";
        return;
    }

    attempts++;

    if (userGuess === randomNumber) {
        message.textContent = `🎉 Congratulations! You guessed the number in ${attempts} attempts.`;
        message.style.color = "green";
        document.getElementById("restartBtn").style.display = "block";
    } else if (userGuess > randomNumber) {
        message.textContent = "📉 Too high! Try again.";
        message.style.color = "red";
    } else {
        message.textContent = "📈 Too low! Try again.";
        message.style.color = "red";
    }

    attemptsDisplay.textContent = `Attempts: ${attempts}`;
}

function restartGame() {
    randomNumber = Math.floor(Math.random() * 100) + 1;
    attempts = 0;
    document.getElementById("message").textContent = "";
    document.getElementById("attempts").textContent = "";
    document.getElementById("guessInput").value = "";
    document.getElementById("restartBtn").style.display = "none";
}
