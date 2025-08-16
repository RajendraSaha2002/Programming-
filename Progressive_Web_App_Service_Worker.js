// Simple service worker for app shell caching (offline-first).
const CACHE_NAME = 'offline-notes-shell-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/style.css',
  '/script.js',
  '/manifest.json',
  '/icon.svg'
];

// On install, cache the app shell
self.addEventListener('install', (evt) => {
  self.skipWaiting();
  evt.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS)).catch(err => console.warn('SW cache addAll failed', err))
  );
});

// Activate - cleanup old caches
self.addEventListener('activate', (evt) => {
  evt.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k))
    ))
  );
  self.clients.claim();
});

// Fetch - try network first for navigation; otherwise cache-first for assets
self.addEventListener('fetch', (evt) => {
  const req = evt.request;
  const url = new URL(req.url);

  // handle navigation requests: network first with fallback to cache/index.html
  if (req.mode === 'navigate' || (req.method === 'GET' && req.headers.get('accept')?.includes('text/html'))) {
    evt.respondWith(
      fetch(req).then(res => {
        // optionally update cache
        const copy = res.clone();
        caches.open(CACHE_NAME).then(c => c.put(req, copy));
        return res;
      }).catch(() => caches.match('/index.html'))
    );
    return;
  }

  // For other requests: serve from cache first, then network and cache it
  evt.respondWith(
    caches.match(req).then(cached => {
      if (cached) return cached;
      return fetch(req).then(networkRes => {
        // put in cache (only GET)
        if (req.method === 'GET') {
          const copy = networkRes.clone();
          caches.open(CACHE_NAME).then(c => c.put(req, copy));
        }
        return networkRes;
      }).catch(() => {
        // optional fallback for images
        if (req.destination === 'image') {
          return new Response('', { status: 404, statusText: 'offline' });
        }
        return new Response('Offline', { status: 503, statusText: 'Offline' });
      });
    })
  );
});