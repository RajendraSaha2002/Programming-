// Photo Editor (Canvas)
// - load local image
// - live filter preview (brightness, contrast, saturate) using ctx.filter
// - Apply filters to commit them to pixels
// - rotate 90° left/right
// - crop mode with rectangular selection (overlay canvas)
// - undo / redo (history of dataURLs)
// - export/download final image
// Notes: object URLs and images live in-memory; for large images use caution.

(() => {
  // DOM
  const fileInput = document.getElementById('file-input');
  const editorCanvas = document.getElementById('editor-canvas');
  const overlayCanvas = document.getElementById('overlay-canvas');
  const canvasStage = document.getElementById('canvas-stage');
  const imageInfo = document.getElementById('image-info');

  const brightness = document.getElementById('brightness');
  const contrast = document.getElementById('contrast');
  const saturate = document.getElementById('saturate');
  const bval = document.getElementById('bval');
  const cval = document.getElementById('cval');
  const sval = document.getElementById('sval');

  const applyFiltersBtn = document.getElementById('apply-filters');
  const revertFiltersBtn = document.getElementById('revert-filters');
  const rotateLeftBtn = document.getElementById('rotate-left');
  const rotateRightBtn = document.getElementById('rotate-right');
  const cropToggleBtn = document.getElementById('crop-toggle');
  const applyCropBtn = document.getElementById('apply-crop');
  const cancelCropBtn = document.getElementById('cancel-crop');

  const downloadBtn = document.getElementById('download');
  const undoBtn = document.getElementById('undo');
  const redoBtn = document.getElementById('redo');
  const resetBtn = document.getElementById('reset');

  // Canvas contexts
  const ctx = editorCanvas.getContext('2d', { willReadFrequently: false });
  const octx = overlayCanvas.getContext('2d');

  // State
  let baseImage = null; // HTMLImageElement representing the committed pixels
  let displayScale = 1; // css scale for display convenience
  let filterState = { brightness: 100, contrast: 100, saturate: 100 };
  let cropMode = false;
  let selection = null; // { x,y,w,h } in image coordinates
  let dragging = false;
  let dragStart = null;

  // History
  const history = [];
  let historyIndex = -1;

  // Helpers
  function uid() { return Date.now().toString(36) + Math.random().toString(36).slice(2,8); }

  function pushHistory(dataURL) {
    // trim forward history
    history.splice(historyIndex + 1);
    history.push(dataURL);
    historyIndex = history.length - 1;
    updateHistoryButtons();
  }

  function updateHistoryButtons() {
    undoBtn.disabled = historyIndex <= 0;
    redoBtn.disabled = historyIndex >= history.length - 1;
  }

  function restoreFromDataURL(dataURL) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => {
        setBaseImage(img);
        resolve();
      };
      img.onerror = reject;
      img.src = dataURL;
    });
  }

  function setBaseImage(img) {
    baseImage = img;
    // size canvases to image natural size and scale down for display if too wide
    const maxWidth = Math.min(900, window.innerWidth - 380); // leave room for controls
    const scale = Math.min(1, maxWidth / img.naturalWidth);
    displayScale = scale || 1;

    const w = Math.round(img.naturalWidth * displayScale);
    const h = Math.round(img.naturalHeight * displayScale);

    editorCanvas.width = img.naturalWidth;
    editorCanvas.height = img.naturalHeight;
    overlayCanvas.width = img.naturalWidth;
    overlayCanvas.height = img.naturalHeight;

    editorCanvas.style.width = w + 'px';
    editorCanvas.style.height = h + 'px';
    overlayCanvas.style.width = w + 'px';
    overlayCanvas.style.height = h + 'px';

    drawPreview(); // draw committed image
    imageInfo.textContent = `${img.naturalWidth}×${img.naturalHeight}px`;
  }

  // Draw the baseImage with current live filters
  function drawPreview() {
    if (!baseImage) {
      ctx.clearRect(0,0,editorCanvas.width, editorCanvas.height);
      return;
    }
    // Use ctx.filter for live preview
    const f = `brightness(${filterState.brightness}%) contrast(${filterState.contrast}%) saturate(${filterState.saturate}%)`;
    ctx.save();
    ctx.filter = f;
    ctx.clearRect(0,0,editorCanvas.width, editorCanvas.height);
    ctx.drawImage(baseImage, 0, 0, editorCanvas.width, editorCanvas.height);
    ctx.restore();
    // overlay selection if cropMode
    drawOverlay();
  }

  function commitFiltersToImage() {
    if (!baseImage) return;
    // draw with filters into temp canvas (same size as image)
    const tmp = document.createElement('canvas');
    tmp.width = editorCanvas.width;
    tmp.height = editorCanvas.height;
    const tctx = tmp.getContext('2d');
    tctx.filter = `brightness(${filterState.brightness}%) contrast(${filterState.contrast}%) saturate(${filterState.saturate}%)`;
    tctx.drawImage(baseImage, 0, 0, tmp.width, tmp.height);
    // create new image from dataURL and set as baseImage
    const dataURL = tmp.toDataURL('image/png');
    const img = new Image();
    img.onload = () => {
      setBaseImage(img);
      pushHistory(dataURL);
    };
    img.src = dataURL;
  }

  function rotateImage(direction = 'right') {
    if (!baseImage) return;
    const w = editorCanvas.width, h = editorCanvas.height;
    const tmp = document.createElement('canvas');
    tmp.width = h;
    tmp.height = w;
    const tctx = tmp.getContext('2d');
    if (direction === 'right') {
      tctx.translate(tmp.width, 0);
      tctx.rotate(Math.PI/2);
    } else {
      tctx.translate(0, tmp.height);
      tctx.rotate(-Math.PI/2);
    }
    // draw current preview (with filters)
    tctx.filter = `brightness(${filterState.brightness}%) contrast(${filterState.contrast}%) saturate(${filterState.saturate}%)`;
    tctx.drawImage(baseImage, 0, 0, w, h);
    const dataURL = tmp.toDataURL('image/png');
    const img = new Image();
    img.onload = () => {
      // reset filters after rotation (they've been baked)
      filterState = { brightness: 100, contrast: 100, saturate: 100 };
      resetFilterInputs();
      setBaseImage(img);
      pushHistory(dataURL);
    };
    img.src = dataURL;
  }

  // Crop selection overlay
  function clearOverlay() {
    octx.clearRect(0,0,overlayCanvas.width, overlayCanvas.height);
  }

  function drawOverlay() {
    clearOverlay();
    if (cropMode && selection) {
      octx.save();
      octx.strokeStyle = 'rgba(255,255,255,0.9)';
      octx.lineWidth = 2;
      octx.setLineDash([6,4]);
      octx.strokeRect(selection.x + 0.5, selection.y + 0.5, selection.w - 1, selection.h - 1);
      // semi-transparent fill outside selection
      octx.fillStyle = 'rgba(0,0,0,0.25)';
      // top
      octx.fillRect(0,0,overlayCanvas.width, selection.y);
      // left
      octx.fillRect(0, selection.y, selection.x, selection.h);
      // right
      octx.fillRect(selection.x + selection.w, selection.y, overlayCanvas.width - selection.x - selection.w, selection.h);
      // bottom
      octx.fillRect(0, selection.y + selection.h, overlayCanvas.width, overlayCanvas.height - selection.y - selection.h);
      octx.restore();
    }
  }

  function startCropMode() {
    if (!baseImage) return;
    cropMode = true;
    cropToggleBtn.textContent = 'Crop mode (ON)';
    applyCropBtn.disabled = true;
    cancelCropBtn.disabled = false;
    overlayCanvas.style.pointerEvents = 'auto';
    selection = null;
    drawOverlay();
  }

  function stopCropMode(resetSelection = true) {
    cropMode = false;
    cropToggleBtn.textContent = 'Start Crop';
    overlayCanvas.style.pointerEvents = 'none';
    if (resetSelection) selection = null;
    applyCropBtn.disabled = true;
    cancelCropBtn.disabled = true;
    drawOverlay();
  }

  // Map mouse event coords into image coordinates
  function mapEventToImageCoords(e) {
    const rect = overlayCanvas.getBoundingClientRect();
    const x = Math.round((e.clientX - rect.left) * (overlayCanvas.width / rect.width));
    const y = Math.round((e.clientY - rect.top) * (overlayCanvas.height / rect.height));
    return { x: clamp(x, 0, overlayCanvas.width), y: clamp(y, 0, overlayCanvas.height) };
  }

  function clamp(v, a, b) { return Math.max(a, Math.min(b, v)); }

  // Apply crop: create temp canvas and draw selected region
  function applyCrop() {
    if (!selection || selection.w <= 0 || selection.h <= 0) return;
    const tmp = document.createElement('canvas');
    tmp.width = selection.w;
    tmp.height = selection.h;
    const tctx = tmp.getContext('2d');
    // draw current preview with filters into temp and copy region
    tctx.filter = `brightness(${filterState.brightness}%) contrast(${filterState.contrast}%) saturate(${filterState.saturate}%)`;
    tctx.drawImage(baseImage, 0, 0, editorCanvas.width, editorCanvas.height);
    const out = document.createElement('canvas');
    out.width = selection.w;
    out.height = selection.h;
    const outCtx = out.getContext('2d');
    outCtx.drawImage(tmp, selection.x, selection.y, selection.w, selection.h, 0, 0, selection.w, selection.h);
    const dataURL = out.toDataURL('image/png');
    const img = new Image();
    img.onload = () => {
      setBaseImage(img);
      // reset selection and bake filters
      filterState = { brightness: 100, contrast: 100, saturate: 100 };
      resetFilterInputs();
      pushHistory(dataURL);
      stopCropMode(true);
    };
    img.src = dataURL;
  }

  // Utility: Auto contrast (very simple implementation: stretch histogram)
  function autoContrast() {
    if (!baseImage) return;
    // draw current preview to temp and process pixels
    const tmp = document.createElement('canvas');
    tmp.width = editorCanvas.width;
    tmp.height = editorCanvas.height;
    const tctx = tmp.getContext('2d');
    tctx.filter = `brightness(${filterState.brightness}%) contrast(${filterState.contrast}%) saturate(${filterState.saturate}%)`;
    tctx.drawImage(baseImage, 0, 0);
    const imgd = tctx.getImageData(0,0,tmp.width,tmp.height);
    const data = imgd.data;
    // find min and max luminance
    let min=255, max=0;
    for (let i=0;i<data.length;i+=4){
      const r=data[i], g=data[i+1], b=data[i+2];
      // luminance approximation
      const l = 0.2126*r + 0.7152*g + 0.0722*b;
      if (l < min) min = l;
      if (l > max) max = l;
    }
    const range = max - min || 1;
    for (let i=0;i<data.length;i+=4){
      data[i] = clamp(((data[i]-min)/range)*255,0,255);
      data[i+1] = clamp(((data[i+1]-min)/range)*255,0,255);
      data[i+2] = clamp(((data[i+2]-min)/range)*255,0,255);
    }
    tctx.putImageData(imgd,0,0);
    const dataURL = tmp.toDataURL('image/png');
    const img = new Image();
    img.onload = ()=> {
      setBaseImage(img);
      filterState = { brightness: 100, contrast: 100, saturate: 100 };
      resetFilterInputs();
      pushHistory(dataURL);
    };
    img.src = dataURL;
  }

  // Quick grayscale
  function grayscale() {
    if (!baseImage) return;
    const tmp = document.createElement('canvas');
    tmp.width = editorCanvas.width;
    tmp.height = editorCanvas.height;
    const tctx = tmp.getContext('2d');
    tctx.drawImage(baseImage,0,0);
    const imgd = tctx.getImageData(0,0,tmp.width,tmp.height);
    const data = imgd.data;
    for (let i=0;i<data.length;i+=4){
      const v = Math.round(0.299*data[i] + 0.587*data[i+1] + 0.114*data[i+2]);
      data[i]=data[i+1]=data[i+2]=v;
    }
    tctx.putImageData(imgd,0,0);
    const dataURL = tmp.toDataURL('image/png');
    const img = new Image();
    img.onload = ()=> {
      setBaseImage(img);
      pushHistory(dataURL);
    };
    img.src = dataURL;
  }

  // Reset filter input UI
  function resetFilterInputs(){
    brightness.value = 100;
    contrast.value = 100;
    saturate.value = 100;
    bval.textContent = '100%';
    cval.textContent = '100%';
    sval.textContent = '100%';
  }

  // Export/download current preview (apply filters before download if user wishes)
  function downloadCurrent() {
    // Draw preview into export canvas so filters are baked into download
    if (!baseImage) return;
    const tmp = document.createElement('canvas');
    tmp.width = editorCanvas.width;
    tmp.height = editorCanvas.height;
    const tctx = tmp.getContext('2d');
    tctx.filter = `brightness(${filterState.brightness}%) contrast(${filterState.contrast}%) saturate(${filterState.saturate}%)`;
    tctx.drawImage(baseImage, 0, 0);
    tmp.toBlob((blob) => {
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `edited-${new Date().toISOString().slice(0,19).replace(/[:T]/g,'-')}.png`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    }, 'image/png');
  }

  // Undo / Redo
  async function undo() {
    if (historyIndex <= 0) return;
    historyIndex--;
    await restoreFromDataURL(history[historyIndex]);
    updateHistoryButtons();
  }
  async function redo() {
    if (historyIndex >= history.length - 1) return;
    historyIndex++;
    await restoreFromDataURL(history[historyIndex]);
    updateHistoryButtons();
  }

  // Event wiring
  fileInput.addEventListener('change', (e) => {
    const f = e.target.files && e.target.files[0];
    if (!f) return;
    const url = URL.createObjectURL(f);
    const img = new Image();
    img.onload = () => {
      setBaseImage(img);
      // push initial state into history
      const tmp = document.createElement('canvas');
      tmp.width = img.naturalWidth;
      tmp.height = img.naturalHeight;
      tmp.getContext('2d').drawImage(img,0,0);
      const d = tmp.toDataURL('image/png');
      pushHistory(d);
    };
    img.onerror = () => alert('Failed to load image.');
    img.src = url;
    fileInput.value = '';
  });

  // Filter sliders (live preview)
  function onFilterChange() {
    filterState.brightness = Number(brightness.value);
    filterState.contrast = Number(contrast.value);
    filterState.saturate = Number(saturate.value);
    bval.textContent = filterState.brightness + '%';
    cval.textContent = filterState.contrast + '%';
    sval.textContent = filterState.saturate + '%';
    drawPreview();
  }
  brightness.addEventListener('input', onFilterChange);
  contrast.addEventListener('input', onFilterChange);
  saturate.addEventListener('input', onFilterChange);

  applyFiltersBtn.addEventListener('click', () => {
    commitFiltersToImage();
  });
  revertFiltersBtn.addEventListener('click', () => {
    filterState = { brightness: 100, contrast: 100, saturate: 100 };
    resetFilterInputs();
    drawPreview();
  });

  rotateLeftBtn.addEventListener('click', () => rotateImage('left'));
  rotateRightBtn.addEventListener('click', () => rotateImage('right'));

  // Crop interactions on overlay canvas
  overlayCanvas.addEventListener('mousedown', (e) => {
    if (!cropMode) return;
    dragging = true;
    const p = mapEventToImageCoords(e);
    dragStart = p;
    selection = { x: p.x, y: p.y, w: 0, h: 0 };
    drawOverlay();
  });
  overlayCanvas.addEventListener('mousemove', (e) => {
    if (!cropMode) return;
    if (!dragging) return;
    const p = mapEventToImageCoords(e);
    const x = Math.min(dragStart.x, p.x);
    const y = Math.min(dragStart.y, p.y);
    const w = Math.abs(p.x - dragStart.x);
    const h = Math.abs(p.y - dragStart.y);
    selection = { x, y, w, h };
    drawOverlay();
    applyCropBtn.disabled = !(selection && selection.w > 4 && selection.h > 4);
  });
  overlayCanvas.addEventListener('mouseup', () => {
    if (!cropMode) return;
    dragging = false;
  });
  overlayCanvas.addEventListener('mouseleave', () => {
    if (!cropMode) return;
    dragging = false;
  });

  cropToggleBtn.addEventListener('click', () => {
    if (!cropMode) startCropMode();
    else stopCropMode(true);
  });
  cancelCropBtn.addEventListener('click', () => {
    stopCropMode(true);
  });
  applyCropBtn.addEventListener('click', () => {
    if (selection) applyCrop();
  });

  // Extra fixes
  document.getElementById('auto-contrast').addEventListener('click', autoContrast);
  document.getElementById('grayscale').addEventListener('click', grayscale);

  downloadBtn.addEventListener('click', downloadCurrent);
  undoBtn.addEventListener('click', () => undo());
  redoBtn.addEventListener('click', () => redo());
  resetBtn.addEventListener('click', async () => {
    if (!confirm('Reset to original (clears history)?')) return;
    if (history.length) {
      await restoreFromDataURL(history[0]);
      history.splice(1); // keep original only
      historyIndex = 0;
      updateHistoryButtons();
      filterState = { brightness:100, contrast:100, saturate:100 };
      resetFilterInputs();
    }
  });

  // Keyboard shortcuts (Ctrl/Cmd+Z, Shift+Ctrl+Z)
  window.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'z') {
      e.preventDefault();
      if (e.shiftKey) redo(); else undo();
    }
  });

  // Initialize overlay pointer events disabled until crop mode active
  overlayCanvas.style.pointerEvents = 'none';

  // Basic resize handling: keep CSS sized canvas centered; actual pixel buffer remains image size
  window.addEventListener('resize', () => {
    if (!baseImage) return;
    // reapply sizing logic
    setBaseImage(baseImage);
  });

  // When page loads, disable buttons that require image
  function setUIEnabled(enabled) {
    const els = [applyFiltersBtn, revertFiltersBtn, rotateLeftBtn, rotateRightBtn, cropToggleBtn, downloadBtn, undoBtn, redoBtn, resetBtn];
    els.forEach(el => el.disabled = !enabled);
  }
  setUIEnabled(false);

  // Watch baseImage changes via observer pattern: we call setBaseImage when loaded, so enable UI there
  const originalSetBaseImage = setBaseImage;
  setBaseImage = function(img) {
    originalSetBaseImage(img);
    setUIEnabled(true);
    // set overlay pointer events to none unless crop mode toggled on
    overlayCanvas.style.pointerEvents = cropMode ? 'auto' : 'none';
  };

  // ensure history buttons initial states
  updateHistoryButtons();
  resetFilterInputs();

  // Expose a small API for debugging
  window.photoEditor = {
    setBaseImage, drawPreview, pushHistory, history,
  };
})();