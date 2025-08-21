// Music Player (Local Files)
// Features:
// - add local audio files via file input or drag-and-drop
// - playlist with play / prev / next / seek / volume / shuffle / repeat
// - keyboard shortcuts (Space, arrows)
// - WebAudio analyser visualizer
// - Media Session integration for lock screen controls
// Notes: File objects can't be persisted across reloads; object URLs are session-bound.

(() => {
  // DOM
  const fileInput = document.getElementById('file-input');
  const dropZone = document.getElementById('drop-zone');
  const playlistEl = document.getElementById('playlist');
  const audio = document.getElementById('audio');

  const playBtn = document.getElementById('play');
  const pauseBtn = document.getElementById('pause');
  const prevBtn = document.getElementById('prev');
  const nextBtn = document.getElementById('next');
  const seekEl = document.getElementById('seek');
  const currentTimeEl = document.getElementById('current-time');
  const durationEl = document.getElementById('duration');
  const volumeEl = document.getElementById('volume');
  const repeatEl = document.getElementById('repeat');
  const shuffleEl = document.getElementById('shuffle');
  const trackTitleEl = document.getElementById('track-title');
  const trackMetaEl = document.getElementById('track-meta');
  const clearPlaylistBtn = document.getElementById('clear-playlist');

  const canvas = document.getElementById('vis');
  const ctx = canvas.getContext('2d');

  // State
  let playlist = []; // {id, name, url, file, duration?}
  let currentIndex = -1;
  let isPlaying = false;
  let rafId = null;
  let audioContext = null;
  let analyser = null;
  let sourceNode = null;

  // Helpers
  function uid() { return Date.now().toString(36) + Math.random().toString(36).slice(2,8); }
  function formatTime(sec) {
    if (!Number.isFinite(sec)) return '00:00';
    const s = Math.floor(sec);
    const m = Math.floor(s / 60);
    const r = s % 60;
    return `${String(m).padStart(2,'0')}:${String(r).padStart(2,'0')}`;
  }

  // Playlist rendering
  function renderPlaylist() {
    playlistEl.innerHTML = '';
    if (!playlist.length) {
      const li = document.createElement('li');
      li.className = 'playlist-item';
      li.textContent = 'No tracks yet.';
      playlistEl.appendChild(li);
      return;
    }
    playlist.forEach((t, i) => {
      const li = document.createElement('li');
      li.className = 'playlist-item';
      if (i === currentIndex) li.classList.add('active');
      li.dataset.index = i;
      li.innerHTML = `
        <div>
          <div style="font-weight:700">${escapeHtml(t.name)}</div>
          <div style="font-size:12px;color:#64748b">${t.file ? (t.file.type || '') : ''}</div>
        </div>
        <div style="display:flex;gap:8px;align-items:center">
          <button class="small-play">▶</button>
          <button class="small-remove" title="Remove">✕</button>
        </div>
      `;
      li.querySelector('.small-play').addEventListener('click', (e) => {
        e.stopPropagation();
        playIndex(i);
      });
      li.querySelector('.small-remove').addEventListener('click', (e) => {
        e.stopPropagation();
        removeIndex(i);
      });
      li.addEventListener('dblclick', () => playIndex(i));
      playlistEl.appendChild(li);
    });
  }

  function escapeHtml(s){ return String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;'); }

  // Add files from FileList
  function addFiles(files) {
    const arr = Array.from(files).filter(f => f.type.startsWith('audio/') || /\.mp3|\.wav|\.ogg|\.m4a$/i.test(f.name));
    arr.forEach(f => {
      const id = uid();
      const url = URL.createObjectURL(f);
      playlist.push({ id, name: f.name, url, file: f });
    });
    renderPlaylist();
    if (currentIndex === -1 && playlist.length) {
      playIndex(0);
    }
  }

  // Remove a track
  function removeIndex(i) {
    const p = playlist[i];
    if (!p) return;
    // revoke objectURL if exists
    try { URL.revokeObjectURL(p.url); } catch(e){}
    playlist.splice(i,1);
    if (i === currentIndex) {
      stop();
      currentIndex = -1;
      if (playlist.length) playIndex(Math.min(i, playlist.length-1));
    } else if (i < currentIndex) {
      currentIndex--;
    }
    renderPlaylist();
  }

  // Clear playlist
  clearPlaylistBtn.addEventListener('click', () => {
    if (!confirm('Clear playlist?')) return;
    playlist.forEach(p => { try { URL.revokeObjectURL(p.url); } catch(e){} });
    playlist = [];
    currentIndex = -1;
    stop();
    renderPlaylist();
  });

  // Play / Pause / Prev / Next
  function playIndex(i) {
    if (i < 0 || i >= playlist.length) return;
    currentIndex = i;
    const t = playlist[i];
    loadTrack(t);
    play();
    renderPlaylist();
  }

  function loadTrack(t) {
    audio.src = t.url;
    trackTitleEl.textContent = t.name;
    trackMetaEl.textContent = t.file ? `${Math.round((t.file.size||0)/1024)} KB` : '';
    // prepare analyser
    setupAnalyser();
    // update media session metadata
    if ('mediaSession' in navigator) {
      try {
        navigator.mediaSession.metadata = new MediaMetadata({
          title: t.name,
          artist: t.file && t.file.type ? t.file.type : '',
        });
      } catch (e) {}
    }
  }

  function play() {
    if (!audio.src) {
      if (playlist.length) playIndex(0);
      return;
    }
    audio.play().then(() => {
      isPlaying = true;
      playBtn.classList.add('hidden');
      pauseBtn.classList.remove('hidden');
      startVisualizer();
      updateMediaSessionPlaybackState();
    }).catch(err => {
      console.warn('Play failed', err);
    });
  }

  function pause() {
    audio.pause();
    isPlaying = false;
    playBtn.classList.remove('hidden');
    pauseBtn.classList.add('hidden');
    stopVisualizer();
    updateMediaSessionPlaybackState();
  }

  function stop() {
    pause();
    audio.currentTime = 0;
    updateSeekUI();
  }

  function prev() {
    if (!playlist.length) return;
    if (audio.currentTime > 3) {
      audio.currentTime = 0;
    } else {
      const idx = (currentIndex - 1 + playlist.length) % playlist.length;
      playIndex(idx);
    }
  }

  function next() {
    if (!playlist.length) return;
    let idx;
    if (shuffleEl.checked) {
      idx = Math.floor(Math.random() * playlist.length);
    } else {
      idx = (currentIndex + 1) % playlist.length;
    }
    playIndex(idx);
  }

  // Seek UI
  function updateSeekUI() {
    const dur = audio.duration || 0;
    const cur = audio.currentTime || 0;
    durationEl.textContent = formatTime(dur);
    currentTimeEl.textContent = formatTime(cur);
    seekEl.max = Math.floor(dur) || 0;
    seekEl.value = Math.floor(cur);
  }

  seekEl.addEventListener('input', () => {
    audio.currentTime = Number(seekEl.value);
  });

  // Volume
  volumeEl.addEventListener('input', () => {
    audio.volume = Number(volumeEl.value);
  });

  // audio events
  audio.addEventListener('timeupdate', updateSeekUI);
  audio.addEventListener('loadedmetadata', updateSeekUI);
  audio.addEventListener('ended', () => {
    if (repeatEl.checked) {
      audio.currentTime = 0;
      play();
    } else {
      next();
    }
  });

  // File input & drag/drop
  fileInput.addEventListener('change', (e) => {
    addFiles(e.target.files);
    fileInput.value = '';
  });

  dropZone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropZone.classList.add('dragover');
  });
  dropZone.addEventListener('dragleave', (e) => {
    dropZone.classList.remove('dragover');
  });
  dropZone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropZone.classList.remove('dragover');
    addFiles(e.dataTransfer.files);
  });

  // Buttons
  playBtn.addEventListener('click', play);
  pauseBtn.addEventListener('click', pause);
  prevBtn.addEventListener('click', prev);
  nextBtn.addEventListener('click', next);

  // Keyboard shortcuts
  window.addEventListener('keydown', (e) => {
    if (e.code === 'Space' && !isTyping(e)) {
      e.preventDefault();
      if (isPlaying) pause();
      else play();
    } else if (e.code === 'ArrowRight') {
      audio.currentTime = Math.min((audio.currentTime||0) + 5, audio.duration || 0);
    } else if (e.code === 'ArrowLeft') {
      audio.currentTime = Math.max((audio.currentTime||0) - 5, 0);
    } else if (e.code === 'ArrowUp') {
      volumeEl.value = Math.min(Number(volumeEl.value) + 0.05, 1).toFixed(2);
      audio.volume = Number(volumeEl.value);
    } else if (e.code === 'ArrowDown') {
      volumeEl.value = Math.max(Number(volumeEl.value) - 0.05, 0).toFixed(2);
      audio.volume = Number(volumeEl.value);
    } else if (e.code === 'KeyS' && (e.ctrlKey || e.metaKey)) {
      // Ctrl/Cmd+S export playlist metadata
      e.preventDefault();
      exportPlaylist();
    }
  });

  function isTyping(e) {
    const tag = (document.activeElement && document.activeElement.tagName) || '';
    return tag === 'INPUT' || tag === 'TEXTAREA';
  }

  // Visualizer using WebAudio Analyser
  function setupAnalyser() {
    try {
      if (!audioContext) audioContext = new (window.AudioContext || window.webkitAudioContext)();
      if (sourceNode) {
        try { sourceNode.disconnect(); } catch(e){}
      }
      sourceNode = audioContext.createMediaElementSource(audio);
      analyser = audioContext.createAnalyser();
      analyser.fftSize = 256;
      sourceNode.connect(analyser);
      analyser.connect(audioContext.destination);
    } catch (e) {
      console.warn('WebAudio init failed', e);
      analyser = null;
    }
  }

  function startVisualizer() {
    if (!analyser) return;
    const bufferLength = analyser.frequencyBinCount;
    const data = new Uint8Array(bufferLength);
    const cw = canvas.width = canvas.clientWidth * devicePixelRatio;
    const ch = canvas.height = canvas.clientHeight * devicePixelRatio;
    ctx.clearRect(0,0,cw,ch);

    function draw() {
      analyser.getByteFrequencyData(data);
      ctx.clearRect(0,0,cw,ch);
      const barWidth = cw / bufferLength;
      for (let i = 0; i < bufferLength; i++) {
        const v = data[i] / 255;
        const h = v * ch;
        const x = i * barWidth;
        ctx.fillStyle = `hsl(${(i / bufferLength) * 240}, 80%, ${20 + v*50}%)`;
        ctx.fillRect(x, ch - h, barWidth*0.9, h);
      }
      rafId = requestAnimationFrame(draw);
    }
    if (!rafId) draw();
  }

  function stopVisualizer() {
    if (rafId) {
      cancelAnimationFrame(rafId);
      rafId = null;
    }
    // clear canvas
    const cw = canvas.width = canvas.clientWidth * devicePixelRatio;
    const ch = canvas.height = canvas.clientHeight * devicePixelRatio;
    ctx.clearRect(0,0,cw,ch);
  }

  // Media Session API
  function updateMediaSessionPlaybackState() {
    if (!('mediaSession' in navigator)) return;
    navigator.mediaSession.playbackState = isPlaying ? 'playing' : 'paused';
  }
  if ('mediaSession' in navigator) {
    navigator.mediaSession.setActionHandler('play', () => play());
    navigator.mediaSession.setActionHandler('pause', () => pause());
    navigator.mediaSession.setActionHandler('previoustrack', () => prev());
    navigator.mediaSession.setActionHandler('nexttrack', () => next());
    navigator.mediaSession.setActionHandler('seekbackward', (details) => {
      const skip = (details && details.seekOffset) || 10;
      audio.currentTime = Math.max((audio.currentTime||0) - skip, 0);
    });
    navigator.mediaSession.setActionHandler('seekforward', (details) => {
      const skip = (details && details.seekOffset) || 10;
      audio.currentTime = Math.min((audio.currentTime||0) + skip, audio.duration || 0);
    });
  }

  // Export playlist metadata (file names, not files)
  function exportPlaylist() {
    if (!playlist.length) { alert('No tracks to export.'); return; }
    const data = playlist.map(p => ({ name: p.name }));
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `playlist-${new Date().toISOString().slice(0,19)}.json`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  // Load sample audio via URL (optional helper) — commented out
  // function addSample(url, name) {
  //   const id = uid();
  //   playlist.push({ id, name: name || url.split('/').pop(), url, file: null });
  //   renderPlaylist();
  // }

  // Handle audio errors gracefully
  audio.addEventListener('error', (e) => {
    console.error('Audio error', e);
    alert('Failed to play track. It may be an unsupported format.');
    next();
  });

  // initial UI state
  renderPlaylist();
  audio.volume = Number(volumeEl.value);

  // Expose for debugging
  window.localMusicPlayer = {
    addFiles,
    playlist,
    playIndex,
    play, pause, next, prev
  };
})();