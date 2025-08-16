// Mini E-commerce Frontend (static demo)
// - Product listing with search & sort
// - Product detail modal with quantity and Buy/Add to Cart
// - Cart drawer with add/remove/update quantity
// - Cart persisted in localStorage
// - Mock checkout (no real payments)

(function () {
  // ---------- DATA ----------
  const PRODUCTS = [
    { id: 'p1', name: 'Comfy Chair', price: 12999.00, desc: 'Comfortable accent chair for living room.', img: 'https://picsum.photos/seed/chair/800/600' },
    { id: 'p2', name: 'Wireless Headphones', price: 8999.50, desc: 'Noise-cancelling wireless headphones with long battery life.', img: 'https://picsum.photos/seed/headphones/800/600' },
    { id: 'p3', name: 'Ceramic Mug Set', price: 2499.00, desc: 'Set of 4 glazed ceramic mugs.', img: 'https://picsum.photos/seed/mug/800/600' },
    { id: 'p4', name: 'Desk Lamp', price: 3599.00, desc: 'LED desk lamp with adjustable brightness and arm.', img: 'https://picsum.photos/seed/lamp/800/600' },
    { id: 'p5', name: 'Backpack', price: 6499.00, desc: 'Water-resistant backpack with laptop pocket.', img: 'https://picsum.photos/seed/backpack/800/600' },
    { id: 'p6', name: 'Sneakers', price: 9999.00, desc: 'Lightweight sneakers for everyday wear.', img: 'https://picsum.photos/seed/sneakers/800/600' },
    { id: 'p7', name: 'Portable Speaker', price: 5499.00, desc: 'Compact Bluetooth speaker with rich sound.', img: 'https://picsum.photos/seed/speaker/800/600' },
    { id: 'p8', name: 'Notebook', price: 899.00, desc: 'Hardcover notebook with 200 pages.', img: 'https://picsum.photos/seed/notebook/800/600' }
  ];

  const CART_KEY = 'mini-shop:cart:v1';

  // ---------- DOM ----------
  const productsEl = document.getElementById('products');
  const searchEl = document.getElementById('search');
  const sortEl = document.getElementById('sort');
  const cartBtn = document.getElementById('cart-btn');
  const cartCountEl = document.getElementById('cart-count');

  // product modal
  const pm = {
    root: document.getElementById('product-modal'),
    image: document.getElementById('pm-image'),
    title: document.getElementById('pm-title'),
    desc: document.getElementById('pm-desc'),
    price: document.getElementById('pm-price'),
    qty: document.getElementById('pm-qty'),
    addBtn: document.getElementById('pm-add'),
    buyBtn: document.getElementById('pm-buy'),
    closeBtn: document.getElementById('pm-close'),
  };

  // cart drawer
  const cartDrawer = {
    root: document.getElementById('cart-drawer'),
    list: document.getElementById('cart-list'),
    subtotal: document.getElementById('cart-subtotal'),
    items: document.getElementById('cart-items'),
    closeBtn: document.getElementById('cart-close'),
    clearBtn: document.getElementById('clear-cart'),
    checkoutBtn: document.getElementById('checkout'),
  };

  // ---------- STATE ----------
  let cart = loadCart(); // { productId -> { id, qty } }
  let currentProduct = null;

  // ---------- HELPERS ----------
  const currency = new Intl.NumberFormat(undefined, { style: 'currency', currency: 'NGN', maximumFractionDigits: 2 });

  function saveCart() {
    try { localStorage.setItem(CART_KEY, JSON.stringify(cart)); }
    catch (e) { console.warn('Failed to save cart', e); }
    updateCartUI();
  }

  function loadCart() {
    try {
      const raw = localStorage.getItem(CART_KEY);
      if (!raw) return {};
      return JSON.parse(raw) || {};
    } catch (e) {
      return {};
    }
  }

  function cartItemCount() {
    return Object.values(cart).reduce((s, it) => s + (it.qty || 0), 0);
  }

  function cartSubtotal() {
    return Object.values(cart).reduce((s, it) => {
      const p = PRODUCTS.find(x => x.id === it.id);
      return s + (p ? p.price * it.qty : 0);
    }, 0);
  }

  // ---------- RENDER PRODUCTS ----------
  function renderProducts(list) {
    productsEl.innerHTML = '';
    if (list.length === 0) {
      const p = document.createElement('div');
      p.className = 'card';
      p.style.padding = '24px';
      p.textContent = 'No products found.';
      productsEl.appendChild(p);
      return;
    }

    const frag = document.createDocumentFragment();
    list.forEach(p => {
      const card = document.createElement('article');
      card.className = 'card';
      card.innerHTML = `
        <img src="${p.img}" alt="${escapeHtml(p.name)}" loading="lazy" />
        <div class="card-body">
          <div class="card-title">${escapeHtml(p.name)}</div>
          <div class="card-desc">${escapeHtml(p.desc)}</div>
          <div class="card-footer">
            <div class="price">${currency.format(p.price)}</div>
            <div>
              <button class="btn" data-id="${p.id}" data-action="view">View</button>
              <button class="btn primary" data-id="${p.id}" data-action="add">Add</button>
            </div>
          </div>
        </div>
      `;
      // handlers
      card.querySelectorAll('button').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const id = btn.dataset.id;
          const action = btn.dataset.action;
          if (action === 'view') openProductModal(id);
          else if (action === 'add') addToCart(id, 1);
        });
      });
      frag.appendChild(card);
    });
    productsEl.appendChild(frag);
  }

  function escapeHtml(s) {
    return String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
  }

  // ---------- SEARCH & SORT ----------
  function getFilteredProducts() {
    const q = (searchEl.value || '').trim().toLowerCase();
    let list = PRODUCTS.slice();
    if (q) {
      list = list.filter(p => (p.name + ' ' + p.desc).toLowerCase().includes(q));
    }
    const s = sortEl.value;
    if (s === 'price-asc') list.sort((a,b) => a.price - b.price);
    else if (s === 'price-desc') list.sort((a,b) => b.price - a.price);
    else if (s === 'name-asc') list.sort((a,b) => a.name.localeCompare(b.name));
    // relevance leaves original order (or filtered order)
    return list;
  }

  // ---------- PRODUCT MODAL ----------
  function openProductModal(id) {
    const p = PRODUCTS.find(x => x.id === id);
    if (!p) return;
    currentProduct = p;
    pm.image.src = p.img;
    pm.image.alt = p.name;
    pm.title.textContent = p.name;
    pm.desc.textContent = p.desc;
    pm.price.textContent = currency.format(p.price);
    pm.qty.value = 1;
    pm.root.setAttribute('aria-hidden', 'false');
    pm.root.style.display = 'flex';
    pm.addBtn.dataset.id = p.id;
    pm.buyBtn.dataset.id = p.id;
    pm.addBtn.focus();
  }

  function closeProductModal() {
    currentProduct = null;
    pm.root.setAttribute('aria-hidden', 'true');
    pm.root.style.display = 'none';
  }

  // ---------- CART OPERATIONS ----------
  function addToCart(id, qty = 1) {
    const existing = cart[id];
    cart[id] = { id, qty: Math.max(1, (existing ? existing.qty : 0) + Number(qty)) };
    saveCart();
    showCart();
  }

  function updateCartItem(id, qty) {
    if (!cart[id]) return;
    qty = Number(qty);
    if (Number.isNaN(qty) || qty <= 0) {
      delete cart[id];
    } else {
      cart[id].qty = Math.floor(qty);
    }
    saveCart();
    renderCart();
  }

  function removeCartItem(id) {
    delete cart[id];
    saveCart();
    renderCart();
  }

  function clearCart() {
    if (!confirm('Clear the cart?')) return;
    cart = {};
    saveCart();
    renderCart();
  }

  // ---------- CART UI ----------
  function updateCartUI() {
    cartCountEl.textContent = String(cartItemCount());
    // reflect counts near buttons if needed (not implemented)
  }

  function renderCart() {
    cartDrawer.list.innerHTML = '';
    const keys = Object.keys(cart);
    if (keys.length === 0) {
      const li = document.createElement('li');
      li.className = 'cart-item';
      li.textContent = 'Your cart is empty.';
      cartDrawer.list.appendChild(li);
    } else {
      const frag = document.createDocumentFragment();
      keys.forEach(id => {
        const item = cart[id];
        const p = PRODUCTS.find(x => x.id === id);
        if (!p) return;
        const li = document.createElement('li');
        li.className = 'cart-item';
        li.innerHTML = `
          <img src="${p.img}" alt="${escapeHtml(p.name)}" />
          <div class="meta">
            <div style="font-weight:700">${escapeHtml(p.name)}</div>
            <div class="muted">${currency.format(p.price)} each</div>
          </div>
          <div>
            <div class="qty">
              <input type="number" min="1" value="${item.qty}" data-id="${id}" aria-label="Quantity for ${escapeHtml(p.name)}" />
            </div>
            <div style="margin-top:8px;text-align:right">
              <div style="font-weight:800">${currency.format(p.price * item.qty)}</div>
              <button class="btn muted" data-id="${id}" data-action="remove">Remove</button>
            </div>
          </div>
        `;
        // qty change
        li.querySelector('input').addEventListener('change', (e) => {
          const v = e.target.value;
          updateCartItem(id, v);
        });
        li.querySelector('button[data-action="remove"]').addEventListener('click', () => removeCartItem(id));
        frag.appendChild(li);
      });
      cartDrawer.list.appendChild(frag);
    }
    cartDrawer.subtotal.textContent = currency.format(cartSubtotal());
    cartDrawer.items.textContent = String(cartItemCount());
    updateCartUI();
  }

  // ---------- CART VISIBILITY ----------
  function showCart() {
    cartDrawer.root.setAttribute('aria-hidden', 'false');
    cartDrawer.root.style.display = 'flex';
    cartBtn.setAttribute('aria-expanded', 'true');
    renderCart();
  }

  function hideCart() {
    cartDrawer.root.setAttribute('aria-hidden', 'true');
    cartDrawer.root.style.display = 'none';
    cartBtn.setAttribute('aria-expanded', 'false');
  }

  // ---------- CHECKOUT ----------
  function checkout() {
    const count = cartItemCount();
    if (count === 0) {
      alert('Your cart is empty.');
      return;
    }
    // Mock checkout flow
    const subtotal = cartSubtotal();
    const confirmMsg = `Proceed to checkout?\nItems: ${count}\nSubtotal: ${currency.format(subtotal)}\n\nThis is a demo — no real payment will be taken.`;
    if (!confirm(confirmMsg)) return;
    // Simulate success
    alert('Payment simulated — thank you for your purchase!');
    cart = {};
    saveCart();
    hideCart();
  }

  // ---------- EVENTS ----------
  // search & sort
  function refreshProducts() {
    const list = getFilteredProducts();
    renderProducts(list);
  }

  searchEl.addEventListener('input', () => {
    // simple debounce
    clearTimeout(searchEl._t);
    searchEl._t = setTimeout(refreshProducts, 220);
  });
  sortEl.addEventListener('change', refreshProducts);

  // product modal actions
  pm.closeBtn.addEventListener('click', closeProductModal);
  pm.addBtn.addEventListener('click', () => {
    const id = pm.addBtn.dataset.id;
    const qty = Number(pm.qty.value) || 1;
    addToCart(id, qty);
    closeProductModal();
  });
  pm.buyBtn.addEventListener('click', () => {
    const id = pm.buyBtn.dataset.id;
    const qty = Number(pm.qty.value) || 1;
    addToCart(id, qty);
    showCart();
    // optionally jump to checkout
  });

  // cart drawer actions
  cartBtn.addEventListener('click', () => {
    const expanded = cartBtn.getAttribute('aria-expanded') === 'true';
    if (expanded) hideCart();
    else showCart();
  });
  cartDrawer.closeBtn.addEventListener('click', hideCart);
  cartDrawer.clearBtn.addEventListener('click', clearCart);
  cartDrawer.checkoutBtn.addEventListener('click', checkout);

  // close modals with ESC
  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (pm.root.getAttribute('aria-hidden') === 'false') closeProductModal();
      if (cartDrawer.root.getAttribute('aria-hidden') === 'false') hideCart();
    }
  });

  // ---------- INIT ----------
  function init() {
    refreshProducts();
    updateCartUI();
    // Hide overlays initially
    pm.root.setAttribute('aria-hidden', 'true');
    pm.root.style.display = 'none';
    cartDrawer.root.setAttribute('aria-hidden', 'true');
    cartDrawer.root.style.display = 'none';
  }

  init();

  // Expose for debugging
  window.miniShop = {
    PRODUCTS,
    cart,
    addToCart,
    removeCartItem,
    updateCartItem,
    checkout,
  };
})();