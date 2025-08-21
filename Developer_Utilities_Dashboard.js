// Developer Utilities Dashboard
// Tools: Regex Tester, JSON Formatter, HTTP Client (Fetch UI), Color Picker
// Minimal, client-side only. Designed for quick iterative work.

(() => {
  // --- Tabbing ---
  const tabs = document.querySelectorAll('.tab');
  const panels = document.querySelectorAll('.panel');
  tabs.forEach(t => t.addEventListener('click', () => {
    tabs.forEach(x => x.classList.remove('active'));
    panels.forEach(p => p.classList.add('hidden'));
    t.classList.add('active');
    document.getElementById(t.dataset.panel).classList.remove('hidden');
  }));

  // --- Regex Tester ---
  const rxPattern = document.getElementById('rx-pattern');
  const rxFlags = document.getElementById('rx-flags');
  const rxInput = document.getElementById('rx-input');
  const rxTestBtn = document.getElementById('rx-test');
  const rxReplaceBtn = document.getElementById('rx-replace-btn');
  const rxReplace = document.getElementById('rx-replace');
  const rxResult = document.getElementById('rx-result');
  const rxCopy = document.getElementById('rx-copy');

  function runRegexTest() {
    rxResult.textContent = '';
    const pattern = rxPattern.value;
    const flags = rxFlags.value;
    let re;
    try {
      re = new RegExp(pattern, flags);
    } catch (e) {
      rxResult.textContent = `Invalid pattern: ${e.message}`;
      return;
    }
    const text = rxInput.value || '';
    const matches = [];
    if (flags.includes('g')) {
      let m;
      while ((m = re.exec(text)) !== null) {
        // capture full match and groups
        matches.push({ index: m.index, match: m[0], groups: m.slice(1) });
        // avoid infinite loop for zero-length matches
        if (m.index === re.lastIndex) re.lastIndex++;
      }
    } else {
      const m = re.exec(text);
      if (m) matches.push({ index: m.index, match: m[0], groups: m.slice(1) });
    }
    if (!matches.length) {
      rxResult.textContent = 'No matches';
      return;
    }
    const out = matches.map((m, i) => {
      const g = m.groups.length ? ` groups: ${JSON.stringify(m.groups)}` : '';
      return `${i+1}) index:${m.index} match:${m.match}${g}`;
    }).join('\n');
    rxResult.textContent = out;
  }

  function runRegexReplace() {
    rxResult.textContent = '';
    try {
      const re = new RegExp(rxPattern.value, rxFlags.value);
      const replaced = (rxInput.value || '').replace(re, rxReplace.value || '');
      rxResult.textContent = replaced;
    } catch (e) {
      rxResult.textContent = 'Replace error: ' + e.message;
    }
  }

  rxTestBtn.addEventListener('click', runRegexTest);
  rxReplaceBtn.addEventListener('click', runRegexReplace);
  rxCopy.addEventListener('click', () => {
    navigator.clipboard?.writeText(rxResult.textContent || '').then(() => {
      rxCopy.textContent = 'Copied!';
      setTimeout(() => rxCopy.textContent = 'Copy Matches', 1200);
    }).catch(() => alert('Copy failed'));
  });

  // --- JSON Formatter ---
  const jsonInput = document.getElementById('json-input');
  const jsonPretty = document.getElementById('json-pretty');
  const jsonMinify = document.getElementById('json-minify');
  const jsonValidate = document.getElementById('json-validate');
  const jsonResult = document.getElementById('json-result');
  const jsonCopy = document.getElementById('json-copy');

  function prettyJSON() {
    jsonResult.textContent = '';
    try {
      const parsed = JSON.parse(jsonInput.value);
      const pretty = JSON.stringify(parsed, null, 2);
      jsonInput.value = pretty;
      jsonResult.textContent = 'Valid JSON (pretty-printed)';
    } catch (e) {
      jsonResult.textContent = 'Invalid JSON: ' + e.message;
    }
  }
  function minifyJSON() {
    try {
      const parsed = JSON.parse(jsonInput.value);
      jsonInput.value = JSON.stringify(parsed);
      jsonResult.textContent = 'Minified';
    } catch (e) {
      jsonResult.textContent = 'Invalid JSON: ' + e.message;
    }
  }
  function validateJSON() {
    try {
      JSON.parse(jsonInput.value);
      jsonResult.textContent = '✅ Valid JSON';
    } catch (e) {
      jsonResult.textContent = '❌ Invalid JSON: ' + e.message;
    }
  }
  jsonPretty.addEventListener('click', prettyJSON);
  jsonMinify.addEventListener('click', minifyJSON);
  jsonValidate.addEventListener('click', validateJSON);
  jsonCopy.addEventListener('click', () => {
    navigator.clipboard?.writeText(jsonInput.value || '').then(() => {
      jsonCopy.textContent = 'Copied!';
      setTimeout(() => jsonCopy.textContent = 'Copy', 1200);
    }).catch(() => alert('Copy failed'));
  });

  // --- HTTP Client ---
  const httpUrl = document.getElementById('http-url');
  const httpMethod = document.getElementById('http-method');
  const httpHeaders = document.getElementById('http-headers');
  const httpBody = document.getElementById('http-body');
  const httpSend = document.getElementById('http-send');
  const httpResponse = document.getElementById('http-response');
  const httpMeta = document.getElementById('http-meta');
  const httpClear = document.getElementById('http-clear');
  const httpSave = document.getElementById('http-save');
  const httpSaved = document.getElementById('http-saved');

  const REQ_KEY = 'devutils:http:requests:v1';
  let savedRequests = loadSavedRequests();

  function loadSavedRequests() {
    try { return JSON.parse(localStorage.getItem(REQ_KEY) || '[]'); } catch (e) { return []; }
  }
  function persistSavedRequests() { localStorage.setItem(REQ_KEY, JSON.stringify(savedRequests)); }
  function refreshSavedSelect() {
    httpSaved.innerHTML = '<option value="">Saved requests...</option>';
    savedRequests.forEach((r, i) => {
      const opt = document.createElement('option');
      opt.value = i;
      opt.textContent = `${r.method} ${r.url}`;
      httpSaved.appendChild(opt);
    });
  }
  refreshSavedSelect();

  httpSaved.addEventListener('change', () => {
    const idx = httpSaved.value;
    if (idx === '') return;
    const r = savedRequests[Number(idx)];
    if (!r) return;
    httpUrl.value = r.url;
    httpMethod.value = r.method;
    httpHeaders.value = r.headers || '';
    httpBody.value = r.body || '';
  });

  httpSave.addEventListener('click', () => {
    const r = { url: httpUrl.value, method: httpMethod.value, headers: httpHeaders.value, body: httpBody.value, created: Date.now() };
    savedRequests.push(r);
    persistSavedRequests();
    refreshSavedSelect();
    alert('Saved request');
  });

  httpClear.addEventListener('click', () => {
    httpUrl.value = '';
    httpHeaders.value = '';
    httpBody.value = '';
    httpResponse.textContent = '';
    httpMeta.textContent = '';
  });

  async function sendRequest() {
    httpResponse.textContent = '';
    httpMeta.textContent = 'Sending...';
    const url = httpUrl.value.trim();
    if (!url) {
      httpMeta.textContent = 'Enter a URL';
      return;
    }
    const method = httpMethod.value;
    // parse headers textarea
    const headers = {};
    (httpHeaders.value || '').split('\n').forEach(line => {
      const idx = line.indexOf(':');
      if (idx > -1) {
        const k = line.slice(0, idx).trim();
        const v = line.slice(idx + 1).trim();
        if (k) headers[k] = v;
      }
    });
    const opts = { method, headers };
    if (method !== 'GET' && method !== 'HEAD' && httpBody.value) {
      // try to detect JSON
      let body = httpBody.value;
      if (headers['Content-Type']?.includes('application/json')) {
        try { JSON.parse(body); } catch(e) { /* still send raw */ }
      }
      opts.body = body;
    }

    const start = performance.now();
    try {
      const res = await fetch(url, opts);
      const elapsed = (performance.now() - start).toFixed(1);
      const contentType = res.headers.get('Content-Type') || '';
      httpMeta.textContent = `${res.status} ${res.statusText} • ${elapsed}ms • ${contentType}`;

      // try parse json
      let bodyText = await res.text();
      if (contentType.includes('application/json')) {
        try {
          const parsed = JSON.parse(bodyText);
          bodyText = JSON.stringify(parsed, null, 2);
        } catch (e) { /* leave raw */ }
      }
      const hdrs = {};
      res.headers.forEach((v,k) => hdrs[k] = v);
      httpResponse.textContent = `-- Response headers --\n${JSON.stringify(hdrs, null, 2)}\n\n-- Body --\n${bodyText}`;
    } catch (err) {
      httpMeta.textContent = 'Request failed: ' + (err.message || err);
      httpResponse.textContent = String(err);
    }
  }

  httpSend.addEventListener('click', sendRequest);

  // --- Color Picker ---
  const cpColor = document.getElementById('cp-color');
  const cpHex = document.getElementById('cp-hex');
  const cpCopy = document.getElementById('cp-copy');
  const cpVarname = document.getElementById('cp-varname');
  const cpGen = document.getElementById('cp-gen');
  const cpOutput = document.getElementById('cp-output');
  const cpBg = document.getElementById('cp-bg');
  const cpContrast = document.getElementById('cp-contrast');

  function hexToRgb(hex) {
    const v = hex.replace('#','');
    const bigint = parseInt(v, 16);
    if (v.length === 3) {
      return {
        r: parseInt(v[0]+v[0],16),
        g: parseInt(v[1]+v[1],16),
        b: parseInt(v[2]+v[2],16)
      };
    }
    return { r: (bigint >> 16) & 255, g: (bigint >> 8) & 255, b: bigint & 255 };
  }
  function luminance(hex) {
    const {r,g,b} = hexToRgb(hex);
    const RsRGB = r/255, GsRGB = g/255, BsRGB = b/255;
    const R = RsRGB <= 0.03928 ? RsRGB/12.92 : Math.pow((RsRGB+0.055)/1.055, 2.4);
    const G = GsRGB <= 0.03928 ? GsRGB/12.92 : Math.pow((GsRGB+0.055)/1.055, 2.4);
    const B = BsRGB <= 0.03928 ? BsRGB/12.92 : Math.pow((BsRGB+0.055)/1.055, 2.4);
    return 0.2126*R + 0.7152*G + 0.0722*B;
  }
  function contrastRatio(hexA, hexB) {
    const L1 = luminance(hexA) + 0.05;
    const L2 = luminance(hexB) + 0.05;
    return (Math.max(L1,L2) / Math.min(L1,L2));
  }

  function updateColorInputs(fromPicker = true) {
    const hex = (fromPicker ? cpColor.value : cpHex.value).trim();
    if (!/^#?[0-9a-fA-F]{3,6}$/.test(hex)) return;
    const normalized = hex.startsWith('#') ? hex : '#' + hex;
    cpColor.value = normalized;
    cpHex.value = normalized;
    cpOutput.textContent = `Hex: ${normalized}\nRGB: ${JSON.stringify(hexToRgb(normalized))}`;
    updateContrast();
  }
  cpColor.addEventListener('input', () => updateColorInputs(true));
  cpHex.addEventListener('change', () => updateColorInputs(false));
  cpCopy.addEventListener('click', () => {
    navigator.clipboard?.writeText(cpHex.value).then(() => {
      cpCopy.textContent = 'Copied!';
      setTimeout(() => cpCopy.textContent = 'Copy Hex', 1000);
    }).catch(() => alert('Copy failed'));
  });

  cpGen.addEventListener('click', () => {
    const name = (cpVarname.value || '--var').trim();
    const hex = cpColor.value;
    // simple shades generator using HSL adjustments
    const shades = generateShades(hex);
    let css = `${name}: ${hex};\n`;
    shades.forEach((s, i) => css += `${name}-${i+1}: ${s};\n`);
    cpOutput.textContent = css;
  });

  function generateShades(hex) {
    // quick conversion to HSL and produce lighter/darker steps
    const {r,g,b} = hexToRgb(hex);
    const rr = r/255, gg = g/255, bb = b/255;
    const max = Math.max(rr,gg,bb), min = Math.min(rr,gg,bb);
    let h=0,s=0,l=(max+min)/2;
    if (max !== min) {
      const d = max-min;
      s = l > 0.5 ? d/(2-max-min) : d/(max+min);
      switch (max) {
        case rr: h = (gg - bb)/d + (gg < bb ? 6 : 0); break;
        case gg: h = (bb - rr)/d + 2; break;
        case bb: h = (rr - gg)/d + 4; break;
      }
      h /= 6;
    }
    function hslToHex(h,s,l){
      function hue2rgb(p,q,t){
        if (t<0) t+=1;
        if (t>1) t-=1;
        if (t<1/6) return p + (q-p)*6*t;
        if (t<1/2) return q;
        if (t<2/3) return p + (q-p)*(2/3 - t)*6;
        return p;
      }
      let r,g,b;
      if (s === 0){
        r=g=b=l;
      } else {
        const q = l < 0.5 ? l*(1+s) : l + s - l*s;
        const p = 2*l - q;
        r = hue2rgb(p,q,h+1/3);
        g = hue2rgb(p,q,h);
        b = hue2rgb(p,q,h-1/3);
      }
      return '#' + [r,g,b].map(x => Math.round(x*255).toString(16).padStart(2,'0')).join('');
    }
    const out = [];
    // generate 5 shades (darker -> lighter)
    const steps = [-0.25, -0.1, 0, 0.12, 0.28];
    for (const d of steps) {
      const nl = Math.min(1, Math.max(0, l + d));
      out.push(hslToHex(h,s,nl));
    }
    return out;
  }

  function updateContrast() {
    const fg = cpColor.value;
    const bg = cpBg.value;
    const ratio = contrastRatio(fg, bg);
    cpContrast.textContent = `Contrast ratio ${ratio.toFixed(2)} :1 — ${ratio >= 4.5 ? 'PASS (WCAG AA)' : 'FAIL'}`;
  }
  cpBg.addEventListener('input', updateContrast);

  // init color inputs
  updateColorInputs(true);

  // --- Utilities ---
  function uid(){ return Date.now().toString(36) + '-' + Math.random().toString(36,8); }
  function escapeHtml(s){ return String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;'); }

  // load last-used tab from session storage
  try {
    const lastTab = sessionStorage.getItem('devutils:lastTab');
    if (lastTab) {
      const t = Array.from(tabs).find(x => x.dataset.panel === lastTab);
      if (t) t.click();
    }
  } catch (e) {}

  // persist last tab on switch
  tabs.forEach(t => t.addEventListener('click', () => {
    try { sessionStorage.setItem('devutils:lastTab', t.dataset.panel); } catch(e) {}
  }));

  // safety: basic keyboard shortcuts
  window.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
      e.preventDefault();
      rxInput.focus();
    }
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'j') {
      e.preventDefault();
      jsonInput.focus();
    }
  });

  // expose small API for testing
  window.devUtils = {
    runRegexTest, prettyJSON, sendRequest, generateShades
  };
})();