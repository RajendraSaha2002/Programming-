document.addEventListener('DOMContentLoaded', () => {
  // DOM
  const form = document.getElementById('questionForm');
  const usernameInput = document.getElementById('username');
  const languageInput = document.getElementById('language');
  const conceptSelect = document.getElementById('concept');
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
  const submitBtn = document.getElementById('submitBtn');

  // Concepts -> KB files
  const KB_FILES = {
    stoicism: 'data/stoicism.json',
    cbt: 'data/cbt.json',
    productivity: 'data/productivity.json',
    career: 'data/career.json'
  };

  // Persona styling per concept
  const PERSONAS = {
    stoicism: {
      greeting: (name) => `Greetings ${name},`,
      closing: '— Your Stoic Mentor',
      styleHint: 'Answer with serenity, focusing on what is in our control.'
    },
    cbt: {
      greeting: (name) => `Hi ${name},`,
      closing: '— Your CBT Coach',
      styleHint: 'Be practical and step-by-step. Offer small experiments.'
    },
    productivity: {
      greeting: (name) => `Hey ${name},`,
      closing: '— Your Productivity Mentor',
      styleHint: 'Use GTD/Deep Work ideas; give actionable next steps.'
    },
    career: {
      greeting: (name) => `Hello ${name},`,
      closing: '— Your Career Coach',
      styleHint: 'Be concise and specific. Include examples when possible.'
    }
  };

  // State
  let isUsingMicrophone = false;
  let spokenText = '';
  let recognition = null;
  const kbCache = new Map();

  // Speech recognition
  if ('webkitSpeechRecognition' in window) {
    recognition = new webkitSpeechRecognition();
    recognition.continuous = true;
    recognition.lang = 'en-US';

    recognition.onresult = (event) => {
      const result = event.results[event.results.length - 1];
      const transcript = result[0].transcript;
      spokenText = transcript;
      spokenTextElement.textContent = `"${spokenText}"`;
      stopListening();
    };
    recognition.onend = () => listeningIndicator.classList.add('hidden');
  } else {
    toggleInputBtn.style.display = 'none';
  }

  toggleInputBtn.addEventListener('click', () => {
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

  startListeningBtn.addEventListener('click', () => {
    if (!recognition) return;
    spokenText = '';
    spokenTextElement.textContent = '"Listening..."';
    listeningIndicator.classList.remove('hidden');
    recognition.start();
  });

  function stopListening() {
    if (recognition) {
      recognition.stop();
      listeningIndicator.classList.add('hidden');
    }
  }

  function showLoading(show) {
    loadingIndicator.classList.toggle('hidden', !show);
    submitBtn.disabled = !!show;
  }

  function displayResponse(text) {
    responseMessage.textContent = text;
    responseContainer.classList.remove('hidden');
    responseContainer.scrollIntoView({ behavior: 'smooth' });
  }

  async function loadKB(concept) {
    if (kbCache.has(concept)) return kbCache.get(concept);
    const file = KB_FILES[concept];
    if (!file) return [];
    const data = await fetch(file).then(r => r.json()).catch(() => []);
    kbCache.set(concept, data);
    return data;
  }

  // Simple keyword scoring
  function bestMatchAnswer(kb, query) {
    if (!Array.isArray(kb) || kb.length === 0) return null;
    const q = (query || '').toLowerCase();
    let best = null, scoreBest = -1;

    for (const item of kb) {
      const keys = (item.keywords || []).map(k => k.toLowerCase());
      let s = 0;
      for (const k of keys) if (q.includes(k)) s++;
      // bonus if title keyword appears
      if (item.title && q.includes(item.title.toLowerCase())) s += 1;
      if (s > scoreBest) { scoreBest = s; best = item; }
    }
    // If nothing matches, try "general" fallback
    if (!best || scoreBest <= 0) {
      const general = kb.find(i => i.category === 'general');
      return general || kb[0];
    }
    return best;
  }

  function craftReply(concept, name, language, query, kbItem) {
    const p = PERSONAS[concept] || PERSONAS.stoicism;
    const greeting = p.greeting(name);
    const hint = p.styleHint ? `\n(${p.styleHint})` : '';
    const langNote = language ? `\n[Note: Offline demo; replies are in ${language}.]` : '';
    const title = kbItem?.title ? `\nTopic: ${kbItem.title}` : '';
    const bullets = kbItem?.steps?.length
      ? '\n\nNext steps:\n- ' + kbItem.steps.join('\n- ')
      : '';
    const resources = kbItem?.resources?.length
      ? '\n\nResources:\n- ' + kbItem.resources.join('\n- ')
      : '';

    const body = kbItem?.answer || 'Here are some practical steps to move forward.';
    return [
      greeting,
      hint,
      title,
      '\n\n' + body,
      bullets,
      resources,
      '\n\n' + p.closing,
      langNote
    ].join('');
  }

  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const name = usernameInput.value.trim();
    const language = languageInput.value.trim();
    const concept = conceptSelect.value;
    const message = (isUsingMicrophone ? spokenText : textMessage.value).trim();

    if (!name || !language || !message) {
      alert('Please fill all fields and provide a message.');
      return;
    }

    showLoading(true);
    try {
      const kb = await loadKB(concept);
      const match = bestMatchAnswer(kb, message);
      const reply = craftReply(concept, name, language, message, match);
      displayResponse(reply);
    } catch (err) {
      console.error(err);
      displayResponse('Sorry, I could not process your request. Please try again.');
    } finally {
      showLoading(false);
    }
  });
});