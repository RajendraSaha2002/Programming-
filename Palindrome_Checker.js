function checkPalindrome() {
    let text = document.getElementById("textInput").value.toLowerCase().replace(/[^a-z0-9]/g, '');
    let reversedText = text.split('').reverse().join('');

    if (text === "") {
        document.getElementById("result").textContent = "Please enter a word or phrase!";
        return;
    }

    if (text === reversedText) {
        document.getElementById("result").textContent = `"${document.getElementById("textInput").value}" is a Palindrome! ✅`;
        document.getElementById("result").style.color = "green";
    } else {
        document.getElementById("result").textContent = `"${document.getElementById("textInput").value}" is NOT a Palindrome! ❌`;
        document.getElementById("result").style.color = "red";
    }
}
