(function () {
  const questionEl = document.getElementById('question');
  const optionsEl = document.getElementById('options');
  const logEl = document.getElementById('log');

  const tree = {
    id: 'start',
    q: 'What do you seek today?',
    options: [
      { text: 'Calm mind', next: 'calm' },
      { text: 'Purpose', next: 'purpose' },
      { text: 'Courage', next: 'courage' }
    ]
  };

  const nodes = {
    start: tree,
    calm: {
      id: 'calm',
      q: 'Choose a practice:',
      options: [
        { text: 'Breath focus', next: 'calm_breath' },
        { text: 'Detach from results', next: 'calm_detach' }
      ]
    },
    calm_breath: { id: 'end1', end: true, text: 'Sit quietly, slow breathing. Remember: equanimity is yoga (Gita 2.48).' },
    calm_detach: { id: 'end2', end: true, text: 'Perform your duty without attachment (Gita 2.47). Peace follows sincere action.' },
    purpose: {
      id: 'purpose',
      q: 'Where do you feel natural strength?',
      options: [
        { text: 'Learning/teaching', next: 'purpose_teach' },
        { text: 'Serving/organizing', next: 'purpose_serve' }
      ]
    },
    purpose_teach: { id: 'end3', end: true, text: 'Share knowledge with humility; align with svadharma (Gita 18.47).' },
    purpose_serve: { id: 'end4', end: true, text: 'Serve steadily; act for the welfare of others (Gita 3.20-21).' },
    courage: {
      id: 'courage',
      q: 'What blocks your courage most?',
      options: [
        { text: 'Fear of failure', next: 'courage_fail' },
        { text: 'Judgment of others', next: 'courage_judge' }
      ]
    },
    courage_fail: { id: 'end5', end: true, text: 'Remember your essence is unborn, eternal (Gita 2.20). Act without fear.' },
    courage_judge: { id: 'end6', end: true, text: 'Fix your mind on your duty, not on opinions. Act with steadiness (Gita 3.30).' }
  };

  let path = ['start'];

  function render(nodeId) {
    const node = nodes[nodeId];
    if (!node) return;
    optionsEl.innerHTML = '';
    if (node.end) {
      questionEl.textContent = 'Guidance';
      optionsEl.innerHTML = `<button onclick="location.reload()">Start over</button>`;
      log(`${node.text}`);
      return;
    }
    questionEl.textContent = node.q;
    node.options.forEach(opt => {
      const b = document.createElement('button');
      b.textContent = opt.text;
      b.onclick = () => {
        path.push(opt.next);
        render(opt.next);
      };
      optionsEl.appendChild(b);
    });
    log(`Q: ${node.q}`);
  }

  function log(text) {
    const p = document.createElement('p');
    p.textContent = text;
    logEl.appendChild(p);
  }

  render('start');
})();