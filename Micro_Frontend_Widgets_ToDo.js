// Simple Todo widget (module)
// Exports:
//  - async mount(container, api)  => builds UI inside container
//  - async unmount()              => cleanup
//  - onMessage(msg)               => optional inbound messages from shell

let rootEl = null;
let apiRef = null;
let todos = [];

function saveLocal() {
  try { localStorage.setItem('mf:todo', JSON.stringify(todos)); } catch(e){}
}
function loadLocal() {
  try { todos = JSON.parse(localStorage.getItem('mf:todo') || '[]'); } catch(e){ todos = []; }
}

export async function mount(container, api) {
  apiRef = api;
  rootEl = document.createElement('div');
  rootEl.innerHTML = `
    <div style="display:flex;gap:8px;align-items:center;margin-bottom:8px">
      <input class="tf" placeholder="New todo" />
      <button class="add">Add</button>
      <button class="clear muted">Clear</button>
    </div>
    <ul class="list" style="padding:0;list-style:none;margin:0"></ul>
  `;
  container.appendChild(rootEl);
  loadLocal();
  renderList();

  rootEl.querySelector('.add').addEventListener('click', onAdd);
  rootEl.querySelector('.clear').addEventListener('click', () => {
    if (!confirm('Clear todos?')) return;
    todos = [];
    saveLocal();
    renderList();
    apiRef.emit({ type: 'todo:cleared' });
  });
  rootEl.querySelector('.tf').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') onAdd();
  });

  function onAdd(){
    const input = rootEl.querySelector('.tf');
    const v = (input.value || '').trim();
    if (!v) return;
    todos.unshift({ id: Date.now().toString(36), text: v, done: false });
    input.value = '';
    saveLocal();
    renderList();
    apiRef.emit({ type: 'todo:added', text: v });
  }

  function renderList(){
    const ul = rootEl.querySelector('.list');
    ul.innerHTML = '';
    if (todos.length === 0) {
      const li = document.createElement('li');
      li.className = 'placeholder';
      li.textContent = 'No todos yet.';
      ul.appendChild(li);
      return;
    }
    todos.forEach(t => {
      const li = document.createElement('li');
      li.style.display = 'flex';
      li.style.alignItems = 'center';
      li.style.justifyContent = 'space-between';
      li.style.padding = '6px 0';
      li.innerHTML = `
        <label style="display:flex;gap:8px;align-items:center">
          <input type="checkbox" ${t.done ? 'checked' : ''}/>
          <span style="min-width:160px">${escapeHtml(t.text)}</span>
        </label>
        <div>
          <button class="rm small danger">Del</button>
        </div>
      `;
      li.querySelector('input[type="checkbox"]').addEventListener('change', (e) => {
        t.done = e.target.checked;
        saveLocal();
        apiRef.emit({ type: 'todo:updated', id: t.id, done: t.done });
      });
      li.querySelector('.rm').addEventListener('click', () => {
        todos = todos.filter(x => x.id !== t.id);
        saveLocal();
        renderList();
        apiRef.emit({ type: 'todo:deleted', id: t.id });
      });
      ul.appendChild(li);
    });
  }
}

export async function unmount() {
  if (rootEl && rootEl.remove) rootEl.remove();
  rootEl = null;
  apiRef = null;
}

export function onMessage(msg) {
  // basic handler: support clear command
  if (!msg) return;
  if (msg.type === 'command' && msg.cmd === 'clear-todos') {
    todos = [];
    saveLocal();
    if (rootEl) {
      const ul = rootEl.querySelector('.list');
      if (ul) ul.innerHTML = '<li class="placeholder">No todos yet.</li>';
    }
  }
}

// small utility
function escapeHtml(s){ return String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;'); }