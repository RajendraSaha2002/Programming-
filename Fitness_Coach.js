document.addEventListener('DOMContentLoaded', () => {
  // Elements
  const form = document.getElementById('coachForm');
  const usernameInput = document.getElementById('username');
  const languageInput = document.getElementById('language');
  const sexInput = document.getElementById('sex');
  const ageInput = document.getElementById('age');
  const heightInput = document.getElementById('height');
  const weightInput = document.getElementById('weight');
  const goalInput = document.getElementById('goal');
  const levelInput = document.getElementById('level');
  const equipmentInput = document.getElementById('equipment');
  const daysPerWeekInput = document.getElementById('daysPerWeek');
  const sessionLengthInput = document.getElementById('sessionLength');
  const dietInput = document.getElementById('diet');
  const notesText = document.getElementById('notes');

  const toggleInputBtn = document.getElementById('toggleInput');
  const textInputContainer = document.getElementById('textInputContainer');
  const micInputContainer = document.getElementById('micInputContainer');
  const startListeningBtn = document.getElementById('startListening');
  const spokenTextElement = document.getElementById('spokenText');
  const listeningIndicator = document.getElementById('listeningIndicator');

  const submitBtn = document.getElementById('submitBtn');
  const loadingIndicator = document.getElementById('loadingIndicator');
  const responseContainer = document.getElementById('responseContainer');
  const responseMessage = document.getElementById('responseMessage');
  const downloadBtn = document.getElementById('downloadBtn');
  const copyBtn = document.getElementById('copyBtn');

  // State
  let isUsingMicrophone = false;
  let spokenText = '';
  let recognition = null;
  let DB = null;

  // Mic setup
  if ('webkitSpeechRecognition' in window) {
    recognition = new webkitSpeechRecognition();
    recognition.continuous = true;
    recognition.lang = 'en-US';
    recognition.onresult = (e) => {
      const result = e.results[e.results.length - 1];
      const transcript = result[0].transcript;
      spokenText = transcript;
      spokenTextElement.textContent = `"${spokenText}"`;
      stopListening();
    };
    recognition.onend = () => listeningIndicator.classList.add('hidden');
  } else {
    toggleInputBtn.style.display = 'none';
  }

  toggleInputBtn.addEventListener('click', () => {
    isUsingMicrophone = !isUsingMicrophone;
    if (isUsingMicrophone) {
      textInputContainer.classList.add('hidden');
      micInputContainer.classList.remove('hidden');
      toggleInputBtn.textContent = 'Switch to Text Input';
    } else {
      textInputContainer.classList.remove('hidden');
      micInputContainer.classList.add('hidden');
      toggleInputBtn.textContent = 'Switch to Microphone Input';
      stopListening();
    }
  });

  startListeningBtn.addEventListener('click', () => {
    if (!recognition) return;
    spokenText = '';
    spokenTextElement.textContent = '"Listening..."';
    listeningIndicator.classList.remove('hidden');
    recognition.start();
  });

  function stopListening() {
    if (recognition) {
      recognition.stop();
      listeningIndicator.classList.add('hidden');
    }
  }

  // Load DB
  async function loadDB() {
    if (DB) return DB;
    try {
      const r = await fetch('data/fitness_db.json');
      DB = await r.json();
      return DB;
    } catch (e) {
      console.error('Failed to load fitness DB', e);
      DB = { warmups: [], mobility: [], exercises: {}, conditioning: {} };
      return DB;
    }
  }

  function showLoading(show) {
    loadingIndicator.classList.toggle('hidden', !show);
    submitBtn.disabled = !!show;
  }

  // Calculations
  function estimateCalories({ sex, age, heightCm, weightKg, daysPerWeek, goal }) {
    // Mifflin-St Jeor
    const s = sex === 'male' ? 5 : -161;
    const bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + s;
    const af = daysPerWeek <= 2 ? 1.375 : daysPerWeek <= 4 ? 1.55 : 1.725;
    let tdee = bmr * af;
    if (goal === 'lose_fat') tdee *= 0.85;
    else if (goal === 'build_muscle') tdee *= 1.10;
    return Math.round(tdee);
  }

  function estimateMacros({ weightKg, calories, goal, diet }) {
    // Protein
    let proteinG = goal === 'lose_fat' ? 2.0 * weightKg : 1.8 * weightKg;
    if (diet === 'vegan') proteinG = Math.max(proteinG, 2.0 * weightKg);
    // Fat ~25% calories
    const fatCals = 0.25 * calories;
    const fatG = fatCals / 9;
    // Carbs remainder
    const protCals = proteinG * 4;
    const carbCals = Math.max(0, calories - (protCals + fatCals));
    const carbsG = carbCals / 4;
    function round(x) { return Math.round(x); }
    return { proteinG: round(proteinG), fatG: round(fatG), carbsG: round(carbsG) };
  }

  // Utils
  function parseNotes(notes) {
    const n = (notes || '').toLowerCase();
    return {
      knee: /knee|patella|meniscus/.test(n),
      back: /back|spine|disc|lumbar/.test(n),
      shoulder: /shoulder|rotator cuff/.test(n),
      noRun: /no run|avoid run|no running/.test(n),
      morning: /morning|early/.test(n),
      evening: /night|late/.test(n)
    };
  }

  function safeFilter(exName, prefs) {
    // Remove jumps/deep flexion for knee; remove heavy hinge for back; overhead for shoulder
    const name = exName.toLowerCase();
    if (prefs.knee && /(jump|box jump|pistol|deep squat|lunge jump)/.test(name)) return false;
    if (prefs.back && /(deadlift|good morning|heavy row)/.test(name)) return false;
    if (prefs.shoulder && /(overhead|press|snatch)/.test(name)) return false;
    return true;
  }

  function pickFrom(list, idx, prefs) {
    if (!Array.isArray(list) || list.length === 0) return null;
    // Rotate by idx to vary plan
    for (let i = 0; i < list.length; i++) {
      const item = list[(idx + i) % list.length];
      if (!prefs || safeFilter(item.name || item, prefs)) return item;
    }
    return list[0];
  }

  function setRepScheme(goal, level) {
    if (goal === 'lose_fat') return { sets: 3, reps: '12–15', rest: '60–75s' };
    if (goal === 'build_muscle') return { sets: level === 'advanced' ? 4 : 3, reps: '6–12', rest: '75–120s' };
    return { sets: 3, reps: '8–12', rest: '60–90s' };
  }

  function sessionExerciseCount(sessionMin) {
    if (sessionMin <= 30) return 4;
    if (sessionMin >= 60) return 6;
    return 5; // ~45 min
  }

  function splitForDays(days) {
    if (days <= 3) return 'full';
    if (days === 4) return 'upper-lower';
    if (days === 5) return 'ppl+uf'; // push/pull/legs + upper + full/condition
    return 'ppl'; // 6 days
  }

  function buildDayLabel(split, dayIdx) {
    if (split === 'full') return ['Full Body A', 'Full Body B', 'Full Body C'][dayIdx] || 'Full Body';
    if (split === 'upper-lower') return ['Upper A', 'Lower A', 'Upper B', 'Lower B'][dayIdx] || 'Upper/Lower';
    if (split === 'ppl') return ['Push A', 'Pull A', 'Legs A', 'Push B', 'Pull B', 'Legs B'][dayIdx] || 'PPL';
    if (split === 'ppl+uf') return ['Push', 'Pull', 'Legs', 'Upper', 'Full/Condition'][dayIdx] || 'PPL+';
    return 'Workout';
  }

  function maybeConditioningLine(cond, prefs, goal, dayIdx) {
    // LISS preferred for fat loss; HIIT sparingly if no knee issues
    if (!cond) return null;
    if (goal === 'lose_fat') {
      return prefs.noRun ? cond.liss_no_run : cond.liss;
    }
    // General or build: add once or twice a week
    if (dayIdx % 2 === 0) {
      return prefs.noRun ? cond.liss_no_run : cond.hiit;
    }
    return null;
  }

  function linesFromExercises(title, items, scheme) {
    const lines = [];
    lines.push(`${title} — ${scheme.sets} sets × ${scheme.reps} (rest ${scheme.rest})`);
    for (const it of items) {
      if (!it) continue;
      const note = it.note ? ` — ${it.note}` : '';
      lines.push(`• ${it.name}${note}`);
    }
    return lines;
  }

  async function buildPlan({
    name, language, sex, age, heightCm, weightKg, goal, level, equipment, daysPerWeek, sessionLength, diet, notes
  }) {
    const db = await loadDB();
    const prefs = parseNotes(notes);

    const calories = estimateCalories({ sex, age, heightCm, weightKg, daysPerWeek, goal });
    const macros = estimateMacros({ weightKg, calories, goal, diet });

    const split = splitForDays(daysPerWeek);
    const perSession = sessionExerciseCount(sessionLength);
    const scheme = setRepScheme(goal, level);

    // Prepare category pools by equipment and level
    const X = db.exercises;
    const pool = (cat) => (X[cat] || []).filter(e =>
      (e.equipment === equipment || (equipment === 'gym' && e.equipment !== 'none') || (equipment === 'basic' && e.equipment !== 'gym')) &&
      (e.level === level || e.level === 'beginner' || (level === 'advanced' && e.level === 'intermediate'))
    );

    const weeks = 4;
    const plan = [];
    for (let w = 1; w <= weeks; w++) {
      plan.push(`Week ${w}: ${w === 4 ? '(Deload ~70% volume/intensity)' : 'Progress +1 rep or +2.5–5% load where solid'}`);
      for (let d = 0; d < daysPerWeek; d++) {
        const label = buildDayLabel(split, d);
        const dayHeader = `\nDay ${d + 1} — ${label}`;
        const warmup = db.warmups.slice(0, 4).map(s => `• ${s}`).join('\n');

        // Choose categories based on split/day
        let cats = [];
        if (split === 'full') {
          cats = ['squat', 'push', 'hinge', 'pull', 'single_leg', 'core'];
        } else if (split === 'upper-lower') {
          cats = (d % 2 === 0) ? ['push', 'pull', 'push', 'pull', 'core'] : ['squat', 'hinge', 'single_leg', 'glutes', 'core'];
        } else if (split === 'ppl') {
          cats = (d % 3 === 0) ? ['push', 'push', 'pull', 'core'] :
                 (d % 3 === 1) ? ['pull', 'pull', 'push', 'core'] :
                                 ['squat', 'hinge', 'single_leg', 'core'];
        } else { // ppl+uf
          cats = d===0?['push','push','core'] : d===1?['pull','pull','core'] :
                 d===2?['squat','hinge','core'] : d===3?['push','pull','core'] : ['conditioning','core'];
        }

        // Trim to session length
        const need = Math.min(perSession, cats.length + 2);
        const items = [];
        let pickIdx = w * 10 + d * 3;
        for (const cat of cats) {
          if (items.length >= need) break;
          if (cat === 'conditioning') continue;
          const list = pool(cat);
          const chosen = pickFrom(list, pickIdx++, prefs);
          if (chosen) items.push(chosen);
        }
        // Add extra accessory if space
        if (items.length < need) {
          const extra = pickFrom(pool('accessory'), pickIdx++, prefs);
          if (extra) items.push(extra);
        }

        // Conditioning line
        const condLine = maybeConditioningLine(db.conditioning, prefs, goal, d);

        // Week-based adjustments
        const effectiveScheme = { ...scheme };
        if (w === 4) {
          effectiveScheme.sets = Math.max(2, Math.round(effectiveScheme.sets * 0.7));
          effectiveScheme.reps = scheme.reps + ' (lighter)';
        }

        // Build lines
        plan.push(dayHeader);
        plan.push('Warm-up (5–8 min):');
        plan.push(warmup);
        plan.push(...linesFromExercises('Main Work', items, effectiveScheme));
        if (condLine) {
          plan.push('\nConditioning:');
          plan.push(`• ${condLine}`);
        }
        plan.push('Cool-down (3–5 min):');
        plan.push(db.mobility.slice(0, 3).map(s => `• ${s}`).join('\n'));
      }
      plan.push(''); // spacer between weeks
    }

    // Nutrition
    const nutrition = [
      `Calories target: ~${calories} kcal/day`,
      `Macros (approx): Protein ${macros.proteinG} g, Carbs ${macros.carbsG} g, Fat ${macros.fatG} g`,
      `Diet note: ${diet === 'vegan' ? 'Prioritize legumes, tofu/tempeh, seitan; supplement B12.' :
                   diet === 'vegetarian' ? 'Include dairy/eggs for protein if suitable.' :
                   'Lean meats, eggs, dairy, and legumes for protein.'}`,
      goal === 'lose_fat'
        ? 'Aim 7–9k steps/day and 2–3 low-intensity cardio sessions.'
        : goal === 'build_muscle'
          ? 'Sleep 7–9h; small calorie surplus; progressive overload weekly.'
          : 'Balance strength, conditioning, mobility; maintain weight.'
    ];

    const header = [
      `Dear ${name},`,
      ``,
      `Here is your 4-week training and nutrition plan. [Offline demo; reply shown in ${language}]`,
      `Stats: ${sex}, ${age}y, ${heightCm}cm, ${weightKg}kg | Goal: ${goal.replace('_',' ')} | Level: ${level} | Equipment: ${equipment} | Days/Week: ${daysPerWeek}, ~${sessionLength} min/session`
    ];

    const tips = [
      'Stop any movement that causes sharp pain; consult a professional if needed.',
      'Keep 1–3 reps in reserve (RPE 7–9) on main sets unless stated.',
      'Track sessions; add small progress weekly except during deload.'
    ];

    const planText = [
      ...header,
      '',
      'Nutrition:',
      ...nutrition.map(x => `- ${x}`),
      '',
      ...plan,
      'General Tips:',
      ...tips.map(x => `- ${x}`)
    ].join('\n');

    return planText;
  }

  // Submit
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = usernameInput.value.trim();
    const language = languageInput.value.trim();
    const sex = sexInput.value;
    const age = parseInt(ageInput.value, 10);
    const heightCm = parseInt(heightInput.value, 10);
    const weightKg = parseFloat(weightInput.value);
    const goal = goalInput.value;
    const level = levelInput.value;
    const equipment = equipmentInput.value;
    const daysPerWeek = parseInt(daysPerWeekInput.value, 10);
    const sessionLength = parseInt(sessionLengthInput.value, 10);
    const diet = dietInput.value;
    const notes = (isUsingMicrophone ? spokenText : notesText.value).trim();

    if (!name || !language || !age || !heightCm || !weightKg) {
      alert('Please fill all required fields.');
      return;
    }

    showLoading(true);
    try {
      const text = await buildPlan({
        name, language, sex, age, heightCm, weightKg, goal, level, equipment, daysPerWeek, sessionLength, diet, notes
      });
      responseMessage.textContent = text;
      responseContainer.classList.remove('hidden');
      responseContainer.scrollIntoView({ behavior: 'smooth' });
    } catch (err) {
      console.error(err);
      alert(err.message || 'Failed to build plan.');
    } finally {
      showLoading(false);
    }
  });

  // Download / Copy
  downloadBtn.addEventListener('click', () => {
    const content = responseMessage.textContent || '';
    const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'fitness_plan.txt';
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  });

  copyBtn.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(responseMessage.textContent || '');
      alert('Plan copied to clipboard!');
    } catch {
      alert('Copy failed. Select and copy manually.');
    }
  });
});