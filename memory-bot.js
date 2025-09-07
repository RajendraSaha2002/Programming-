(function () {
  const messagesEl = document.getElementById('messages');
  const form = document.getElementById('form');
  const input = document.getElementById('input');

  // Very simple "memory" store
  const memory = {
    name: null,
    likes: new Set(),
    dislikes: new Set(),
    lastTopics: []
  };

  function addMessage(text, who='bot') {
    const d = document.createElement('div');
    d.className = `msg ${who}`;
    d.textContent = text;
    messagesEl.appendChild(d);
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }

  function rememberTopic(t) {
    memory.lastTopics.push(t);
    if (memory.lastTopics.length > 5) memory.lastTopics.shift();
  }

  function extractFacts(t) {
    const mName = t.match(/i am (\w+)|my name is (\w+)/i);
    if (mName) memory.name = (mName[1] || mName[2] || '').trim();

    const like = t.match(/i (really )?like ([\w\s]+)/i);
    if (like) {
      memory.likes.add(like[2].trim().toLowerCase());
    }
    const dislike = t.match(/i (really )?dislike ([\w\s]+)/i);
    if (dislike) {
      memory.dislikes.add(dislike[2].trim().toLowerCase());
    }
  }

  function replyTo(t) {
    extractFacts(t);
    rememberTopic(t);

    const lower = t.toLowerCase();
    if (/your name|who are you/.test(lower)) {
      return "I'm a small memory bot. I remember a few things you tell me.";
    }
    if (/what do you remember|what do i like/.test(lower)) {
      const likes = [...memory.likes].slice(0,3).join(', ') || 'nothing yet';
      const dislikes = [...memory.dislikes].slice(0,3).join(', ') || 'nothing yet';
      const topics = memory.lastTopics.slice(-3).join(' | ') || 'no prior topics';
      return `I remember: likes = ${likes}; dislikes = ${dislikes}; recent topics = ${topics}.` +
             (memory.name ? ` Also, your name is ${memory.name}.` : '');
    }
    // Personalized greeting
    if (!memory.name && /^(hi|hello|hey)\b/i.test(lower)) {
      return "Hi! What's your name?";
    }
    if (memory.name && /^(hi|hello|hey)\b/i.test(lower)) {
      return `Hello ${memory.name}! What would you like to talk about today?`;
    }
    // Light preference mirroring
    for (const like of memory.likes) {
      if (lower.includes(like)) return `Ah yes, you like ${like}. Tell me what you enjoy most about it.`;
    }

    // Default reflective response
    return "Got it. Tell me more—what makes this important to you?";
  }

  addMessage("Hello! I'm Memory Bot. Tell me your name or say what you like/dislike.");
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const t = input.value.trim();
    if (!t) return;
    addMessage(t, 'user');
    input.value = '';
    setTimeout(() => addMessage(replyTo(t), 'bot'), 180);
  });
})();