// Screencast Recorder + Annotator
// - capture screen via getDisplayMedia
// - composite video + annotation canvas onto a single canvas and record via MediaRecorder
// - support optional microphone mixing
// - live drawing overlay with undo/clear and adjustable color/size
// - snapshot and download recorded clips
// Notes: Runs entirely in the browser. Best on modern Chromium/Firefox.

(() => {
  // DOM
  const startCaptureBtn = document.getElementById('start-capture');
  const startRecordBtn = document.getElementById('start-record');
  const pauseRecordBtn = document.getElementById('pause-record');
  const resumeRecordBtn = document.getElementById('resume-record');
  const stopRecordBtn = document.getElementById('stop-record');
  const downloadBtn = document.getElementById('download');
  const snapshotBtn = document.getElementById('snapshot');
  const withMicChk = document.getElementById('with-mic');

  const previewVideo = document.getElementById('preview-video');
  const compositeCanvas = document.getElementById('composite-canvas');
  const drawCanvas = document.getElementById('draw-canvas');

  const colorInput = document.getElementById('color');
  const sizeInput = document.getElementById('size');
  const undoBtn = document.getElementById('undo');
  const clearBtn = document.getElementById('clear');

  const clipsList = document.getElementById('clips');

  // State
  let screenStream = null;
  let micStream = null;
  let combinedStream = null;
  let mediaRecorder = null;
  let recordedBlobs = [];
  let recording = false;
  let compositeCtx = compositeCanvas.getContext('2d');
  let drawCtx = drawCanvas.getContext('2d');
  let drawScale = 1;

  // Drawing state & history
  let drawing = false;
  let currentPath = null;
  let strokes = []; // array of paths: {color,size,points: [{x,y}, ...]}
  let undone = [];

  // Utility
  function uid() { return Date.now().toString(36) + Math.random().toString(36).slice(2,8); }
  function enable(...els){ els.forEach(e => e.disabled = false); }
  function disable(...els){ els.forEach(e => e.disabled = true); }

  // Initialize canvases to match visible area of preview
  function resizeCanvasesToVideo() {
    const vw = previewVideo.videoWidth || previewVideo.clientWidth || 1280;
    const vh = previewVideo.videoHeight || previewVideo.clientHeight || 720;
    // set canvas backing to video intrinsic resolution for crispness
    compositeCanvas.width = vw;
    compositeCanvas.height = vh;
    drawCanvas.width = vw;
    drawCanvas.height = vh;
    compositeCanvas.style.width = '100%';
    compositeCanvas.style.height = '100%';
    drawCanvas.style.width = '100%';
    drawCanvas.style.height = '100%';
    drawScale = compositeCanvas.width / drawCanvas.clientWidth;
    // copy current drawing to new sizes if needed
    redrawStrokes();
  }

  // Start screen capture (asks user permission)
  startCaptureBtn.addEventListener('click', async () => {
    try {
      screenStream = await navigator.mediaDevices.getDisplayMedia({ video: true, audio: true });
    } catch (err) {
      alert('Failed to capture screen: ' + (err.message || err));
      return;
    }
    // optional mic
    if (withMicChk.checked) {
      try {
        micStream = await navigator.mediaDevices.getUserMedia({ audio: true });
      } catch (err) {
        console.warn('Mic denied/failed:', err);
        micStream = null;
      }
    }
    // attach preview (show the raw screen so user sees source)
    previewVideo.srcObject = screenStream;
    previewVideo.muted = true;
    previewVideo.play().catch(() => {});
    previewVideo.onloadedmetadata = () => {
      resizeCanvasesToVideo();
      // start composite loop
      startCompositeLoop();
    };

    // enable record controls
    enable(startRecordBtn, snapshotBtn, clearBtn, undoBtn);
    startCaptureBtn.disabled = true;
  });

  // Composite loop: draw video frame then draw annotations on top into compositeCanvas
  let compositeRaf = null;
  function startCompositeLoop() {
    cancelAnimationFrame(compositeRaf);
    function drawLoop() {
      const w = compositeCanvas.width;
      const h = compositeCanvas.height;
      compositeCtx.clearRect(0,0,w,h);
      // draw video frame (cover)
      if (previewVideo.readyState >= 2) {
        compositeCtx.drawImage(previewVideo, 0, 0, w, h);
      }
      // draw annotations (drawCanvas) on top
      compositeCtx.drawImage(drawCanvas, 0, 0, w, h);
      compositeRaf = requestAnimationFrame(drawLoop);
    }
    compositeRaf = requestAnimationFrame(drawLoop);
  }

  // Recording
  startRecordBtn.addEventListener('click', async () => {
    if (!screenStream) return alert('No screen stream. Click "Start Capture" first.');
    // create a stream from composite canvas
    const canvasStream = compositeCanvas.captureStream(30); // 30fps
    const tracks = [];
    // take video track from canvas
    const vtrack = canvasStream.getVideoTracks()[0];
    if (vtrack) tracks.push(vtrack);

    // combine audio: screen stream may include system audio; prefer it, else fallback to mic
    const audioTracks = [];
    if (screenStream.getAudioTracks().length) {
      audioTracks.push(...screenStream.getAudioTracks());
    }
    if (micStream && micStream.getAudioTracks().length) {
      audioTracks.push(...micStream.getAudioTracks());
    }
    // create combined stream
    combinedStream = new MediaStream();
    tracks.forEach(t => combinedStream.addTrack(t));
    audioTracks.forEach(t => combinedStream.addTrack(t));

    // Create MediaRecorder
    recordedBlobs = [];
    const options = selectSupportedMime();
    try {
      mediaRecorder = new MediaRecorder(combinedStream, options);
    } catch (e) {
      alert('MediaRecorder not supported: ' + e);
      return;
    }

    mediaRecorder.ondataavailable = (ev) => { if (ev.data && ev.data.size) recordedBlobs.push(ev.data); };
    mediaRecorder.onstop = () => {
      const blob = new Blob(recordedBlobs, { type: recordedBlobs[0]?.type || 'video/webm' });
      addClip(blob);
      downloadBtn.disabled = false;
    };

    mediaRecorder.start(100); // emit every 100ms
    recording = true;
    startRecordBtn.disabled = true;
    pauseRecordBtn.disabled = false;
    stopRecordBtn.disabled = false;
    resumeRecordBtn.disabled = true;
    snapshotBtn.disabled = false;
    updateUIRecording(true);
  });

  pauseRecordBtn.addEventListener('click', () => {
    if (!mediaRecorder) return;
    if (mediaRecorder.state === 'recording') {
      mediaRecorder.pause();
      pauseRecordBtn.disabled = true;
      resumeRecordBtn.disabled = false;
      updateUIRecording(false, 'paused');
    }
  });
  resumeRecordBtn.addEventListener('click', () => {
    if (!mediaRecorder) return;
    if (mediaRecorder.state === 'paused') {
      mediaRecorder.resume();
      resumeRecordBtn.disabled = true;
      pauseRecordBtn.disabled = false;
      updateUIRecording(true);
    }
  });

  stopRecordBtn.addEventListener('click', () => {
    if (!mediaRecorder) return;
    mediaRecorder.stop();
    recording = false;
    pauseRecordBtn.disabled = true;
    resumeRecordBtn.disabled = true;
    stopRecordBtn.disabled = true;
    startRecordBtn.disabled = false;
    updateUIRecording(false, 'stopped');
    // stop canvas tracks when done? keep preview active so user can continue annotating
  });

  // MIME selection helper
  function selectSupportedMime() {
    const candidate = [
      { mimeType: 'video/webm;codecs=vp9,opus' },
      { mimeType: 'video/webm;codecs=vp8,opus' },
      { mimeType: 'video/webm' },
      { mimeType: '' }
    ];
    for (const opt of candidate) {
      try {
        if (!opt.mimeType || MediaRecorder.isTypeSupported(opt.mimeType)) return opt;
      } catch (e) { continue; }
    }
    return {};
  }

  // Snapshot
  snapshotBtn.addEventListener('click', () => {
    if (!compositeCanvas.width) return;
    compositeCanvas.toBlob((blob) => {
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = `screenshot-${new Date().toISOString().slice(0,19).replace(/[:T]/g,'-')}.png`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(a.href);
    }, 'image/png');
  });

  // Add recorded clip to list
  function addClip(blob) {
    const id = uid();
    const url = URL.createObjectURL(blob);
    const li = document.createElement('li');
    li.innerHTML = `
      <div style="flex:1;min-width:0">
        <div style="font-weight:700">Clip ${new Date().toLocaleString()}</div>
        <div style="font-size:12px;color:#64748b">${(blob.size/1024/1024).toFixed(2)} MB</div>
      </div>
      <div class="clip-actions">
        <button data-url="${url}" class="play-clip btn small">Play</button>
        <button data-url="${url}" class="download-clip btn small">Download</button>
        <button class="delete-clip btn small muted">Delete</button>
      </div>
    `;
    clipsList.prepend(li);

    li.querySelector('.play-clip').addEventListener('click', (e) => {
      const u = e.currentTarget.dataset.url;
      openClipPlayer(u);
    });
    li.querySelector('.download-clip').addEventListener('click', (e) => {
      const u = e.currentTarget.dataset.url;
      const a = document.createElement('a');
      a.href = u;
      a.download = `screencast-${new Date().toISOString().slice(0,19).replace(/[:T]/g,'-')}.webm`;
      document.body.appendChild(a);
      a.click();
      a.remove();
    });
    li.querySelector('.delete-clip').addEventListener('click', (e) => {
      if (!confirm('Delete clip?')) return;
      URL.revokeObjectURL(url);
      li.remove();
    });
  }

  // Open clip in a player overlay
  function openClipPlayer(url) {
    const overlay = document.createElement('div');
    Object.assign(overlay.style, {
      position: 'fixed', inset: '0', background: 'rgba(0,0,0,0.8)', display: 'flex',
      alignItems: 'center', justifyContent: 'center', zIndex: 9999
    });
    const v = document.createElement('video');
    v.src = url;
    v.controls = true;
    v.style.maxWidth = '90%';
    v.style.maxHeight = '90%';
    overlay.appendChild(v);
    overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove(); });
    document.body.appendChild(overlay);
    v.play().catch(()=>{});
  }

  // Drawing: pointer events on drawCanvas
  function getCanvasPos(evt) {
    const rect = drawCanvas.getBoundingClientRect();
    const x = (evt.clientX - rect.left) * (drawCanvas.width / rect.width);
    const y = (evt.clientY - rect.top) * (drawCanvas.height / rect.height);
    return { x, y };
  }

  drawCanvas.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    drawing = true;
    currentPath = { color: colorInput.value, size: Number(sizeInput.value), points: [] };
    const pt = getCanvasPos(e);
    currentPath.points.push(pt);
    drawPoint(pt.x, pt.y, currentPath.color, currentPath.size);
  });
  drawCanvas.addEventListener('pointermove', (e) => {
    if (!drawing) return;
    const pt = getCanvasPos(e);
    const last = currentPath.points[currentPath.points.length -1];
    // add only if moved enough to reduce points
    if (!last || Math.hypot(pt.x-last.x, pt.y-last.y) > 2) {
      currentPath.points.push(pt);
      drawStrokeSegment(last, pt, currentPath.color, currentPath.size);
    }
  });
  drawCanvas.addEventListener('pointerup', (e) => {
    if (!drawing) return;
    drawing = false;
    strokes.push(currentPath);
    currentPath = null;
    undone = [];
    updateUndoClearButtons();
  });
  drawCanvas.addEventListener('pointercancel', () => {
    drawing = false;
    currentPath = null;
  });

  function drawPoint(x,y,color,size) {
    drawCtx.fillStyle = color;
    drawCtx.beginPath();
    drawCtx.arc(x, y, size/2, 0, Math.PI*2);
    drawCtx.fill();
  }
  function drawStrokeSegment(a,b,color,size) {
    if (!a || !b) return;
    drawCtx.strokeStyle = color;
    drawCtx.lineWidth = size;
    drawCtx.lineCap = 'round';
    drawCtx.lineJoin = 'round';
    drawCtx.beginPath();
    drawCtx.moveTo(a.x, a.y);
    drawCtx.lineTo(b.x, b.y);
    drawCtx.stroke();
  }

  function redrawStrokes() {
    drawCtx.clearRect(0,0,drawCanvas.width, drawCanvas.height);
    for (const s of strokes) {
      if (!s.points.length) continue;
      drawCtx.lineCap = 'round';
      drawCtx.lineJoin = 'round';
      drawCtx.strokeStyle = s.color;
      drawCtx.lineWidth = s.size;
      drawCtx.beginPath();
      drawCtx.moveTo(s.points[0].x, s.points[0].y);
      for (let i=1;i<s.points.length;i++) {
        const p = s.points[i];
        drawCtx.lineTo(p.x, p.y);
      }
      drawCtx.stroke();
    }
  }

  // Undo / Clear
  undoBtn.addEventListener('click', () => {
    if (!strokes.length) return;
    const s = strokes.pop();
    undone.push(s);
    redrawStrokes();
    updateUndoClearButtons();
  });
  clearBtn.addEventListener('click', () => {
    if (!strokes.length) return;
    if (!confirm('Clear all annotations?')) return;
    strokes = [];
    undone = [];
    redrawStrokes();
    updateUndoClearButtons();
  });

  function updateUndoClearButtons() {
    undoBtn.disabled = strokes.length === 0;
    clearBtn.disabled = strokes.length === 0;
  }

  // Update UI based on recording state
  function updateUIRecording(isRecording, stateText = '') {
    // visual hint: border color
    previewVideo.style.outline = isRecording ? '4px solid rgba(16,185,129,0.15)' : '';
  }

  // Stop all tracks (call when user wants to stop capture completely)
  async function stopCapture() {
    if (screenStream) {
      screenStream.getTracks().forEach(t => t.stop());
      screenStream = null;
    }
    if (micStream) {
      micStream.getTracks().forEach(t => t.stop());
      micStream = null;
    }
    previewVideo.srcObject = null;
    cancelAnimationFrame(compositeRaf);
    compositeCtx.clearRect(0,0,compositeCanvas.width, compositeCanvas.height);
    drawCtx.clearRect(0,0,drawCanvas.width, drawCanvas.height);
    startCaptureBtn.disabled = false;
    startRecordBtn.disabled = true;
    pauseRecordBtn.disabled = true;
    stopRecordBtn.disabled = true;
    snapshotBtn.disabled = true;
  }

  // Download last recording (if exists)
  downloadBtn.addEventListener('click', () => {
    if (!recordedBlobs || !recordedBlobs.length) return alert('No recording available.');
    const blob = new Blob(recordedBlobs, { type: recordedBlobs[0].type || 'video/webm' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `screencast-${new Date().toISOString().slice(0,19).replace(/[:T]/g,'-')}.webm`;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  });

  // Clean up when page unloads
  window.addEventListener('beforeunload', () => {
    stopCapture();
  });

  // initial UI state
  disable(startRecordBtn, pauseRecordBtn, resumeRecordBtn, stopRecordBtn, downloadBtn, snapshotBtn);
  updateUndoClearButtons();

  // small helpers for testing
  window._screencast_debug = {
    getStrokes: () => strokes,
    getRecordedBlobs: () => recordedBlobs
  };
})();