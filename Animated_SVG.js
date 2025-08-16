// Animated SVG Infographic
// - Bars: monthly visits (animated height)
// - Line: conversion % drawn as a path and morphs between datasets
// - Play/pause, timeline slider, reset, export SVG, hover tooltips
// - Lightweight tweening using requestAnimationFrame

(function () {
  // DOM
  const svg = document.getElementById('viz');
  const barsGroup = document.getElementById('bars');
  const linePath = document.getElementById('linePath');
  const areaPath = document.getElementById('areaPath');
  const pointsGroup = document.getElementById('points');
  const label = document.getElementById('label');
  const playBtn = document.getElementById('play');
  const pauseBtn = document.getElementById('pause');
  const resetBtn = document.getElementById('reset');
  const timeline = document.getElementById('timeline');
  const exportBtn = document.getElementById('export');
  const tooltip = document.getElementById('tooltip');

  // layout inside svg: margin and inner size (matches viewBox)
  const margin = { left: 0, top: 0 };
  const inner = { width: 780, height: 320 }; // created against translate(60,40)

  // synthetic data sets (12 months)
  const datasets = {
    visitsA: [820, 900, 1000, 1200, 1100, 1250, 1400, 1350, 1280, 1500, 1700, 1800],
    visitsB: [1200, 1400, 1500, 1550, 1600, 1700, 2000, 2100, 2050, 2200, 2400, 2600],
    convA:  [1.2, 1.5, 1.6, 1.9, 1.7, 2.0, 2.2, 2.1, 2.0, 2.4, 2.7, 2.9], // percentages
    convB:  [1.6, 1.9, 2.0, 2.1, 2.3, 2.5, 2.8, 3.0, 2.9, 3.1, 3.4, 3.9],
  };

  // animation state
  let state = {
    currentVisits: datasets.visitsA.slice(),
    currentConv: datasets.convA.slice(),
    targetVisits: datasets.visitsA.slice(),
    targetConv: datasets.convA.slice(),
    t: 0, // progress 0..1 for current tween
    playing: false,
    animStart: null,
    animDuration: 1600, // ms for a transition
  };

  // pre-calc x positions for 12 months
  const months = [...Array(12)].map((_, i) => {
    const gap = inner.width / 12;
    const x = gap * i + gap * 0.08; // small offset
    const barWidth = gap * 0.84;
    return { index: i, x, barWidth };
  });

  // scale helpers
  function maxOf(arr) { return Math.max(...arr); }
  function scaleYVisits(v) {
    const max = Math.max(maxOf(datasets.visitsA), maxOf(datasets.visitsB)) * 1.05;
    // invert for svg (0 at top)
    return inner.height - (v / max) * inner.height;
  }
  function scaleConvY(pct) {
    const maxPct = Math.max(maxOf(datasets.convA), maxOf(datasets.convB)) * 1.2;
    return inner.height - (pct / maxPct) * inner.height;
  }

  // init: create bars and points placeholders
  function initShapes() {
    barsGroup.innerHTML = '';
    pointsGroup.innerHTML = '';
    months.forEach((m, i) => {
      const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
      rect.setAttribute('x', m.x.toFixed(2));
      rect.setAttribute('width', (m.barWidth - 6).toFixed(2));
      rect.setAttribute('rx', 6);
      rect.setAttribute('fill', 'url(#gradBar)');
      rect.dataset.month = i;
      barsGroup.appendChild(rect);

      const pt = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      pt.setAttribute('r', 5);
      pt.setAttribute('fill', '#ef4444');
      pt.dataset.month = i;
      pointsGroup.appendChild(pt);

      // attach hover for tooltip (use mouseenter/leave)
      rect.addEventListener('mousemove', onBarHover);
      rect.addEventListener('mouseleave', hideTooltip);
      pt.addEventListener('mousemove', onPointHover);
      pt.addEventListener('mouseleave', hideTooltip);
    });
    updateShapes(1); // initial render
  }

  // build path from currentConv
  function buildLinePath(convArr) {
    const gap = inner.width / 12;
    const pts = convArr.map((v, i) => {
      const cx = gap * i + gap * 0.5;
      const cy = scaleConvY(v);
      return [cx, cy];
    });
    // smooth-ish path with simple cubic smoothing (not perfect but OK)
    let d = '';
    pts.forEach((p, i) => {
      if (i === 0) d += `M ${p[0].toFixed(2)} ${p[1].toFixed(2)} `;
      else {
        // simple quadratic curve based on midpoints
        const prev = pts[i - 1];
        const cx = (prev[0] + p[0]) / 2;
        const cy = (prev[1] + p[1]) / 2;
        d += `Q ${prev[0].toFixed(2)} ${prev[1].toFixed(2)} ${cx.toFixed(2)} ${cy.toFixed(2)} `;
        if (i === pts.length - 1) d += `T ${p[0].toFixed(2)} ${p[1].toFixed(2)} `;
      }
    });
    return { d, pts };
  }

  function buildAreaPath(pts) {
    // pts is array [ [x,y], ... ]
    if (!pts || pts.length === 0) return '';
    let d = `M ${pts[0][0].toFixed(2)} ${inner.height.toFixed(2)} L ${pts[0][0].toFixed(2)} ${pts[0][1].toFixed(2)} `;
    for (let i = 1; i < pts.length; i++) {
      d += `L ${pts[i][0].toFixed(2)} ${pts[i][1].toFixed(2)} `;
    }
    d += `L ${pts[pts.length - 1][0].toFixed(2)} ${inner.height.toFixed(2)} Z`;
    return d;
  }

  // interpolation
  function lerp(a, b, t) { return a + (b - a) * t; }

  function updateShapes(progress = state.t) {
    // calculate interpolated arrays
    const visits = state.currentVisits.map((v, i) => lerp(v, state.targetVisits[i], progress));
    const conv = state.currentConv.map((v, i) => lerp(v, state.targetConv[i], progress));

    // update bars
    const rects = Array.from(barsGroup.querySelectorAll('rect'));
    rects.forEach((rect, i) => {
      const v = visits[i];
      const y = scaleYVisits(v);
      const h = inner.height - (y);
      rect.setAttribute('y', y.toFixed(2));
      rect.setAttribute('height', Math.max(2, h).toFixed(2));
      // add data attributes for tooltip
      rect.dataset.value = Math.round(v);
    });

    // update line and area
    const { d, pts } = buildLinePath(conv);
    linePath.setAttribute('d', d);
    areaPath.setAttribute('d', buildAreaPath(pts));

    // update points
    const circles = Array.from(pointsGroup.querySelectorAll('circle'));
    circles.forEach((c, i) => {
      const p = pts[i];
      c.setAttribute('cx', p[0].toFixed(2));
      c.setAttribute('cy', p[1].toFixed(2));
      c.dataset.pct = conv[i].toFixed(2);
    });

    // label current dataset
    label.textContent = `Dataset progress: ${(progress * 100).toFixed(0)}%`;
  }

  // animation loop for tweening from current to target
  function animateTo(duration = state.animDuration) {
    state.animStart = performance.now();
    state.animDuration = duration;
    state.playing = true;
    playBtn.classList.add('hidden');
    pauseBtn.classList.remove('hidden');

    function step(now) {
      const elapsed = now - state.animStart;
      let t = Math.min(1, elapsed / state.animDuration);
      // easing (easeOutQuad)
      t = 1 - (1 - t) * (1 - t);
      state.t = t;
      updateShapes(t);
      timeline.value = Math.round(t * 100);
      if (t < 1 && state.playing) {
        state._raf = requestAnimationFrame(step);
      } else {
        // end: commit target to current
        state.currentVisits = state.targetVisits.slice();
        state.currentConv = state.targetConv.slice();
        state.t = 0;
        state.playing = false;
        playBtn.classList.remove('hidden');
        pauseBtn.classList.add('hidden');
      }
    }
    state._raf = requestAnimationFrame(step);
  }

  function pauseAnimation() {
    if (!state.playing) return;
    state.playing = false;
    if (state._raf) cancelAnimationFrame(state._raf);
    playBtn.classList.remove('hidden');
    pauseBtn.classList.add('hidden');
  }

  // UI actions to go to different datasets
  function goToDataset(nameVisits, nameConv) {
    state.targetVisits = (datasets[nameVisits] || state.currentVisits).slice();
    state.targetConv = (datasets[nameConv] || state.currentConv).slice();
    animateTo(1400);
  }

  // example sequence: visitsA->visitsB and convA->convB
  function playSequence() {
    // first toggle to B
    goToDataset('visitsB', 'convB');
  }

  // timeline slider control (manual scrubbing)
  timeline.addEventListener('input', (e) => {
    const v = Number(e.target.value) / 100;
    // if playing, pause
    if (state.playing) pauseAnimation();
    // set shapes to interpolated state
    updateShapes(v);
  });

  // play/pause/reset/export wiring
  playBtn.addEventListener('click', () => {
    // if current and target are same, toggle to alternate dataset
    if (arraysEqual(state.currentVisits, state.targetVisits) && arraysEqual(state.currentConv, state.targetConv)) {
      // swap to B if currently A, else to A
      const isA = arraysEqual(state.currentVisits, datasets.visitsA);
      if (isA) {
        state.targetVisits = datasets.visitsB.slice();
        state.targetConv = datasets.convB.slice();
      } else {
        state.targetVisits = datasets.visitsA.slice();
        state.targetConv = datasets.convA.slice();
      }
    }
    animateTo();
  });

  pauseBtn.addEventListener('click', pauseAnimation);

  resetBtn.addEventListener('click', () => {
    pauseAnimation();
    // reset to baseline A
    state.currentVisits = datasets.visitsA.slice();
    state.currentConv = datasets.convA.slice();
    state.targetVisits = state.currentVisits.slice();
    state.targetConv = state.currentConv.slice();
    state.t = 0;
    updateShapes(1);
    timeline.value = 0;
  });

  exportBtn.addEventListener('click', () => {
    const svgEl = svg.cloneNode(true);
    // ensure inline styles retained (we used CSS); set width/height attrs
    svgEl.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
    const serializer = new XMLSerializer();
    const text = serializer.serializeToString(svgEl);
    const blob = new Blob([text], { type: 'image/svg+xml;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'infographic.svg';
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  });

  // tooltip handlers
  function onBarHover(e) {
    const rect = e.currentTarget;
    const month = Number(rect.dataset.month) + 1;
    const val = rect.dataset.value;
    const x = e.clientX + 12;
    const y = e.clientY + 12;
    showTooltip(`Month ${month}<br/>Visits: ${val}`, x, y);
  }

  function onPointHover(e) {
    const c = e.currentTarget;
    const month = Number(c.dataset.month) + 1;
    const pct = c.dataset.pct;
    const x = e.clientX + 12;
    const y = e.clientY + 12;
    showTooltip(`Month ${month}<br/>Conversion: ${pct}%`, x, y);
  }

  function showTooltip(html, x, y) {
    tooltip.innerHTML = html;
    tooltip.style.left = x + 'px';
    tooltip.style.top = y + 'px';
    tooltip.hidden = false;
  }
  function hideTooltip() { tooltip.hidden = true; }

  // util: compare arrays
  function arraysEqual(a, b) {
    if (!a || !b || a.length !== b.length) return false;
    for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
    return true;
  }

  // small demo: toggle dataset every time user double-clicks the SVG
  svg.addEventListener('dblclick', () => {
    playSequence();
  });

  // init
  initShapes();
  // initial content: set targets identical to current
  state.targetVisits = state.currentVisits.slice();
  state.targetConv = state.currentConv.slice();
  updateShapes(1);

  // expose for dev
  window.svgInfographic = {
    playSequence,
    goToDataset,
    reset: () => resetBtn.click(),
  };
})();