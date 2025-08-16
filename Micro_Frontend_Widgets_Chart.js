// Mini Chart widget (module)
// - renders a simple sparkline-like bar + line using inline SVG
// - exports mount(container, api) and unmount()

let root = null;
let svg = null;
let apiRef = null;

export async function mount(container, api) {
  apiRef = api;
  root = document.createElement('div');
  root.innerHTML = `
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">
      <strong>Mini Chart</strong>
      <div style="display:flex;gap:6px">
        <button class="rnd">Randomize</button>
      </div>
    </div>
    <div class="chart-wrap"></div>
  `;
  container.appendChild(root);
  svg = createSVG(420, 180);
  root.querySelector('.chart-wrap').appendChild(svg);
  const btn = root.querySelector('.rnd');
  btn.addEventListener('click', () => {
    apiRef.emit({ type: 'chart:randomize' });
    draw(randomData());
  });
  draw(randomData());
}

export async function unmount() {
  if (root && root.remove) root.remove();
  root = null;
  svg = null;
  apiRef = null;
}

export function onMessage(msg) {
  if (!msg) return;
  if (msg.type === 'set-data' && Array.isArray(msg.data)) {
    draw(msg.data);
  }
}

// helpers
function createSVG(w,h){
  const svg = document.createElementNS('http://www.w3.org/2000/svg','svg');
  svg.setAttribute('width', '100%');
  svg.setAttribute('viewBox', `0 0 ${w} ${h}`);
  svg.style.maxWidth = '100%';
  return svg;
}

function randomData(){
  return Array.from({length:12}, () => Math.round(Math.random()*100 + 20));
}

function draw(data){
  if (!svg) return;
  const w = 420, h = 180;
  const margin = 12;
  const innerW = w - margin*2;
  const innerH = h - margin*2;
  const max = Math.max(...data) || 1;
  svg.innerHTML = '';
  // bars
  const gap = innerW / data.length;
  data.forEach((v,i) => {
    const x = margin + i*gap + gap*0.12;
    const bw = gap*0.76;
    const height = (v/max)*innerH;
    const y = margin + (innerH - height);
    const rect = document.createElementNS('http://www.w3.org/2000/svg','rect');
    rect.setAttribute('x', x.toFixed(2));
    rect.setAttribute('y', y.toFixed(2));
    rect.setAttribute('width', bw.toFixed(2));
    rect.setAttribute('height', height.toFixed(2));
    rect.setAttribute('fill', '#60a5fa');
    svg.appendChild(rect);
  });
  // simple polyline
  const pts = data.map((v,i) => {
    const x = margin + i*gap + gap*0.5;
    const y = margin + (innerH - (v/max)*innerH);
    return `${x.toFixed(2)},${y.toFixed(2)}`;
  }).join(' ');
  const poly = document.createElementNS('http://www.w3.org/2000/svg','polyline');
  poly.setAttribute('points', pts);
  poly.setAttribute('fill', 'none');
  poly.setAttribute('stroke', '#ef4444');
  poly.setAttribute('stroke-width', 2);
  svg.appendChild(poly);
}