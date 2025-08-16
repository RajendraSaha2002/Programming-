// Offline Notes (PWA) — script.js
// Features:
// - IndexedDB storage for notes (id, title, body, updatedAt)
// - Create / edit / delete notes, search, autosave with debounce
// - Service worker registration and online/offline indicator
// - "beforeinstallprompt" handling for install prompt

(function () {
  // ---------- IndexedDB small wrapper ----------
  const DB_NAME = 'offline-notes-db';
  const DB_VERSION = 1;
  const STORE = 'notes';

  function openDB() {
    return new Promise((resolve, reject) => {
      const req = indexedDB.open(DB_NAME, DB_VERSION);
      req.onupgradeneeded = (e) => {
        const db = e.target.result;
        if (!db.objectStoreNames.contains(STORE)) {
          const os = db.createObjectStore(STORE, { keyPath: 'id' });
          os.createIndex('updatedAt', 'updatedAt', { unique: false });
        }
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  function idbGetAll(db) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE, 'readonly');
      const store = tx.objectStore(STORE);
      const req = store.getAll();
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  function idbPut(db, note) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE, 'readwrite');
      const store = tx.objectStore(STORE);
      const req = store.put(note);
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }

  function idbDelete(db, id) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE, 'readwrite');
      const store = tx.objectStore(STORE);
      const req = store.delete(id);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }

  // ---------- UI elements ----------
  const newBtn = document.getElementById('new-note');
  const installBtn = document.getElementById('install-btn');
  const statusEl = document.getElementById('status');
  const notesList = document.getElementById('notes-list');
  const searchInput = document.getElementById('search');

  const titleInput = document.getElementById('note-title');
  const bodyInput = document.getElementById('note-body');
  const saveBtn = document.getElementById('save-note');
  const deleteBtn = document.getElementById('delete-note');
  const noteUpdated = document.getElementById('note-updated');

  let db;
  let notes = []; // local cache
  let currentId = null;
  let debouncedSaveTimer = null;
  const AUTOSAVE_MS = 700;

  // ---------- helpers ----------
  function uid() { return Date.now().toString(36) + '-' + Math.random().toString(36).slice(2,8); }
  function formatDate(ts) { return new Date(ts).toLocaleString(); }
  function setStatus(online) {
    if (online) {
      statusEl.textContent = 'Online';
      statusEl.classList.remove('offline'); statusEl.classList.add('online');
    } else {
      statusEl.textContent = 'Offline';
      statusEl.classList.remove('online'); statusEl.classList.add('offline');
    }
  }
  function renderNotes(list) {
    notesList.innerHTML = '';
    if (!list.length) {
      const li = document.createElement('li');
      li.className = 'note-item';
      li.textContent = 'No notes yet. Click "New" to create one.';
      notesList.appendChild(li);
      return;
    }
    // sort by updatedAt desc (newest first)
    list.sort((a,b) => b.updatedAt - a.updatedAt);
    for (const n of list) {
      const li = document.createElement('li');
      li.className = 'note-item';
      li.dataset.id = n.id;
      const t = document.createElement('div');
      t.className = 't';
      t.textContent = n.title || '(Untitled)';
      const m = document.createElement('div');
      m.className = 'meta';
      m.textContent = formatDate(n.updatedAt || n.createdAt || 0);
      li.appendChild(t);
      li.appendChild(m);
      li.addEventListener('click', () => { openNote(n.id); });
      notesList.appendChild(li);
    }
  }

  function refreshList() {
    // apply search filter
    const q = (searchInput.value || '').trim().toLowerCase();
    const filtered = q ? notes.filter(n => (n.title + ' ' + n.body).toLowerCase().includes(q)) : notes.slice();
    renderNotes(filtered);
  }

  // ---------- note operations ----------
  async function createNote() {
    const id = uid();
    const now = Date.now();
    const note = { id, title: '', body: '', createdAt: now, updatedAt: now };
    notes.unshift(note);
    await idbPut(db, note);
    currentId = id;
    renderEditor(note);
    refreshList();
  }

  async function openNote(id) {
    const note = notes.find(n => n.id === id);
    if (!note) return;
    currentId = id;
    renderEditor(note);
  }

  function renderEditor(note) {
    titleInput.value = note.title || '';
    bodyInput.value = note.body || '';
    deleteBtn.hidden = false;
    noteUpdated.textContent = 'Saved ' + formatDate(note.updatedAt || note.createdAt);
  }

  async function saveCurrentNote() {
    if (!currentId) return;
    const note = notes.find(n => n.id === currentId);
    if (!note) return;
    note.title = titleInput.value;
    note.body = bodyInput.value;
    note.updatedAt = Date.now();
    await idbPut(db, note);
    noteUpdated.textContent = 'Saved ' + formatDate(note.updatedAt);
    refreshList();
  }

  function scheduleAutosave() {
    clearTimeout(debouncedSaveTimer);
    debouncedSaveTimer = setTimeout(() => {
      saveCurrentNote().catch(console.warn);
    }, AUTOSAVE_MS);
  }

  async function deleteCurrentNote() {
    if (!currentId) return;
    if (!confirm('Delete this note?')) return;
    await idbDelete(db, currentId);
    notes = notes.filter(n => n.id !== currentId);
    currentId = null;
    titleInput.value = '';
    bodyInput.value = '';
    deleteBtn.hidden = true;
    noteUpdated.textContent = 'Not saved';
    refreshList();
  }

  // ---------- initialization ----------
  async function initDBAndLoad() {
    db = await openDB();
    notes = await idbGetAll(db);
    refreshList();
    // open first note if exists
    if (notes.length) {
      openNote(notes[0].id);
    } else {
      // empty editor
      deleteBtn.hidden = true;
      noteUpdated.textContent = 'Not saved';
    }
  }

  // ---------- service worker & install prompt ----------
  let deferredPrompt = null;
  window.addEventListener('beforeinstallprompt', (e) => {
    // Prevent automatic prompt
    e.preventDefault();
    deferredPrompt = e;
    installBtn.hidden = false;
  });

  installBtn.addEventListener('click', async () => {
    installBtn.hidden = true;
    if (!deferredPrompt) return;
    deferredPrompt.prompt();
    const choice = await deferredPrompt.userChoice;
    if (choice.outcome === 'accepted') {
      console.log('User accepted install');
    } else {
      console.log('User dismissed install');
    }
    deferredPrompt = null;
  });

  // Register service worker
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('service-worker.js').then(reg => {
      console.log('SW registered', reg.scope);
    }).catch(err => console.warn('SW register failed', err));
  }

  // online/offline indicator
  window.addEventListener('online', () => setStatus(true));
  window.addEventListener('offline', () => setStatus(false));
  setStatus(navigator.onLine);

  // ---------- events ----------
  newBtn.addEventListener('click', async () => {
    await createNote();
    titleInput.focus();
  });

  saveBtn.addEventListener('click', () => {
    saveCurrentNote().catch(console.warn);
  });

  deleteBtn.addEventListener('click', () => {
    deleteCurrentNote().catch(console.warn);
  });

  titleInput.addEventListener('input', scheduleAutosave);
  bodyInput.addEventListener('input', scheduleAutosave);
  searchInput.addEventListener('input', () => refreshList());

  // keyboard shortcuts: Ctrl/Cmd+N new note, Ctrl/Cmd+S save
  window.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 's') {
      e.preventDefault();
      saveCurrentNote().catch(console.warn);
    }
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'n') {
      e.preventDefault();
      createNote();
    }
  });

  // load DB
  initDBAndLoad().catch(err => console.error(err));

  // expose for debugging
  window.pwaNotes = {
    createNote, saveCurrentNote, deleteCurrentNote,
    list: () => notes.slice(),
  };
})();