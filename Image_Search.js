// Image Search + Lightbox (supports Pixabay or Unsplash).
// Instructions:
// 1) Get an API key:
//    - Pixabay: https://pixabay.com/api/docs/  (recommended for easy setup)
//    - Unsplash: https://unsplash.com/developers
// 2) Set PIXABAY_API_KEY or UNSPLASH_ACCESS_KEY below (leave empty to use demo placeholders).
//
// Features implemented:
// - Search images via API (query + pagination)
// - Infinite scroll (IntersectionObserver)
// - Grid of thumbnails with title/meta
// - Click to open lightbox with large image, download link, favorite toggle
// - Favorites persisted in localStorage and viewable via "Favorites" button
// - Debounced search & basic error handling

(function () {
  // ====== CONFIG ======
  // Add your API keys here:
  const PIXABAY_API_KEY = ''; // e.g. '123456-abcdef...'
  const UNSPLASH_ACCESS_KEY = ''; // e.g. 'AbCdEfGhIjKl...'

  // default provider 'pixabay' or 'unsplash'
  const DEFAULT_PROVIDER = 'pixabay';

  // page size (per API limits)
  const PER_PAGE = 20;

  // ====== ELEMENTS ======
  const providerSelect = document.getElementById('provider');
  const searchInput = document.getElementById('search-input');
  const searchBtn = document.getElementById('search-btn');
  const grid = document.getElementById('grid');
  const sentinel = document.getElementById('sentinel');
  const favBtn = document.getElementById('show-fav');

  const lightbox = document.getElementById('lightbox');
  const lbImg = document.getElementById('lb-img');
  const lbClose = document.getElementById('lb-close');
  const lbInfo = document.getElementById('lb-info');
  const lbDownload = document.getElementById('lb-download');
  const lbFav = document.getElementById('lb-fav');

  const cardTmpl = document.getElementById('card-tmpl');

  // ====== STATE ======
  let provider = DEFAULT_PROVIDER;
  let query = '';
  let page = 1;
  let loading = false;
  let noMore = false;
  let images = []; // flattened list
  let favorites = loadFavorites(); // {id -> imageObj}
  let viewingFavorites = false;

  // ====== UTIL ======
  function debounce(fn, wait = 300) {
    let t;
    return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), wait); };
  }

  function stamp() { return Date.now().toString(36); }

  function saveFavorites() {
    try { localStorage.setItem('image-search:favorites', JSON.stringify(Object.values(favorites))); } catch (e) { console.warn(e); }
  }

  function loadFavorites() {
    try {
      const raw = localStorage.getItem('image-search:favorites');
      if (!raw) return {};
      const arr = JSON.parse(raw);
      const map = {};
      arr.forEach(i => map[i._id || i.id] = i);
      return map;
    } catch (e) { return {}; }
  }

  // ====== API LAYER ======
  async function fetchPixabay(q, p = 1) {
    if (!PIXABAY_API_KEY) throw new Error('Missing Pixabay API key. Set PIXABAY_API_KEY in script.js');
    const url = `https://pixabay.com/api/?key=${encodeURIComponent(PIXABAY_API_KEY)}&q=${encodeURIComponent(q)}&image_type=photo&per_page=${PER_PAGE}&page=${p}&safesearch=true`;
    const res = await fetch(url);
    if (!res.ok) throw new Error('Pixabay error: ' + res.statusText);
    const json = await res.json();
    // normalize: id, thumb, large, title
    return {
      total: json.totalHits || 0,
      results: (json.hits || []).map(h => ({
        id: String(h.id),
        thumb: h.webformatURL,
        large: h.largeImageURL || h.fullHDURL || h.webformatURL,
        title: h.tags || '',
        user: h.user || '',
        source: 'pixabay',
      })),
    };
  }

  async function fetchUnsplash(q, p = 1) {
    if (!UNSPLASH_ACCESS_KEY) throw new Error('Missing Unsplash access key. Set UNSPLASH_ACCESS_KEY in script.js');
    const url = `https://api.unsplash.com/search/photos?client_id=${encodeURIComponent(UNSPLASH_ACCESS_KEY)}&query=${encodeURIComponent(q)}&page=${p}&per_page=${PER_PAGE}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error('Unsplash error: ' + res.statusText);
    const json = await res.json();
    return {
      total: json.total || 0,
      results: (json.results || []).map(h => ({
        id: h.id,
        thumb: h.urls.small,
        large: h.urls.full || h.urls.raw || h.urls.regular,
        title: h.alt_description || h.description || '',
        user: h.user && h.user.name ? h.user.name : '',
        source: 'unsplash',
        download_link: h.links && h.links.download,
      })),
    };
  }

  // fallback: produce placeholder images when no API key
  function placeholderResults(p = 1) {
    const res = [];
    for (let i = 0; i < PER_PAGE; i++) {
      const id = stamp() + '-' + i + '-' + p;
      res.push({
        id,
        thumb: `https://picsum.photos/seed/${encodeURIComponent(id)}/400/280`,
        large: `https://picsum.photos/seed/${encodeURIComponent(id)}/1200/800`,
        title: `Placeholder ${id}`,
        user: 'picsum',
        source: 'placeholder',
      });
    }
    return { total: 1000, results: res };
  }

  async function searchImages(q, p = 1) {
    if (!q) return { total: 0, results: [] };
    try {
      if (provider === 'pixabay') {
        if (!PIXABAY_API_KEY) return placeholderResults(p);
        return await fetchPixabay(q, p);
      } else if (provider === 'unsplash') {
        if (!UNSPLASH_ACCESS_KEY) return placeholderResults(p);
        return await fetchUnsplash(q, p);
      }
      return placeholderResults(p);
    } catch (err) {
      console.warn(err);
      return placeholderResults(p); // graceful fallback
    }
  }

  // ====== RENDER ======
  function clearGrid() {
    grid.innerHTML = '';
  }

  function createCard(imgObj) {
    const node = cardTmpl.content.firstElementChild.cloneNode(true);
    const img = node.querySelector('img.thumb');
    const title = node.querySelector('.title');
    const meta = node.querySelector('.meta');
    const favBtn = node.querySelector('.fav');

    img.src = imgObj.thumb;
    img.alt = imgObj.title || imgObj.user || 'Image';
    title.textContent = imgObj.title || (imgObj.user ? `by ${imgObj.user}` : '');
    meta.textContent = imgObj.source ? imgObj.source : '';

    // favorite state
    const key = imgObj._id || imgObj.id;
    if (favorites[key]) favBtn.textContent = '♥';
    else favBtn.textContent = '♡';

    // Open lightbox
    node.addEventListener('click', (e) => {
      // if clicking the favorite button, don't open lightbox
      if (e.target === favBtn) return;
      openLightbox(imgObj);
    });

    // favorite toggle
    favBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      toggleFavorite(imgObj, favBtn);
    });

    return node;
  }

  function renderImages(list, append = true) {
    if (!append) clearGrid();
    const fragment = document.createDocumentFragment();
    list.forEach(img => fragment.appendChild(createCard(img)));
    grid.appendChild(fragment);
  }

  // ====== LIGHTBOX ======
  let currentLightboxImage = null;

  function openLightbox(imgObj) {
    currentLightboxImage = imgObj;
    lbImg.src = imgObj.large;
    lbImg.alt = imgObj.title || imgObj.user || 'Image';
    lbInfo.textContent = `${imgObj.title || ''}${imgObj.user ? ' — ' + imgObj.user : ''}`;
    // download link: prefer provided, else use large url
    if (imgObj.download_link) lbDownload.href = imgObj.download_link;
    else lbDownload.href = imgObj.large;
    lbDownload.setAttribute('download', `image-${imgObj.id || stamp()}.jpg`);
    // favorite button reflect state
    const key = imgObj._id || imgObj.id;
    lbFav.textContent = favorites[key] ? '♥ Favorited' : '♡ Favorite';
    lightbox.hidden = false;
    document.body.style.overflow = 'hidden';
  }

  function closeLightbox() {
    lightbox.hidden = true;
    lbImg.src = '';
    currentLightboxImage = null;
    document.body.style.overflow = '';
  }

  lbClose.addEventListener('click', closeLightbox);
  lightbox.addEventListener('click', (e) => {
    if (e.target === lightbox) closeLightbox();
  });

  lbFav.addEventListener('click', () => {
    if (!currentLightboxImage) return;
    const key = currentLightboxImage._id || currentLightboxImage.id;
    if (favorites[key]) {
      delete favorites[key];
      lbFav.textContent = '♡ Favorite';
    } else {
      favorites[key] = currentLightboxImage;
      lbFav.textContent = '♥ Favorited';
    }
    saveFavorites();
    // reflect change in grid
    refreshGridFavoriteStates();
  });

  function toggleFavorite(imgObj, btnEl) {
    const key = imgObj._id || imgObj.id;
    if (favorites[key]) {
      delete favorites[key];
      btnEl.textContent = '♡';
    } else {
      favorites[key] = imgObj;
      btnEl.textContent = '♥';
    }
    saveFavorites();
  }

  function refreshGridFavoriteStates() {
    document.querySelectorAll('.card').forEach(card => {
      const id = card.dataset.cardId;
      // we don't set data-card-id currently, so refresh by matching img src -> favorites lookup (best-effort)
      const img = card.querySelector('img.thumb');
      const favBtn = card.querySelector('.fav');
      if (!img || !favBtn) return;
      const found = Object.values(favorites).some(f => f.thumb === img.src || f.large === img.src);
      favBtn.textContent = found ? '♥' : '♡';
    });
  }

  // ====== INFINITE SCROLL ======
  const observer = new IntersectionObserver(async (entries) => {
    for (const entry of entries) {
      if (entry.isIntersecting && !loading && !noMore && !viewingFavorites) {
        page += 1;
        await loadPage();
      }
    }
  }, { root: null, rootMargin: '200px', threshold: 0.1 });

  // ====== LOAD / SEARCH ======
  async function loadPage() {
    loading = true;
    setLoadingUI(true);
    try {
      const res = await searchImages(query, page);
      if (res.results.length === 0) {
        noMore = true;
      } else {
        images = images.concat(res.results);
        renderImages(res.results, true);
      }
    } catch (err) {
      console.error(err);
    } finally {
      loading = false;
      setLoadingUI(false);
    }
  }

  async function doSearch(q) {
    query = q.trim();
    page = 1;
    images = [];
    noMore = false;
    viewingFavorites = false;
    clearGrid();
    if (!query) {
      // show favorites or placeholder
      renderPlaceholder();
      return;
    }
    setLoadingUI(true);
    try {
      const res = await searchImages(query, page);
      images = res.results.slice();
      if (res.results.length < PER_PAGE) noMore = true;
      renderImages(images, false);
      // start observing sentinel for infinite scroll
      observer.observe(sentinel);
    } catch (err) {
      console.error(err);
      renderPlaceholder('Failed to load images.');
    } finally {
      setLoadingUI(false);
    }
  }

  function renderPlaceholder(text = 'Search to see images. If no API key is provided, placeholders are used.') {
    clearGrid();
    const p = document.createElement('div');
    p.className = 'placeholder';
    p.style.padding = '36px';
    p.style.textAlign = 'center';
    p.style.gridColumn = '1 / -1';
    p.textContent = text;
    grid.appendChild(p);
  }

  // ====== FAVORITES VIEW ======
  function showFavorites() {
    viewingFavorites = true;
    observer.unobserve(sentinel);
    clearGrid();
    const favList = Object.values(favorites).slice().reverse();
    if (favList.length === 0) {
      renderPlaceholder('No favorites yet — click ♡ on any image to save it.');
      return;
    }
    renderImages(favList, false);
  }

  // ====== UI HELPERS ======
  function setLoadingUI(on) {
    searchBtn.disabled = on;
    if (on) searchBtn.textContent = 'Loading...';
    else searchBtn.textContent = 'Search';
  }

  // ====== EVENTS ======
  searchBtn.addEventListener('click', () => {
    const q = searchInput.value || '';
    doSearch(q);
  });

  const debouncedSearch = debounce(() => {
    const q = searchInput.value || '';
    doSearch(q);
  }, 450);

  searchInput.addEventListener('input', debouncedSearch);

  providerSelect.addEventListener('change', (e) => {
    provider = e.target.value;
    // Inform user if chosen provider requires key
    if (provider === 'pixabay' && !PIXABAY_API_KEY) {
      console.info('Pixabay selected but PIXABAY_API_KEY is empty. Placeholders will be used.');
    } else if (provider === 'unsplash' && !UNSPLASH_ACCESS_KEY) {
      console.info('Unsplash selected but UNSPLASH_ACCESS_KEY is empty. Placeholders will be used.');
    }
    // clear previous results
    renderPlaceholder('Provider changed — enter a query and search.');
  });

  favBtn.addEventListener('click', () => {
    showFavorites();
  });

  // Keyboard: Enter to search
  searchInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      doSearch(searchInput.value);
    }
  });

  // INIT
  function init() {
    providerSelect.value = DEFAULT_PROVIDER;
    provider = providerSelect.value;
    renderPlaceholder();
    observer.observe(sentinel);
  }

  init();

  // expose some methods for debugging
  window.imageSearch = {
    doSearch,
    showFavorites,
    openLightbox,
    closeLightbox,
    get favorites() { return favorites; },
  };
})();