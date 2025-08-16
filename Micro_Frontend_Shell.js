// Micro‑Frontend Playground — shell.js (ES module)
// - Demo of two module-based micro-frontends and one iframe-based
// - Dynamic loading of module widgets via import()
// - iframe widgets communicate with postMessage
// - Instances persisted in localStorage as layout
// - Instances can be reordered, removed, and receive simple messages

const AVAILABLE = {
  'todo': { type: 'module', title: 'Todo Widget', path: './widgets/todo.js' },
  'chart': { type: 'module', title: 'Mini Chart', path: './widgets/chart.js' },
  'iframe-sample': { type: 'iframe', title: 'Iframe Sample', path: './widgets/iframe-widget.html' },
};

const STORAGE_KEY = 'microfront:layout:v1';

const workspace = document.getElementById('workspace');
const instancesList = document.getElementById('instances');
const widgetSelect = document.getElementById('widget-select');
const addBtn = document.getElementById('add-widget');
const saveBtn = document.getElementById('save-layout');
const clearBtn = document.getElementById('clear-layout');
const template = document.getElementById('widget-frame-template');

let state = {
  instances: [] // { id, widgetKey, type, title, meta }
};

// lightweight utility
function uid(){ return Date.now().toString(36) + '-' + Math.random().toString(36).slice(2,8); }

function persist(){ localStorage.setItem(STORAGE_KEY, JSON.stringify(state.instances)); }
function loadPersist(){
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    return JSON.parse(raw);
  } catch(e){ return []; }
}

// Create DOM frame for widget and mount module/iframe
async function mountInstance(inst) {
  const node = template.content.firstElementChild.cloneNode(true);
  node.dataset.instanceId = inst.id;
  node.querySelector('.widget-title').textContent = inst.title;
  const body = node.querySelector('.widget-body');

  // actions
  node.querySelector('.remove').addEventListener('click', () => {
    unmountInstance(inst.id);
  });
  node.querySelector('.up').addEventListener('click', () => moveInstance(inst.id, -1));
  node.querySelector('.down').addEventListener('click', () => moveInstance(inst.id, +1));
  node.querySelector('.msg').addEventListener('click', () => sendMessageToInstance(inst.id, { type: 'ping', text: 'Hello from shell', ts: Date.now() }));

  // attach body content depending on type
  if (inst.type === 'module') {
    // dynamic import the module and call mount
    try {
      const mod = await import(inst.path + '?t=' + Date.now()); // cache-bust during dev
      if (typeof mod.mount === 'function') {
        // provide a simple API for widget to communicate back
        const api = {
          emit: (msg) => { handleWidgetEvent(inst.id, msg); },
          props: inst.meta || {},
        };
        await mod.mount(body, api);
        inst._module = mod; // keep reference for unmount
      } else {
        body.innerHTML = '<div class="small-note">Module does not export mount(container, api)</div>';
      }
    } catch (err) {
      console.error('Failed to load module', inst.path, err);
      body.innerHTML = `<div class="small-note">Failed to load widget module: ${err.message}</div>`;
    }
  } else if (inst.type === 'iframe') {
    const iframe = document.createElement('iframe');
    iframe.className = 'iframe';
    iframe.src = inst.path;
    iframe.dataset.instanceId = inst.id;
    // listen to messages from iframe
    const onMessage = (ev) => {
      if (!ev.data || ev.data.__microfront_id !== inst.id) return;
      handleWidgetEvent(inst.id, ev.data.payload);
    };
    window.addEventListener('message', onMessage);
    // keep cleanup reference
    inst._iframeListener = onMessage;
    body.appendChild(iframe);
    inst._iframe = iframe;
  }

  workspace.appendChild(node);
  renderInstancesPanel();
  persist();
}

// Unmount and remove instance
async function unmountInstance(id) {
  const idx = state.instances.findIndex(i => i.id === id);
  if (idx === -1) return;
  const inst = state.instances[idx];
  // unmount module widget if exported
  if (inst.type === 'module' && inst._module && typeof inst._module.unmount === 'function') {
    try { await inst._module.unmount(); } catch(e){ console.warn(e); }
  }
  // remove iframe listeners if any
  if (inst.type === 'iframe' && inst._iframeListener) {
    window.removeEventListener('message', inst._iframeListener);
  }
  // remove DOM
  const el = workspace.querySelector(`[data-instance-id="${id}"]`);
  if (el) el.remove();
  // remove from state
  state.instances.splice(idx, 1);
  renderInstancesPanel();
  persist();
}

// Move instance up/down
function moveInstance(id, dir) {
  const idx = state.instances.findIndex(i => i.id === id);
  if (idx === -1) return;
  const to = idx + dir;
  if (to < 0 || to >= state.instances.length) return;
  const [item] = state.instances.splice(idx, 1);
  state.instances.splice(to, 0, item);
  reRenderWorkspace();
  persist();
}

