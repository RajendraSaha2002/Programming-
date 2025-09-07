document.addEventListener('DOMContentLoaded', () => {
  // Elements
  const usernameInput = document.getElementById('username');
  const nativeLangInput = document.getElementById('nativeLang');
  const targetLangSelect = document.getElementById('targetLang');
  const levelSelect = document.getElementById('level');
  const modeSelect = document.getElementById('mode');
  const countSelect = document.getElementById('count');

  const toggleInputBtn = document.getElementById('toggleInput');
  const toggleTTSBtn = document.getElementById('toggleTTS');
  const textInputContainer = document.getElementById('textInputContainer');
  const micInputContainer = document.getElementById('micInputContainer');
  const answerBox = document.getElementById('answerBox');
  const startListeningBtn = document.getElementById('startListening');
  const spokenTextElement = document.getElementById('spokenText');
  const listeningIndicator = document.getElementById('listeningIndicator');

  const startBtn = document.getElementById('startBtn');
  const checkBtn = document.getElementById('checkBtn');
  const nextBtn = document.getElementById('nextBtn');

  const loadingIndicator = document.getElementById('loadingIndicator');
  const responseContainer = document.getElementById('responseContainer');
  const promptEl = document.getElementById('prompt');
  const responseMessage = document.getElementById('responseMessage');
  const choicesContainer = document.getElementById('choicesContainer');
  const progressEl = document.getElementById('progress');

  const downloadBtn = document.getElementById('downloadBtn');
  const copyBtn = document.getElementById('copyBtn');

  // State
  let DB = null;
  let session = null;
  let isUsingMicrophone = false;
  let recognition = null;
  let speakPrompt = true;
  let lastResults = [];

  // Load DB
  async function loadDB() {
    if (DB) return DB;
    try {
      const r = await fetch('data/language_db.json');
      DB = await r.json();
      return DB;
    } catch (e) {
      console.error('Failed to load language DB', e);
      DB = { languages: {} };
      return DB;
    }
  }

  // Mic
  if ('webkitSpeechRecognition' in window) {
    recognition = new webkitSpeechRecognition();
    recognition.continuous = true;
    recognition.lang = 'en-US'; // will switch per language on start
    recognition.onresult = (e) => {
      const result = e.results[e.results.length - 1];
      const transcript = result[0].transcript;
      spokenTextElement.textContent = `"${transcript}"`;
      answerBox.value = transcript;
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

  toggleTTSBtn.addEventListener('click', () => {
    speakPrompt = !speakPrompt;
    toggleTTSBtn.textContent = speakPrompt ? 'Speak Prompt: ON' : 'Speak Prompt: OFF';
    if (!speakPrompt && 'speechSynthesis' in window) speechSynthesis.cancel();
  });

  startListeningBtn.addEventListener('click', () => {
    if (!recognition) return;
    spokenTextElement.textContent = '"Listening..."';
    listeningIndicator.classList.remove('hidden');
    // switch recognition language toward target if possible
    const langMeta = getLangMeta(targetLangSelect.value);
    recognition.lang = langMeta?.speechCode || 'en-US';
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
    startBtn.disabled = !!show;
    checkBtn.disabled = !!show;
    nextBtn.disabled = !!show;
  }

  function say(text, langCode) {
    if (!speakPrompt || !('speechSynthesis' in window)) return;
    const u = new SpeechSynthesisUtterance(text);
    u.lang = langCode || 'en-US';
    u.rate = 1; u.pitch = 1; u.volume = 1;
    speechSynthesis.speak(u);
  }

  function getLangMeta(key) {
    const meta = {
      spanish: { code: 'es', speechCode: 'es-ES', name: 'Spanish' },
      hindi:   { code: 'hi', speechCode: 'hi-IN', name: 'Hindi' },
      french:  { code: 'fr', speechCode: 'fr-FR', name: 'French' },
      german:  { code: 'de', speechCode: 'de-DE', name: 'German' }
    };
    return meta[key];
  }

  // Normalize strings for comparison (strip accents, punctuation, leading articles, case)
  function normalize(s, langKey) {
    if (!s) return '';
    let out = s.toLowerCase().trim();
    out = out.normalize('NFD').replace(/[\u0300-\u036f]/g, ''); // strip accents
    out = out.replace(/[.,!?;:'"()]/g, ' ');
    out = out.replace(/\s+/g, ' ').trim();
    // strip common articles
    if (langKey === 'spanish' || langKey === 'french') {
      out = out.replace(/^(el|la|los|las|un|una|le|la|les|un|une|des)\s+/, '');
    }
    if (langKey === 'german') {
      out = out.replace(/^(der|die|das|ein|eine)\s+/, '');
    }
    return out;
  }

  function similar(a, b) {
    // quick len tolerant cmp
    a = a.trim(); b = b.trim();
    if (!a || !b) return false;
    if (a === b) return true;
    if (a.includes(b) || b.includes(a)) return true;
    // allow small edit distance for typos
    return levenshtein(a, b) <= Math.max(1, Math.floor(Math.min(a.length, b.length) / 6));
  }

  function levenshtein(a, b) {
    const m = a.length, n = b.length;
    const dp = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
    for (let i = 0; i <= m; i++) dp[i][0] = i;
    for (let j = 0; j <= n; j++) dp[0][j] = j;
    for (let i = 1; i <= m; i++) {
      for (let j = 1; j <= n; j++) {
        const cost = a[i - 1] === b[j - 1] ? 0 : 1;
        dp[i][j] = Math.min(
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost
        );
      }
    }
    return dp[m][n];
  }

  // Session and question building
  function pickN(arr, n) {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a.slice(0, n);
  }

  function buildQuestions(dbLang, mode, count, level, langKey) {
    const qs = [];
    const vocab = dbLang.vocab || [];
    const phrases = dbLang.phrases || [];
    const fills = dbLang.fill || [];
    const pool = { vocab, phrases, fills };

    const toNative = mode === 'toNative';
    const toTarget = mode === 'toTarget';
    const mcq = mode === 'mcq';
    const flash = mode === 'flashcards';
    const fill = mode === 'fill';
    const convo = mode === 'conversation';

    const max = Math.min(count, 50);
    if (flash || toNative || toTarget || mcq) {
      const base = pickN(vocab, max);
      base.forEach(v => {
        if (flash) {
          qs.push({
            type: 'flash',
            prompt: `Flashcard: ${v.native} → ? (${dbLang.name})`,
            speak: v.target,
            correct: [v.target, ...(v.alts || [])],
            extras: v.roman ? `(${v.roman})` : '',
            langKey
          });
        } else if (toTarget) {
          qs.push({
            type: 'input',
            prompt: `Translate to ${dbLang.name}: ${v.native}`,
            speak: v.native, speakLang: 'en-US',
            correct: [v.target, ...(v.alts || [])],
            show: `Expected: ${v.target}${v.roman ? ` (${v.roman})` : ''}`,
            langKey
          });
        } else if (toNative) {
          qs.push({
            type: 'input',
            prompt: `Translate to your native language: ${v.target}`,
            speak: v.target,
            correct: [v.native, ...(v.nativeAlts || [])],
            show: `Expected: ${v.native}`,
            compareLang: 'native',
            langKey
          });
        } else if (mcq) {
          // 1 correct + 3 distractors
          const distract = pickN(vocab.filter(x => x !== v), 3).map(x => x.target);
          const options = pickN([v.target, ...distract], 4);
          qs.push({
            type: 'mcq',
            prompt: `Pick the ${dbLang.name} word for: ${v.native}`,
            options,
            correct: [v.target],
            speak: v.native, speakLang: 'en-US',
            langKey
          });
        }
      });
    }

    if (fill) {
      const base = pickN(fills, max);
      base.forEach(f => {
        qs.push({
          type: 'input',
          prompt: `Fill in the blank: ${f.sentence}${f.hint ? ` (hint: ${f.hint})` : ''}`,
          correct: [f.answer, ...(f.alts || [])],
          show: `Answer: ${f.answer}${f.roman ? ` (${f.roman})` : ''}`,
          speak: f.speak || f.sentence.replace('___', '...'),
          langKey
        });
      });
    }

    if (convo) {
      const base = pickN(phrases, Math.min(max, phrases.length || 5));
      base.forEach(p => {
        qs.push({
          type: 'input',
          prompt: `Reply naturally to: "${p.target}" (${p.native})`,
          correct: p.accept || [],
          show: `One way: ${p.target}${p.roman ? ` (${p.roman})` : ''}`,
          speak: p.target,
          freeform: true,
          langKey
        });
      });
    }

    return qs.slice(0, count);
  }

  function beginSession() {
    responseMessage.textContent = '';
    choicesContainer.innerHTML = '';
    promptEl.textContent = '';
    lastResults = [];

    const name = usernameInput.value.trim();
    const nativeLang = nativeLangInput.value.trim();
    const langKey = targetLangSelect.value;
    const level = levelSelect.value;
    const mode = modeSelect.value;
    const count = parseInt(countSelect.value, 10);

    if (!name || !nativeLang) {
      alert('Please enter your name and native language.');
      return;
    }
    const dbLang = DB.languages[langKey];
    if (!dbLang) {
      alert('Selected language data not available.');
      return;
    }
    dbLang.name = dbLang.name || (getLangMeta(langKey)?.name || langKey);

    const questions = buildQuestions(dbLang, mode, count, level, langKey);
    if (!questions.length) {
      alert('Not enough data for this mode. Try another mode or language.');
      return;
    }

    session = {
      name, nativeLang, langKey, level, mode, count,
      idx: 0,
      correct: 0,
      questions
    };

    responseContainer.classList.remove('hidden');
    renderCurrentQuestion();
    startBtn.disabled = true;
    checkBtn.disabled = false;
    nextBtn.disabled = true;
  }

  function renderChoices(q) {
    choicesContainer.innerHTML = '';
    if (q.type !== 'mcq') return;
    const wrap = document.createElement('div');
    wrap.style.display = 'grid';
    wrap.style.gridTemplateColumns = 'repeat(auto-fit,minmax(120px,1fr))';
    wrap.style.gap = '8px';
    q.options.forEach(opt => {
      const b = document.createElement('button');
      b.textContent = opt;
      b.style.padding = '10px';
      b.onclick = () => {
        // select as answer
        answerBox.value = opt;
      };
      wrap.appendChild(b);
    });
    choicesContainer.appendChild(wrap);
  }

  function renderCurrentQuestion() {
    if (!session) return;
    const q = session.questions[session.idx];
    promptEl.textContent = q.prompt;
    renderChoices(q);
    answerBox.value = '';
    responseMessage.textContent = '';
    progressEl.textContent = `Question ${session.idx + 1} of ${session.count} | Score: ${session.correct}`;
    // Speak prompt
    const langMeta = getLangMeta(session.langKey);
    const speakLang = q.speakLang || langMeta?.speechCode || 'en-US';
    if (q.speak) say(q.speak, speakLang);
  }

  function checkAnswer() {
    if (!session) return;
    const q = session.questions[session.idx];
    const raw = answerBox.value.trim();
    const ans = raw || (spokenTextElement.textContent || '').replace(/(^"|"$)/g, '').trim();

    // For flashcards, just reveal
    if (q.type === 'flash') {
      responseMessage.textContent = `Answer: ${q.correct[0]} ${q.extras || ''}`;
      nextBtn.disabled = false;
      checkBtn.disabled = true;
      lastResults.push({ prompt: q.prompt, your: '(viewed)', correct: q.correct[0], ok: true });
      return;
    }

    if (!ans && !q.freeform) {
      alert('Please provide an answer (type or speak).');
      return;
    }

    let ok = false;
    if (q.freeform) {
      // Freeform: accept anything non-empty, optionally match some keywords
      ok = !!ans;
    } else {
      const normUser = normalize(ans, q.compareLang === 'native' ? 'english' : session.langKey);
      for (const c of q.correct) {
        const normC = normalize(c, session.langKey);
        if (similar(normUser, normC)) { ok = true; break; }
      }
    }

    if (ok) {
      session.correct += 1;
      responseMessage.textContent = '✅ Correct!';
    } else {
      responseMessage.textContent = `❌ Not quite. ${q.show ? q.show : `Expected: ${q.correct[0]}`}`;
    }
    lastResults.push({ prompt: q.prompt, your: ans || '(blank)', correct: q.correct[0], ok });
    progressEl.textContent = `Question ${session.idx + 1} of ${session.count} | Score: ${session.correct}`;
    checkBtn.disabled = true;
    nextBtn.disabled = false;
  }

  function nextQuestion() {
    if (!session) return;
    if (session.idx < session.count - 1) {
      session.idx += 1;
      renderCurrentQuestion();
      nextBtn.disabled = true;
      checkBtn.disabled = false;
    } else {
      // Finished
      const pct = Math.round((session.correct / session.count) * 100);
      responseMessage.textContent = `Session complete! Score: ${session.correct}/${session.count} (${pct}%).`;
      promptEl.textContent = 'Great work! Review your answers below or start a new session.';
      checkBtn.disabled = true;
      nextBtn.disabled = true;
      startBtn.disabled = false;
    }
  }

  function downloadSession() {
    const lines = [];
    lines.push(`Name: ${session?.name || ''}`);
    lines.push(`Native: ${session?.nativeLang || ''}`);
    lines.push(`Target: ${session ? getLangMeta(session.langKey)?.name : ''}`);
    lines.push(`Mode: ${session?.mode || ''}`);
    lines.push(`Score: ${session?.correct || 0}/${session?.count || 0}`);
    lines.push('');
    lastResults.forEach((r, i) => {
      lines.push(`Q${i + 1}: ${r.prompt}`);
      lines.push(`Your: ${r.your}`);
      lines.push(`Correct: ${r.correct}`);
      lines.push(`Result: ${r.ok ? 'Correct' : 'Wrong'}`);
      lines.push('');
    });
    const blob = new Blob([lines.join('\n')], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = 'language_tutor_session.txt';
    document.body.appendChild(a); a.click(); a.remove();
    URL.revokeObjectURL(url);
  }

  async function copyResults() {
    try {
      const text = responseContainer.innerText || '';
      await navigator.clipboard.writeText(text);
      alert('Copied session to clipboard!');
    } catch {
      alert('Copy failed. Select and copy manually.');
    }
  }

  // Wire up
  startBtn.addEventListener('click', async () => {
    showLoading(true);
    try {
      await loadDB();
      beginSession();
    } finally {
      showLoading(false);
    }
  });
  checkBtn.addEventListener('click', checkAnswer);
  nextBtn.addEventListener('click', nextQuestion);
  downloadBtn.addEventListener('click', downloadSession);
  copyBtn.addEventListener('click', copyResults);
});