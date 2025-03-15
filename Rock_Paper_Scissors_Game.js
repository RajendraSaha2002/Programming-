function playGame(userChoice) {
    const choices = ["rock", "paper", "scissors"];
    const computerChoice = choices[Math.floor(Math.random() * 3)];

    let result = "";

    if (userChoice === computerChoice) {
        result = "It's a Draw! 🤝";
    } else if (
        (userChoice === "rock" && computerChoice === "scissors") ||
        (userChoice === "paper" && computerChoice === "rock") ||
        (userChoice === "scissors" && computerChoice === "paper")
    ) {
        result = "You Win! 🎉";
    } else {
        result = "Computer Wins! 😢";
    }

    document.getElementById("result").textContent = result;
    document.getElementById("userChoice").textContent = `You chose: ${userChoice}`;
    document.getElementById("computerChoice").textContent = `Computer chose: ${computerChoice}`;
}
