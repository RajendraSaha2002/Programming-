document.addEventListener('DOMContentLoaded', function() {
    // DOM Elements
    const questionForm = document.getElementById('questionForm');
    const usernameInput = document.getElementById('username');
    const languageInput = document.getElementById('language');
    const apiKey = "AIzaSyCGBgvJkTM2-DiKgt_jyLTwUi2QIEiG5fE";
    const textMessage = document.getElementById('textMessage');
    const toggleInputBtn = document.getElementById('toggleInput');
    const textInputContainer = document.getElementById('textInputContainer');
    const micInputContainer = document.getElementById('micInputContainer');
    const startListeningBtn = document.getElementById('startListening');
    const spokenTextElement = document.getElementById('spokenText');
    const listeningIndicator = document.getElementById('listeningIndicator');
    const responseContainer = document.getElementById('responseContainer');
    const responseMessage = document.getElementById('responseMessage');
    const loadingIndicator = document.getElementById('loadingIndicator');
    const backgroundMusic = document.getElementById('backgroundMusic');
    const submitBtn = document.getElementById('submitBtn');

    // State variables
    let isUsingMicrophone = false;
    let spokenText = '';
    let recognition = null;

    // Initialize speech recognition if available
    if ('webkitSpeechRecognition' in window) {
        recognition = new webkitSpeechRecognition();
        recognition.continuous = true;
        recognition.lang = 'en-US';

        recognition.onresult = function(event) {
            const result = event.results[event.results.length - 1];
            const transcript = result[0].transcript;
            spokenText = transcript;
            spokenTextElement.textContent = `"${spokenText}"`;
            stopListening();
        };

        recognition.onend = function() {
            listeningIndicator.classList.add('hidden');
        };
    } else {
        // If speech recognition is not supported, hide the microphone option
        toggleInputBtn.style.display = 'none';
    }

    // Toggle between text and microphone input
    toggleInputBtn.addEventListener('click', function() {
        isUsingMicrophone = !isUsingMicrophone;
        
        if (isUsingMicrophone) {
            textInputContainer.classList.add('hidden');
            micInputContainer.classList.remove('hidden');
            toggleInputBtn.textContent = 'Switch to Text Input';
        } else {
            textInputContainer.classList.remove('hidden');
            micInputContainer.classList.add('hidden');
            toggleInputBtn.textContent = 'Switch to Microphone Input';
            stopListening();
        }
    });

    // Start listening for speech
    startListeningBtn.addEventListener('click', function() {
        if (recognition) {
            spokenText = '';
            spokenTextElement.textContent = '"Listening..."';
            listeningIndicator.classList.remove('hidden');
            recognition.start();
        }
    });

    // Stop listening for speech
    function stopListening() {
        if (recognition) {
            recognition.stop();
            listeningIndicator.classList.add('hidden');
        }
    }

    // Form submission
    questionForm.addEventListener('submit', async function(e) {
        e.preventDefault();
        
        const username = usernameInput.value.trim();
        const language = languageInput.value.trim();
        const message = isUsingMicrophone ? spokenText : textMessage.value.trim();
        
        if (!username || !language) {
            alert('Please fill in all fields');
            return;
        }
        
        if (!message) {
            alert('Please enter your message or speak using the microphone');
            return;
        }
        
        // Show loading indicator
        loadingIndicator.classList.remove('hidden');
        submitBtn.disabled = true;
        
        try {
            const response = await fetchGuidance(username, message, language);
            displayResponse(response);
            
            // Play background music
            backgroundMusic.play().catch(error => {
                console.log('Auto-play prevented:', error);
            });
        } catch (error) {
            console.error('Error:', error);
            alert('Failed to get guidance. Please try again later.');
        } finally {
            loadingIndicator.classList.add('hidden');
            submitBtn.disabled = false;
        }
    });

    // Fetch guidance from API
    async function fetchGuidance(username, message, language) {
        try {
            // Show a loading message in the response container
            responseMessage.textContent = "Connecting to Gemini API...";
            responseContainer.classList.remove('hidden');
            
            // Create the request to the Gemini API
            const apiUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';
            
            // Construct the prompt for Gemini API
            const prompt = `Acting as lord Krishna, give a solution to this problem: ${message}. 
                           Give references based on Bhagwat Gita incidents. 
                           Format the output as a letter addressed to ${username}. 
                           Please reply in simple ${language} language, do not use hard to understand words.`;
            
            // Make the API request
            const response = await fetch(`${apiUrl}?key=${apiKey}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    contents: [{
                        role: "user",
                        parts: [{
                            text: prompt
                        }]
                    }]
                })
            });
            
            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                console.error('API Error:', errorData);
                
                if (response.status === 400) {
                    throw new Error('Invalid API request. Please check your API key and try again.');
                } else if (response.status === 401) {
                    throw new Error('Invalid API key. Please check your API key and try again.');
                } else if (response.status === 429) {
                    throw new Error('API rate limit exceeded. Please try again later.');
                } else {
                    throw new Error(`API request failed with status ${response.status}`);
                }
            }
            
            const data = await response.json();
            
            // Extract the response text from the Gemini API response
            if (data.candidates && data.candidates[0] && data.candidates[0].content && 
                data.candidates[0].content.parts && data.candidates[0].content.parts[0]) {
                return data.candidates[0].content.parts[0].text;
            } else {
                throw new Error('Unexpected API response format');
            }
        } catch (error) {
            console.error('Error calling Gemini API:', error);
            
            // Show error to user
            alert(`Error: ${error.message}`);
            
            // Fallback to local response if API fails
            return generateFallbackResponse(username, message, language);
        }
    }

    // Generate a fallback response if the API call fails
    function generateFallbackResponse(username, message, language) {
        const lowerMessage = message.toLowerCase();
        let response = '';
        
        // Simple keyword matching for demonstration purposes
        if (lowerMessage.includes('anxiety') || lowerMessage.includes('worry') || lowerMessage.includes('stress')) {
            response = `Dear ${username},\n\nI understand your concerns about anxiety and worry. In the Bhagavad Gita, I taught Arjuna: "For him who has conquered the mind, the mind is the best of friends; but for one who has failed to do so, his mind will remain the greatest enemy." (Chapter 6, Verse 6)\n\nWorry comes from attachment to outcomes. Remember that you are entitled to perform your prescribed duties, but you are not entitled to the fruits of your actions. Never consider yourself to be the cause of the results of your activities, and never be attached to not doing your duty. (Chapter 2, Verse 47)\n\nFocus on the present moment and your duty (dharma) without excessive concern for the results. This detachment is not indifference, but a higher understanding of your true nature.\n\nYours always,\nLord Krishna`;
        } 
        else if (lowerMessage.includes('purpose') || lowerMessage.includes('meaning') || lowerMessage.includes('direction')) {
            response = `Dear ${username},\n\nYou seek purpose and meaning in life. This is a noble pursuit. In the Bhagavad Gita, I explain that each person has their own dharma (duty/purpose) based on their natural qualities and station in life.\n\n"It is better to perform one's own duties imperfectly than to master the duties of another. By fulfilling the obligations born of one's nature, a person never incurs sin." (Chapter 18, Verse 47)\n\nDiscover your natural talents and use them in service to others. When you align your actions with dharma and perform them with devotion, you will find fulfillment.\n\nRemember: "Whatever action a great man performs, common men follow. And whatever standards he sets by exemplary acts, all the world pursues." (Chapter 3, Verse 21)\n\nYours eternally,\nLord Krishna`;
        }
        else if (lowerMessage.includes('fear') || lowerMessage.includes('courage') || lowerMessage.includes('brave')) {
            response = `Dear ${username},\n\nI see that fear troubles you. When Arjuna faced the battlefield at Kurukshetra, he too was overcome with fear and doubt.\n\nI told him: "The wise neither grieve for the living nor for the dead." (Chapter 2, Verse 11)\n\nFear arises when we identify with the temporary body rather than the eternal soul. "For the soul there is neither birth nor death at any time. He has not come into being, does not come into being, and will not come into being. He is unborn, eternal, ever-existing, and primeval. He is not slain when the body is slain." (Chapter 2, Verse 20)\n\nFace your challenges with the knowledge that you are more than your physical form and temporary circumstances. True courage comes from this understanding.\n\nWith you always,\nLord Krishna`;
        }
        else {
            response = `Dear ${username},\n\nI have heard your question with an open heart. In the Bhagavad Gita, I taught that wisdom comes to those who seek with sincerity and devotion.\n\n"Just as a lamp in a windless place does not flicker, so the disciplined mind of a yogi remains steady in meditation on the self." (Chapter 6, Verse 19)\n\nRemember that you are not this temporary body, but the eternal soul within. "The soul can never be cut to pieces by any weapon, nor burned by fire, nor moistened by water, nor withered by the wind." (Chapter 2, Verse 23)\n\nApproach life's challenges with equanimity, performing your duties without attachment to results. "Perform your duty equipoised, abandoning all attachment to success or failure. Such equanimity is called yoga." (Chapter 2, Verse 48)\n\nMay you find peace and clarity on your path.\n\nEternally yours,\nLord Krishna`;
        }
        
        return response;
    }

    // Display the response
    function displayResponse(response) {
        responseMessage.textContent = response;
        responseContainer.classList.remove('hidden');
        
        // Scroll to the response
        responseContainer.scrollIntoView({ behavior: 'smooth' });
    }
});