const sentences = [
    "The quick brown fox jumps over the lazy dog.",
    "Coding is fun when you understand the logic.",
    "Practice makes a person perfect in typing.",
    "JavaScript is a versatile programming language."
];

let currentSentence = "";
let startTime, endTime;

function startTest() {
    currentSentence = sentences[Math.floor(Math.random() * sentences.length)];
    document.getElementById("sentence").textContent = currentSentence;
    document.getElementById("inputField").value = "";
    document.getElementById("result").textContent = "";
    startTime = null;
}

document.getElementById("inputField").addEventListener("input", function() {
    if (!startTime) startTime = new Date();

    const typedText = this.value;
    if (typedText === currentSentence) {
        endTime = new Date();
        calculateSpeed();
    }
});

function calculateSpeed() {
    let timeTaken = (endTime - startTime) / 1000; // Convert to seconds
    let wordsTyped = currentSentence.split(" ").length;
    let speed = Math.round((wordsTyped / timeTaken) * 60);

    document.getElementById("result").textContent = `Typing Speed: ${speed} WPM`;
}

// Initialize test on page load
startTest();
