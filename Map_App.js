// Map App (Leaflet) — script.js
// Features:
// - Display map (OpenStreetMap tiles)
// - Click map to add marker (prompt for title/description)
// - Edit / delete markers via popup or sidebar list
// - Geolocation "Locate me"
// - Search (Nominatim) with basic results and pan-to
// - Marker clustering (Leaflet.markercluster)
// - Persist markers to localStorage and export/import GeoJSON

(function () {
  const STORAGE_KEY = 'leaflet-markers:v1';

  // DOM
  const mapEl = document.getElementById('map');
  const searchInput = document.getElementById('search-input');
  const locateBtn = document.getElementById('locate-btn');
  const exportBtn = document.getElementById('export-btn');
  const importBtn = document.getElementById('import-btn');
  const importFile = document.getElementById('import-file');
  const clearBtn = document.getElementById('clear-btn');
  const markerListEl = document.getElementById('marker-list');

  // State
  let map, markers = [], markerLayer, clusterGroup;

  // Helpers
  function uid() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
  }

  function saveMarkers() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(markers));
    } catch (e) {
      console.warn('Failed to save markers', e);
    }
  }

  function loadMarkers() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return [];
      return JSON.parse(raw);
    } catch (e) {
      console.warn('Failed to load markers', e);
      return [];
    }
  }

  function formatDate(ts) {
    return new Date(ts).toLocaleString();
  }

  // Initialize map
  function initMap() {
    map = L.map('map').setView([20, 0], 2);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(map);

    // Marker cluster group
    clusterGroup = L.markerClusterGroup();
    markerLayer = L.layerGroup();
    clusterGroup.addLayer(markerLayer);
    map.addLayer(clusterGroup);

    // Load persisted markers
    markers = loadMarkers();
    markers.forEach(m => addMarkerToMap(m, { save: false }));

    // Click to add marker
    map.on('click', onMapClick);
  }

  function onMapClick(e) {
    const lat = e.latlng.lat;
    const lng = e.latlng.lng;
    // prompt for title/description (simple)
    const title = prompt('Marker title (leave empty for "Untitled")', '');
    if (title === null) return; // user cancelled
    const desc = prompt('Description (optional)', '') || '';
    const obj = {
      id: uid(),
      lat,
      lng,
      title: title.trim() || 'Untitled',
      description: desc.trim(),
      createdAt: Date.now(),
    };
    markers.push(obj);
    addMarkerToMap(obj, { save: true, openPopup: true });
    refreshSidebar();
    saveMarkers();
  }

  // Create Leaflet marker and attach popup with edit/delete controls
  function addMarkerToMap(m, opts = {}) {
    const marker = L.marker([m.lat, m.lng], { title: m.title, riseOnHover: true });
    const popupHtml = createPopupHtml(m);
    marker.bindPopup(popupHtml);
    marker.on('popupopen', () => {
      // wire popup buttons
      setTimeout(() => {
        const editBtn = document.getElementById('edit-' + m.id);
        const delBtn = document.getElementById('del-' + m.id);
        if (editBtn) editBtn.addEventListener('click', () => openEditDialog(m.id));
        if (delBtn) delBtn.addEventListener('click', () => deleteMarker(m.id));
      }, 10);
    });
    marker._metaId = m.id;

    clusterGroup.addLayer(marker);

    // If options ask to open popup after add
    if (opts.openPopup) marker.openPopup();
    return marker;
  }

  function createPopupHtml(m) {
    // include buttons with ids to attach events once popup opens
    const title = escapeHtml(m.title || '');
    const desc = escapeHtml(m.description || '');
    const date = formatDate(m.createdAt || Date.now());
    return `<div class="popup">
      <strong>${title}</strong>
      <div style="margin-top:6px;font-size:13px">${desc}</div>
      <div style="margin-top:8px;font-size:12px;color:#666">${date}</div>
      <div style="margin-top:8px">
        <button id="edit-${m.id}">Edit</button>
        <button id="del-${m.id}">Delete</button>
      </div>
    </div>`;
  }

  function escapeHtml(s) {
    return String(s || '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  }

  // When editing, we prompt for new title/description
  function openEditDialog(id) {
    const idx = markers.findIndex(x => x.id === id);
    if (idx === -1) return;
    const m = markers[idx];
    const newTitle = prompt('Edit title', m.title);
    if (newTitle === null) return;
    const newDesc = prompt('Edit description', m.description);
    if (newDesc === null) return;
    m.title = newTitle.trim() || 'Untitled';
    m.description = newDesc.trim();
    m.updatedAt = Date.now();
    // re-render markers on map
    reloadAllMarkers();
    saveMarkers();
    refreshSidebar();
  }

  function deleteMarker(id) {
    if (!confirm('Delete this marker?')) return;
    markers = markers.filter(m => m.id !== id);
    reloadAllMarkers();
    saveMarkers();
    refreshSidebar();
  }

  function reloadAllMarkers() {
    // remove all from cluster and re-add
    clusterGroup.clearLayers();
    markers.forEach(m => addMarkerToMap(m));
  }

  // Sidebar list render
  function refreshSidebar() {
    markerListEl.innerHTML = '';
    if (markers.length === 0) {
      markerListEl.textContent = 'No markers. Click map to add one.';
      return;
    }
    // newest first
    const list = markers.slice().sort((a, b) => (b.createdAt || 0) - (a.createdAt || 0));
    list.forEach(m => {
      const div = document.createElement('div');
      div.className = 'marker-item';
      div.innerHTML = `
        <div>
          <div style="font-weight:700">${escapeHtml(m.title)}</div>
          <div class="meta">${formatDate(m.createdAt || 0)} • ${m.lat.toFixed(5)}, ${m.lng.toFixed(5)}</div>
        </div>
        <div class="marker-actions">
          <button class="edit" data-id="${m.id}">Edit</button>
          <button class="del" data-id="${m.id}">Del</button>
          <button class="pan" data-id="${m.id}">Pan</button>
        </div>
      `;
      markerListEl.appendChild(div);
    });

    // attach events
    markerListEl.querySelectorAll('button.edit').forEach(btn => {
      btn.addEventListener('click', (e) => openEditDialog(btn.dataset.id));
    });
    markerListEl.querySelectorAll('button.del').forEach(btn => {
      btn.addEventListener('click', (e) => deleteMarker(btn.dataset.id));
    });
    markerListEl.querySelectorAll('button.pan').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const id = btn.dataset.id;
        const m = markers.find(x => x.id === id);
        if (!m) return;
        map.setView([m.lat, m.lng], 16, { animate: true });
      });
    });
  }

  // Locate user
  function locateUser() {
    if (!navigator.geolocation) {
      alert('Geolocation not supported in this browser.');
      return;
    }
    locateBtn.disabled = true;
    navigator.geolocation.getCurrentPosition((pos) => {
      const lat = pos.coords.latitude;
      const lng = pos.coords.longitude;
      map.setView([lat, lng], 14);
      // optional: add a temporary marker for location
      const locMarker = L.circleMarker([lat, lng], { radius: 8, color: '#2b8aef', fillColor: '#2b8aef', fillOpacity: 0.6 });
      locMarker.addTo(map);
      setTimeout(() => map.removeLayer(locMarker), 4000);
      locateBtn.disabled = false;
    }, (err) => {
      alert('Unable to retrieve location: ' + (err.message || 'error'));
      locateBtn.disabled = false;
    }, { enableHighAccuracy: true, timeout: 8000 });
  }

  // Search (Nominatim)
  async function searchPlace(q) {
    if (!q) return;
    const url = 'https://nominatim.openstreetmap.org/search?format=jsonv2&q=' + encodeURIComponent(q);
    try {
      const res = await fetch(url, { headers: { 'Accept-Language': 'en' } });
      if (!res.ok) throw new Error('Search failed');
      const data = await res.json();
      return data; // array of results
    } catch (e) {
      console.warn('Search error', e);
      return [];
    }
  }

  // Handle search input (Enter)
  function setupSearch() {
    searchInput.addEventListener('keydown', async (e) => {
      if (e.key === 'Enter') {
        const q = searchInput.value.trim();
        if (!q) return;
        searchInput.disabled = true;
        const results = await searchPlace(q);
        searchInput.disabled = false;
        if (!results || results.length === 0) {
          alert('No results found.');
          return;
        }
        // show first 5 results in a small prompt-like list for selection
        const choices = results.slice(0, 6);
        let msg = 'Select a result:\n';
        choices.forEach((r, i) => {
          msg += `${i+1}) ${r.display_name}\n`;
        });
        msg += '\nEnter number to pan, or Cancel.';
        const pick = prompt(msg, '1');
        if (pick === null) return;
        const n = Number(pick);
        if (Number.isNaN(n) || n < 1 || n > choices.length) {
          alert('Invalid choice');
          return;
        }
        const sel = choices[n-1];
        const lat = Number(sel.lat);
        const lon = Number(sel.lon);
        map.setView([lat, lon], 14);
        // Also ask if user wants to add a marker at that spot
        if (confirm('Add marker at this location?')) {
          const title = prompt('Marker title', sel.display_name.split(',')[0] || 'Place');
          const obj = {
            id: uid(),
            lat,
            lng: lon,
            title: title ? title.trim() : (sel.display_name || 'Place'),
            description: sel.display_name || '',
            createdAt: Date.now(),
          };
          markers.push(obj);
          addMarkerToMap(obj, { save: true, openPopup: true });
          refreshSidebar();
          saveMarkers();
        }
      }
    });
  }

  // Export GeoJSON
  function exportGeoJSON() {
    const features = markers.map(m => ({
      type: 'Feature',
      properties: {
        id: m.id,
        title: m.title,
        description: m.description,
        createdAt: m.createdAt,
      },
      geometry: {
        type: 'Point',
        coordinates: [m.lng, m.lat],
      },
    }));
    const geojson = {
      type: 'FeatureCollection',
      features,
    };
    const blob = new Blob([JSON.stringify(geojson, null, 2)], { type: 'application/geo+json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `markers-${new Date().toISOString().slice(0,19).replace(/[:T]/g,'-')}.geojson`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  // Import GeoJSON or simple array format
  function handleImportFile(file) {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      try {
        const json = JSON.parse(ev.target.result);
        if (json.type === 'FeatureCollection' && Array.isArray(json.features)) {
          const imported = json.features.map(f => {
            const coords = f.geometry && f.geometry.coordinates;
            const props = f.properties || {};
            return {
              id: props.id || uid(),
              lat: coords ? Number(coords[1]) : 0,
              lng: coords ? Number(coords[0]) : 0,
              title: props.title || props.name || (props.id || 'Imported'),
              description: props.description || '',
              createdAt: props.createdAt || Date.now(),
            };
          });
          markers = markers.concat(imported);
        } else if (Array.isArray(json)) {
          // assume array of {lat,lng,title,description}
          const imported = json.map(it => ({
            id: it.id || uid(),
            lat: Number(it.lat),
            lng: Number(it.lng),
            title: it.title || 'Imported',
            description: it.description || '',
            createdAt: it.createdAt || Date.now(),
          }));
          markers = markers.concat(imported);
        } else {
          alert('Unsupported file format');
          return;
        }
        reloadAllMarkers();
        saveMarkers();
        refreshSidebar();
        alert('Import successful');
      } catch (err) {
        console.error(err);
        alert('Failed to import: ' + err.message);
      }
    };
    reader.readAsText(file);
  }

  // Clear markers
  function clearAllMarkers() {
    if (!confirm('Remove all markers?')) return;
    markers = [];
    reloadAllMarkers();
    saveMarkers();
    refreshSidebar();
  }

  // Wire UI events
  function wireUI() {
    locateBtn.addEventListener('click', locateUser);
    exportBtn.addEventListener('click', exportGeoJSON);
    importBtn.addEventListener('click', () => importFile.click());
    importFile.addEventListener('change', (e) => {
      const file = e.target.files && e.target.files[0];
      handleImportFile(file);
      importFile.value = '';
    });
    clearBtn.addEventListener('click', clearAllMarkers);
  }

  // Init
  function init() {
    initMap();
    refreshSidebar();
    setupSearch();
    wireUI();
  }

  // run
  init();

  // Expose for debugging
  window.mapApp = {
    getMarkers: () => markers.slice(),
    addMarker: (m) => { markers.push(m); addMarkerToMap(m); saveMarkers(); refreshSidebar(); },
    clear: clearAllMarkers,
  };
})();