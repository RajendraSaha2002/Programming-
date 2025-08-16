// Simple Kanban Board with drag & drop and persistence (localStorage).
// Features:
// - add/delete/rename columns
// - add/edit/delete cards
// - drag & drop cards between columns and reorder within a column
// - persist board to localStorage
// - export/import JSON
// - simple modal for card description

(function () {
  // Elements
  const boardEl = document.getElementById('board');
  const addColumnBtn = document.getElementById('add-column-btn');
  const exportBtn = document.getElementById('export-btn');
  const importBtn = document.getElementById('import-btn');
  const importFileInput = document.getElementById('import-file');
  const colTemplate = document.getElementById('col-template');
  const cardTemplate = document.getElementById('card-template');

  const modal = document.getElementById('modal');
  const modalTitle = document.getElementById('modal-title');
  const modalDesc = document.getElementById('modal-desc');
  const modalSave = document.getElementById('modal-save');
  const modalCancel = document.getElementById('modal-cancel');

  const STORAGE_KEY = 'kanban-board:v1';

  // Data model
  let board = {
    columns: [
      { id: uid(), title: 'Todo', cards: [] },
      { id: uid(), title: 'In Progress', cards: [] },
      { id: uid(), title: 'Done', cards: [] },
    ],
  };

  // Drag state
  let dragState = { cardId: null, fromColId: null, draggedEl: null };

  // Modal state
  let editingCard = null; // { colId, cardId }

  // Utilities
  function uid() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
  }

  function save() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(board));
  }

  function load() {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    try {
      const parsed = JSON.parse(raw);
      if (parsed && Array.isArray(parsed.columns)) {
        board = parsed;
      }
    } catch (e) {
      console.warn('Failed to load board', e);
    }
  }

  // Rendering
  function render() {
    boardEl.innerHTML = '';
    board.columns.forEach((col) => {
      const colNode = colTemplate.content.firstElementChild.cloneNode(true);
      colNode.dataset.colId = col.id;

      const titleInput = colNode.querySelector('.col-title');
      titleInput.value = col.title;
      titleInput.addEventListener('change', (e) => {
        col.title = e.target.value.trim() || 'Unnamed';
        save();
      });

      const addCardBtn = colNode.querySelector('.add-card');
      addCardBtn.addEventListener('click', () => {
        const newCard = {
          id: uid(),
          title: 'New card',
          description: '',
          createdAt: Date.now(),
        };
        col.cards.unshift(newCard);
        save();
        render();
        // open editor for newly created card
        startEditCard(col.id, newCard.id);
      });

      const deleteColBtn = colNode.querySelector('.delete-col');
      deleteColBtn.addEventListener('click', () => {
        if (!confirm(`Delete column "${col.title}" and its ${col.cards.length} cards?`)) return;
        board.columns = board.columns.filter(c => c.id !== col.id);
        save();
        render();
      });

      const list = colNode.querySelector('.card-list');
      // If empty show placeholder
      if (col.cards.length === 0) {
        const ph = document.createElement('div');
        ph.className = 'placeholder';
        ph.textContent = 'No cards. Click + Card or drop one here.';
        list.appendChild(ph);
      }

      // render cards
      col.cards.forEach((card) => {
        const cardNode = cardTemplate.content.firstElementChild.cloneNode(true);
        cardNode.dataset.cardId = card.id;
        cardNode.dataset.colId = col.id;

        const titleEl = cardNode.querySelector('.card-title');
        titleEl.textContent = card.title;
        // inline edit of title
        titleEl.addEventListener('input', (e) => {
          card.title = e.target.textContent.trim() || 'Untitled';
          save();
        });

        const meta = cardNode.querySelector('.card-meta');
        meta.textContent = new Date(card.createdAt).toLocaleString();

        const editBtn = cardNode.querySelector('.edit-desc');
        editBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          startEditCard(col.id, card.id);
        });

        const delBtn = cardNode.querySelector('.delete-card');
        delBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          if (!confirm('Delete card?')) return;
          deleteCard(col.id, card.id);
        });

        // Drag events
        cardNode.addEventListener('dragstart', (e) => {
          dragState.cardId = card.id;
          dragState.fromColId = col.id;
          dragState.draggedEl = cardNode;
          cardNode.classList.add('dragging');
          try {
            e.dataTransfer.setData('text/plain', JSON.stringify({ cardId: card.id, fromColId: col.id }));
            e.dataTransfer.effectAllowed = 'move';
          } catch (err) {
            // some browsers may disallow setData during dragstart in some contexts
          }
        });
        cardNode.addEventListener('dragend', () => {
          dragState = { cardId: null, fromColId: null, draggedEl: null };
          document.querySelectorAll('.card').forEach(n => n.classList.remove('dragging'));
          // remove any placeholders left behind
          document.querySelectorAll('.card-list .placeholder').forEach(n => n.remove());
        });

        // Allow clicking card to edit
        cardNode.addEventListener('click', () => startEditCard(col.id, card.id));

        list.appendChild(cardNode);
      });

      // Dragover / drop on column's list to accept cards
      list.addEventListener('dragover', (e) => {
        e.preventDefault();
        const afterEl = getDragAfterElement(list, e.clientY);
        // remove existing placeholder(s)
        [...list.querySelectorAll('.placeholder')].forEach(n => n.remove());
        const ph = document.createElement('div');
        ph.className = 'placeholder';
        if (afterEl == null) {
          list.appendChild(ph);
        } else {
          list.insertBefore(ph, afterEl);
        }
      });

      list.addEventListener('dragleave', (e) => {
        // remove placeholder when leaving column
        // but if leaving to another card within same list, skip removal (handled by dragover)
        const related = e.relatedTarget;
        if (!list.contains(related)) {
          [...list.querySelectorAll('.placeholder')].forEach(n => n.remove());
        }
      });

      list.addEventListener('drop', (e) => {
        e.preventDefault();
        // remove placeholder(s)
        const placeholders = [...list.querySelectorAll('.placeholder')];
        placeholders.forEach(n => n.remove());

        // attempt to read dataTransfer
        let payload = null;
        try {
          const raw = e.dataTransfer.getData('text/plain');
          if (raw) payload = JSON.parse(raw);
        } catch (err) {
          // ignore
        }
        // fallback to dragState
        const cardId = (payload && payload.cardId) || dragState.cardId;
        const fromColId = (payload && payload.fromColId) || dragState.fromColId;

        if (!cardId || !fromColId) return;

        const toColId = col.id;
        const fromCol = board.columns.find(c => c.id === fromColId);
        const toCol = board.columns.find(c => c.id === toColId);
        if (!fromCol || !toCol) return;

        // find card object
        const cardIdx = fromCol.cards.findIndex(c => c.id === cardId);
        if (cardIdx === -1) return;
        const [cardObj] = fromCol.cards.splice(cardIdx, 1);

        // determine insert position based on mouse Y
        const afterEl = getDragAfterElement(list, e.clientY);
        if (!afterEl) {
          // append at end (top of list in our design is start, but we used unshift when adding; keep consistent: insert at end-of-list)
          toCol.cards.push(cardObj);
        } else {
          // insert before the card represented by afterEl
          const afterId = afterEl.dataset.cardId;
          const insertIdx = toCol.cards.findIndex(c => c.id === afterId);
          if (insertIdx === -1) toCol.cards.push(cardObj);
          else toCol.cards.splice(insertIdx, 0, cardObj);
        }

        save();
        render();
      });

      boardEl.appendChild(colNode);
    });

    // Make the board horizontally scrollable on small screens
  }

  // Helpers for drag position detection
  function getDragAfterElement(container, y) {
    const draggableElements = [...container.querySelectorAll('.card:not(.dragging)')];

    if (draggableElements.length === 0) return null;

    let closest = null;
    let closestOffset = Number.NEGATIVE_INFINITY;

    draggableElements.forEach((child) => {
      const box = child.getBoundingClientRect();
      const offset = y - box.top - box.height / 2;
      if (offset < 0 && offset > closestOffset) {
        closestOffset = offset;
        closest = child;
      }
    });

    return closest;
  }

  // Card operations
  function deleteCard(colId, cardId) {
    const col = board.columns.find(c => c.id === colId);
    if (!col) return;
    col.cards = col.cards.filter(c => c.id !== cardId);
    save();
    render();
  }

  function startEditCard(colId, cardId) {
    const col = board.columns.find(c => c.id === colId);
    if (!col) return;
    const card = col.cards.find(c => c.id === cardId);
    if (!card) return;
    editingCard = { colId, cardId };
    modalTitle.value = card.title;
    modalDesc.value = card.description || '';
    showModal();
  }

  function applyModalSave() {
    if (!editingCard) return;
    const { colId, cardId } = editingCard;
    const col = board.columns.find(c => c.id === colId);
    if (!col) return;
    const card = col.cards.find(c => c.id === cardId);
    if (!card) return;
    card.title = modalTitle.value.trim() || 'Untitled';
    card.description = modalDesc.value;
    save();
    render();
    hideModal();
  }

  // Modal
  function showModal() {
    modal.classList.remove('hidden');
    modal.setAttribute('aria-hidden', 'false');
    modalTitle.focus();
  }
  function hideModal() {
    modal.classList.add('hidden');
    modal.setAttribute('aria-hidden', 'true');
    editingCard = null;
  }

  modalCancel.addEventListener('click', hideModal);
  modalSave.addEventListener('click', applyModalSave);

  // Keyboard: ESC closes modal
  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (!modal.classList.contains('hidden')) hideModal();
    }
  });

  // Add column
  addColumnBtn.addEventListener('click', () => {
    const title = prompt('Column title', 'New Column') || 'New Column';
    board.columns.push({ id: uid(), title: title.trim(), cards: [] });
    save();
    render();
    // scroll to end to reveal new column
    setTimeout(() => boardEl.lastElementChild?.scrollIntoView({ behavior: 'smooth', inline: 'end' }), 50);
  });

  // Export / Import
  exportBtn.addEventListener('click', () => {
    const data = JSON.stringify(board, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `kanban-${new Date().toISOString().slice(0,19).replace(/[:T]/g,'-')}.json`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  });

  importBtn.addEventListener('click', () => {
    importFileInput.click();
  });

  importFileInput.addEventListener('change', (e) => {
    const file = e.target.files && e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function (ev) {
      try {
        const parsed = JSON.parse(ev.target.result);
        if (!parsed || !Array.isArray(parsed.columns)) throw new Error('Invalid format');
        if (!confirm('Importing will replace your current board. Continue?')) return;
        board = parsed;
        save();
        render();
      } catch (err) {
        alert('Failed to import: ' + err.message);
      }
    };
    reader.readAsText(file);
    // reset input so same file can be re-selected later
    importFileInput.value = '';
  });

  // Touch fallback: enable pointer events to initiate drag on touch devices
  // This is a lightweight approach: long press to start dragging is not implemented;
  // mobile users can use buttons to add/edit cards or reorder via export/import + manual editing.
  // (Implementing full touch drag-reorder is more involved — can add on request.)

  // Init
  load();
  render();

  // Expose for debug
  window.kanbanBoard = {
    board,
    save,
    load,
    render,
  };
})();