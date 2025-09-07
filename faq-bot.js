(async function () {
  const messages = document.getElementById('messages');
  const form = document.getElementById('form');
  const input = document.getElementById('input');

  const kb = await fetch('./faq.json').then(r => r.json());

  function addMessage(text, who='bot') {
    const div = document.createElement('div');
    div.className = `msg ${who}`;
    div.textContent = text;
    messages.appendChild(div);
    messages.scrollTop = messages.scrollHeight;
  }

  function score(query, entry) {
    // simple keyword overlap scoring
    const q = query.toLowerCase().split(/\W+/).filter(Boolean);
    const text = (entry.q + ' ' + entry.a).toLowerCase();
    let s = 0;
    for (const w of q) if (text.includes(w)) s++;
    return s;
  }

  function answer(query) {
    let best = null, bestScore = -1;
    for (const e of kb) {
      const s = score(query, e);
      if (s > bestScore) { best = e; bestScore = s; }
    }
    if (!best || bestScore < 1) {
      return "I couldn't find that in my notes. Try asking about karma, dharma, detachment, or yoga.";
    }
    return best.a;
  }

  addMessage("Hi! I answer from a small local knowledge base. Ask a question.");
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const t = input.value.trim();
    if (!t) return;
    addMessage(t, 'user');
    input.value = '';
    setTimeout(() => addMessage(answer(t), 'bot'), 150);
  });
})();