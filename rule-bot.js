(function () {
  const messages = document.getElementById('messages');
  const form = document.getElementById('form');
  const input = document.getElementById('input');

  const rules = [
    { re: /(hello|hi|namaste)/i, reply: "Namaste! How can I help you today?" },
    { re: /(stress|anxiety|worry)/i, reply: "Focus on the present and your duty. Detach from outcomes, peace will follow." },
    { re: /(purpose|meaning|direction)/i, reply: "Act according to your dharma—use your nature in service." },
    { re: /(fear|courage|brave)/i, reply: "Courage comes when you remember your true self is eternal." }
  ];

  function addMessage(text, who='bot') {
    const div = document.createElement('div');
    div.className = `msg ${who}`;
    div.textContent = text;
    messages.appendChild(div);
    messages.scrollTop = messages.scrollHeight;
  }

  function replyTo(userText) {
    for (const r of rules) {
      if (r.re.test(userText)) return r.reply;
    }
    return "I hear you. Tell me more so I can guide you better.";
  }

  addMessage("Hello! I'm a small rule-based bot. Try 'stress', 'purpose', or 'fear'.");
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const t = input.value.trim();
    if (!t) return;
    addMessage(t, 'user');
    input.value = '';
    const r = replyTo(t);
    setTimeout(() => addMessage(r, 'bot'), 200);
  });
})();