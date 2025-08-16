// Expense Tracker
// Features:
// - add / edit / delete transactions
// - calculate balance, total income, total expenses
// - filter by all/income/expense
// - persist data in localStorage
// - export CSV, clear all
// - simple UX: click a transaction to edit it

(function () {
  // Elements
  const descInput = document.getElementById('desc');
  const amountInput = document.getElementById('amount');
  const form = document.getElementById('tx-form');
  const addBtn = document.getElementById('add-btn');
  const updateBtn = document.getElementById('update-btn');
  const cancelBtn = document.getElementById('cancel-btn');
  const txList = document.getElementById('tx-list');
  const balanceEl = document.getElementById('balance');
  const incomeEl = document.getElementById('income');
  const expensesEl = document.getElementById('expenses');
  const filterEl = document.getElementById('filter');
  const exportBtn = document.getElementById('export-csv');
  const clearAllBtn = document.getElementById('clear-all');

  // Storage key
  const STORAGE_KEY = 'expense-tracker:transactions';

  // State
  let transactions = [];
  let editingId = null;
  let currentFilter = 'all';

  // Utilities
  const currency = new Intl.NumberFormat(undefined, { style: 'currency', currency: 'NGN', maximumFractionDigits: 2 });

  function save() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(transactions));
  }

  function load() {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) transactions = parsed;
    } catch (e) {
      console.warn('Failed to load transactions', e);
    }
  }

  function uid() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
  }

  // Business logic
  function addTransaction(desc, amount) {
    const tx = { id: uid(), description: desc, amount: Number(amount), createdAt: Date.now() };
    transactions.unshift(tx);
    save();
    render();
  }

  function updateTransaction(id, desc, amount) {
    const idx = transactions.findIndex(t => t.id === id);
    if (idx === -1) return;
    transactions[idx].description = desc;
    transactions[idx].amount = Number(amount);
    save();
    render();
  }

  function deleteTransaction(id) {
    transactions = transactions.filter(t => t.id !== id);
    save();
    render();
  }

  function clearAll() {
    if (!confirm('Clear all transactions? This cannot be undone.')) return;
    transactions = [];
    save();
    render();
  }

  function computeTotals(list) {
    const income = list.filter(t => t.amount > 0).reduce((s, t) => s + t.amount, 0);
    const expenses = list.filter(t => t.amount < 0).reduce((s, t) => s + t.amount, 0);
    const balance = income + expenses;
    return { income, expenses, balance };
  }

  // Rendering
  function renderList() {
    txList.innerHTML = '';
    const list = transactions.filter(txFilter);
    if (list.length === 0) {
      const li = document.createElement('li');
      li.className = 'tx-item';
      li.textContent = 'No transactions yet.';
      txList.appendChild(li);
      return;
    }

    list.forEach((t) => {
      const li = document.createElement('li');
      li.className = 'tx-item';
      li.tabIndex = 0;

      const left = document.createElement('div');
      left.className = 'left';
      const desc = document.createElement('div');
      desc.className = 'desc';
      desc.textContent = t.description;
      const meta = document.createElement('div');
      meta.className = 'meta';
      meta.textContent = new Date(t.createdAt).toLocaleString();

      left.appendChild(desc);
      left.appendChild(meta);

      const right = document.createElement('div');
      right.className = 'tx-actions';
      const amount = document.createElement('div');
      amount.className = 'tx-amount ' + (t.amount >= 0 ? 'positive' : 'negative');
      amount.textContent = currency.format(t.amount);

      const editBtn = document.createElement('button');
      editBtn.className = 'small-btn';
      editBtn.title = 'Edit';
      editBtn.textContent = 'Edit';
      editBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        startEdit(t.id);
      });

      const delBtn = document.createElement('button');
      delBtn.className = 'small-btn';
      delBtn.title = 'Delete';
      delBtn.textContent = 'Delete';
      delBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        if (confirm('Delete this transaction?')) deleteTransaction(t.id);
      });

      right.appendChild(amount);
      right.appendChild(editBtn);
      right.appendChild(delBtn);

      li.appendChild(left);
      li.appendChild(right);

      // click the item to edit as well
      li.addEventListener('click', () => startEdit(t.id));

      txList.appendChild(li);
    });
  }

  function renderSummary() {
    const list = transactions;
    const { income, expenses, balance } = computeTotals(list);
    balanceEl.textContent = currency.format(balance);
    incomeEl.textContent = currency.format(income);
    expensesEl.textContent = currency.format(Math.abs(expenses));
  }

  function render() {
    renderSummary();
    renderList();
    renderFormState();
  }

  function txFilter(t) {
    if (currentFilter === 'all') return true;
    if (currentFilter === 'income') return t.amount > 0;
    if (currentFilter === 'expense') return t.amount < 0;
    return true;
  }

  // Form handling
  function resetForm() {
    descInput.value = '';
    amountInput.value = '';
    editingId = null;
    renderFormState();
  }

  function startEdit(id) {
    const tx = transactions.find(t => t.id === id);
    if (!tx) return;
    editingId = id;
    descInput.value = tx.description;
    amountInput.value = tx.amount;
    renderFormState();
    // focus description for quick edit
    descInput.focus();
  }

  function renderFormState() {
    if (editingId) {
      addBtn.classList.add('hidden');
      updateBtn.classList.remove('hidden');
      cancelBtn.classList.remove('hidden');
    } else {
      addBtn.classList.remove('hidden');
      updateBtn.classList.add('hidden');
      cancelBtn.classList.add('hidden');
    }
  }

  // Export CSV
  function exportCSV() {
    if (!transactions.length) {
      alert('No transactions to export.');
      return;
    }
    const header = ['id', 'description', 'amount', 'createdAt'];
    const rows = transactions.map(t => [t.id, `"${String(t.description).replace(/"/g, '""')}"`, t.amount, new Date(t.createdAt).toISOString()]);
    const csv = [header.join(','), ...rows.map(r => r.join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `transactions-${new Date().toISOString().slice(0,19).replace(/[:T]/g,'-')}.csv`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  // Events
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const desc = descInput.value.trim();
    const amount = Number(amountInput.value);
    if (!desc || Number.isNaN(amount) || amount === 0) {
      alert('Please enter a description and a non-zero amount.');
      return;
    }
    if (editingId) {
      updateTransaction(editingId, desc, amount);
    } else {
      addTransaction(desc, amount);
    }
    resetForm();
  });

  updateBtn.addEventListener('click', () => {
    const desc = descInput.value.trim();
    const amount = Number(amountInput.value);
    if (!desc || Number.isNaN(amount) || amount === 0) {
      alert('Please enter a description and a non-zero amount.');
      return;
    }
    if (editingId) {
      updateTransaction(editingId, desc, amount);
      resetForm();
    }
  });

  cancelBtn.addEventListener('click', () => {
    resetForm();
  });

  filterEl.addEventListener('change', () => {
    currentFilter = filterEl.value;
    render();
  });

  exportBtn.addEventListener('click', exportCSV);
  clearAllBtn.addEventListener('click', clearAll);

  // Initialization
  load();
  // If empty, optionally seed with an example entry
  if (transactions.length === 0) {
    // Example starter items (uncomment to provide defaults)
    // transactions = [
    //   { id: uid(), description: 'Salary', amount: 120000.00, createdAt: Date.now() - 86400000 },
    //   { id: uid(), description: 'Groceries', amount: -8500.50, createdAt: Date.now() - 43200000 },
    // ];
    // save();
  }
  render();
  // expose for debugging in console
  window.expenseTracker = {
    addTransaction,
    updateTransaction,
    deleteTransaction,
    getAll: () => transactions.slice(),
  };
})();