// re-render workspace (unmount all and mount in order) — simple approach
async function reRenderWorkspace() {
  // unmount all modules (if necessary) and clear DOM
  const toUnmount = state.instances.slice();
  workspace.innerHTML = '';
  // re-mount in order
  for (const inst of state.instances) {
    // ensure the instance has path resolved
    if (!inst.path) {
      const meta = AVAILABLE[inst.widgetKey];
      inst.path = meta.path;
    }
    await mountInstance(inst);
  }
}

// send message to instance by id
function sendMessageToInstance(id, payload) {
  const inst = state.instances.find(i => i.id === id);
  if (!inst) return;
  if (inst.type === 'module') {
    // if module exposes onMessage, call it
    if (inst._module && typeof inst._module.onMessage === 'function') {
      try { inst._module.onMessage(payload); } catch (e) { console.warn(e); }
    } else {
      console.log('Module instance has no onMessage handler', id, payload);
    }
  } else if (inst.type === 'iframe') {
    if (inst._iframe && inst._iframe.contentWindow) {
      inst._iframe.contentWindow.postMessage({ __microfront_id: inst.id, payload }, '*');
    }
  }
}

// handle event emitted by widget (module or iframe)
function handleWidgetEvent(id, msg) {
  console.log('Widget event', id, msg);
  // basic example: show notification in instances panel
  const instEl = instancesList.querySelector(`[data-instance-id="${id}"]`);
  if (instEl) {
    const note = instEl.querySelector('.instance-note');
    if (note) note.textContent = JSON.stringify(msg).slice(0, 80);
  }
}

// render instances sidebar
function renderInstancesPanel() {
  instancesList.innerHTML = '';
  if (state.instances.length === 0) {
    const li = document.createElement('li');
    li.className = 'instance-item';
    li.textContent = 'No instances. Add a widget to experiment.';
    instancesList.appendChild(li);
    return;
  }
  state.instances.forEach(inst => {
    const li = document.createElement('li');
    li.className = 'instance-item';
    li.dataset.instanceId = inst.id;
    li.innerHTML = `
      <div style="display:flex;flex-direction:column">
        <strong>${inst.title}</strong>
        <span class="instance-note small-note">${(inst.meta && inst.meta.note) || ''}</span>
      </div>
      <div style="display:flex;gap:6px;align-items:center">
        <button class="btn small" data-action="msg" data-id="${inst.id}">Msg</button>
        <button class="btn small muted" data-action="focus" data-id="${inst.id}">Focus</button>
        <button class="btn small danger" data-action="remove" data-id="${inst.id}">Remove</button>
      </div>
    `;
    instancesList.appendChild(li);

    li.querySelector('button[data-action="msg"]').addEventListener('click', () => sendMessageToInstance(inst.id, { type: 'ui:hello', text: 'Hi widget' }));
    li.querySelector('button[data-action="focus"]').addEventListener('click', () => {
      const el = workspace.querySelector(`[data-instance-id="${inst.id}"]`);
      if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
    li.querySelector('button[data-action="remove"]').addEventListener('click', () => unmountInstance(inst.id));
  });
}

// Add new instance (create and mount)
addBtn.addEventListener('click', async () => {
  const widgetKey = widgetSelect.value;
  const meta = AVAILABLE[widgetKey];
  const inst = {
    id: uid(),
    widgetKey,
    type: meta.type,
    title: meta.title,
    path: meta.type === 'module' ? meta.path : meta.path,
    meta: { created: Date.now() }
  };
  state.instances.push(inst);
  await mountInstance(inst);
});

// Save / Clear layout
saveBtn.addEventListener('click', () => {
  persist();
  alert('Layout saved to localStorage.');
});
clearBtn.addEventListener('click', () => {
  if (!confirm('Remove all widgets and clear saved layout?')) return;
  // unmount all
  state.instances.slice().forEach(i => { unmountInstance(i.id); });
  state.instances = [];
  workspace.innerHTML = '';
  instancesList.innerHTML = '';
  localStorage.removeItem(STORAGE_KEY);
});

// Receive persisted layout on load
(async function init(){
  const persisted = loadPersist();
  if (persisted && persisted.length) {
    // reconstruct instances; ensure widgetKey and path set
    state.instances = persisted.map(p => {
      const meta = AVAILABLE[p.widgetKey];
      return { ...p, type: meta?.type || p.type, path: meta?.path || p.path, title: meta?.title || p.title };
    });
    // mount in order
    for (const inst of state.instances) {
      await mountInstance(inst);
    }
  }
})();

// Expose for debugging
window.microfront = {
  AVAILABLE, state, sendMessageToInstance, unmountInstance, mountInstance
};