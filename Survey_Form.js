document.getElementById("surveyForm").addEventListener("submit", function(event) {
    event.preventDefault(); // Prevent form from refreshing the page

    let name = document.getElementById("name").value.trim();
    let email = document.getElementById("email").value.trim();
    let age = document.getElementById("age").value.trim();
    let feedback = document.getElementById("feedback").value.trim();
    let message = document.getElementById("message");

    // Validation checks
    if (name === "" || email === "" || age === "" || feedback === "") {
        message.style.color = "red";
        message.textContent = "All fields are required!";
        return;
    }

    if (!validateEmail(email)) {
        message.style.color = "red";
        message.textContent = "Invalid email format!";
        return;
    }

    if (age < 10 || age > 100) {
        message.style.color = "red";
        message.textContent = "Age must be between 10 and 100!";
        return;
    }

    // Success message
    message.style.color = "green";
    message.textContent = "Survey submitted successfully!";
    
    // Clear form fields after submission
    document.getElementById("surveyForm").reset();
});

// Email validation function
function validateEmail(email) {
    let emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailPattern.test(email);
}
