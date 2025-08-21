// Code Playground — Mini REPL
// - Editors: HTML, CSS, JS
// - Run code in a sandboxed iframe (srcdoc), capture console logs & errors
// - Save / load snippets to localStorage, export single HTML
// - Ctrl+Enter to run, simple snippet management

(() => {
  // DOM
  const htmlEl = document.getElementById('html-editor');
  const cssEl = document.getElementById('css-editor');
  const jsEl = document.getElementById('js-editor');
  const runBtn = document.getElementById('run');
  const stopBtn = document.getElementById('stop');
  const preview = document.getElementById('preview');
  const consoleLog = document.getElementById('console-log');
  const saveBtn = document.getElementById('save-snippet');
  const snippetsEl = document.getElementById('snippets');
  const newSnippetBtn = document.getElementById('new-snippet');
  const deleteSnippetBtn = document.getElementById('delete-snippet');
  const exportBtn = document.getElementById('export-html');
  const clearConsoleBtn = document.getElementById('clear-console');

  const STORAGE_KEY = 'codeplay:snippets:v1';

  // Sample starter snippet
  const starter = {
    id: 'starter',
    name: 'Starter',
    html: `<h2>Hello, playground!</h2>\n<p>Edit HTML / CSS / JS and press Run.</p>`,
    css: `body{font-family:system-ui;display:flex;flex-direction:column;gap:8px;padding:20px}\nh2{color:#2563eb}`,
    js: `console.log('Hello from JS');\n// try: alert('demo');\n`
  };

  // state
  let snippets = loadSnippets();
  if (!snippets.length) {
    snippets = [starter];
    persistSnippets();
  }
  let selectedId = snippets[0].id;

  // render snippet list and load selected
  function renderSnippets() {
    snippetsEl.innerHTML = '';
    for (const s of snippets.slice().reverse()) {
      const div = document.createElement('div');
      div.className = 'snippet-item' + (s.id === selectedId ? ' selected' : '');
      div.dataset.id = s.id;
      div.innerHTML = `<div style="min-width:0"><strong style="display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${escape(s.name)}</strong>
        <small style="color:var(--muted)">${new Date(s.createdAt || Date.now()).toLocaleString()}</small>
      </div>
      <div style="display:flex;gap:6px">
        <button title="Load" class="btn muted load">Load</button>
      </div>`;
      snippetsEl.appendChild(div);
      div.querySelector('.load').addEventListener('click', (e) => {
        e.stopPropagation();
        selectedId = s.id;
        loadSnippet(s.id);
        renderSnippets();
      });
      div.addEventListener('click', () => {
        selectedId = s.id;
        renderSnippets();
      });
    }
  }

  function loadSnippet(id) {
    const s = snippets.find(x => x.id === id);
    if (!s) return;
    htmlEl.value = s.html || '';
    cssEl.value = s.css || '';
    jsEl.value = s.js || '';
    selectedId = s.id;
    renderSnippets();
    logInfo(`Loaded snippet: ${s.name}`);
  }

  function persistSnippets() {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(snippets)); } catch (e) { console.warn(e); }
  }

  function loadSnippets() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return [];
      return JSON.parse(raw);
    } catch (e) { return []; }
  }

  function saveSnippet() {
    const name = prompt('Enter snippet name', snippets.find(s => s.id === selectedId)?.name || 'My snippet');
    if (!name) return;
    const id = selectedId || uid();
    const payload = {
      id,
      name,
      html: htmlEl.value,
      css: cssEl.value,
      js: jsEl.value,
      createdAt: Date.now()
    };
    // replace or push
    const idx = snippets.findIndex(s => s.id === id);
    if (idx >= 0) snippets[idx] = payload;
    else snippets.push(payload);
    persistSnippets();
    selectedId = id;
    renderSnippets();
    logInfo(`Saved snippet: ${name}`);
  }

    function newSnippet() {
      const id = uid();
      const blank = {
        id,
        name: 'Untitled',
        html: '',
        css: '',
        js: '',
        createdAt: Date.now()
      };
      snippets.push(blank);
      persistSnippets();
      selectedId = id;
      renderSnippets();
      loadSnippet(id);
    }
  
    // Initialize UI
    renderSnippets();
    loadSnippet(selectedId);
  })();