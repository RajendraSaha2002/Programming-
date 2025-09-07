document.addEventListener('DOMContentLoaded', () => {
  // Elements
  const form = document.getElementById('plannerForm');
  const usernameInput = document.getElementById('username');
  const languageInput = document.getElementById('language');
  const originsInput = document.getElementById('origins');
  const destinationsInput = document.getElementById('destinations');
  const startDateInput = document.getElementById('startDate');
  const endDateInput = document.getElementById('endDate');
  const budgetSelect = document.getElementById('budget');
  const paceSelect = document.getElementById('pace');
  const interestsInputs = document.querySelectorAll('.interest');
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
      const r = await fetch('data/travel_db.json');
      DB = await r.json();
      return DB;
    } catch (e) {
      console.error('Failed to load travel DB', e);
      DB = { cities: {} };
      return DB;
    }
  }

  function showLoading(show) {
    loadingIndicator.classList.toggle('hidden', !show);
    submitBtn.disabled = !!show;
  }

  // Utils
  function parseDestinations(text) {
    return text.split(',')
      .map(s => s.trim())
      .filter(Boolean)
      .map(s => s.replace(/\s+/g, ' '))
  }

  function toKey(city) {
    return city.toLowerCase().trim();
  }

  function dateDiffDaysInclusive(start, end) {
    const s = new Date(start);
    const e = new Date(end);
    if (isNaN(s) || isNaN(e)) return 0;
    const ms = e - s;
    if (ms < 0) return 0;
    return Math.floor(ms / (1000 * 60 * 60 * 24)) + 1;
  }

  function addDays(dateStr, n) {
    const d = new Date(dateStr);
    d.setDate(d.getDate() + n);
    return d.toISOString().slice(0, 10);
  }

  function formatDate(dateStr) {
    try {
      const d = new Date(dateStr + 'T00:00:00');
      return d.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' });
    } catch {
      return dateStr;
    }
  }

  function pick(arr, usedSet) {
    // pick first not used; if all used, wrap around
    if (!Array.isArray(arr) || arr.length === 0) return null;
    for (const item of arr) {
      const key = item.name || item;
      if (!usedSet.has(key)) {
        usedSet.add(key);
        return item;
      }
    }
    // allow reuse if needed
    return arr[0] || null;
  }

  function slotsByPace(pace) {
    if (pace === 'relaxed') return ['Morning', 'Afternoon']; // 2 slots
    if (pace === 'packed') return ['Morning', 'Midday', 'Afternoon', 'Evening']; // 4
    return ['Morning', 'Afternoon', 'Evening']; // standard 3
  }

  function nightlyBudget(budget) {
    if (budget === 'shoestring') return 'Approx. $30–60/day (hostels, local eateries, public transport)';
    if (budget === 'luxury') return 'Approx. $150–300+/day (4–5★ stays, fine dining, taxis)';
    return 'Approx. $60–120/day (3★ stays, mix of dining, metro/taxis)';
  }

  function filterCategories(cityData, interests) {
    const categories = cityData?.categories || {};
    const result = {};
    const selected = new Set(interests);
    // Always allow culture/food if DB has them, but prefer selected first
    const order = ['culture','nature','food','shopping','nightlife','adventure','spiritual'];
    for (const c of order) {
      if (categories[c]?.length) {
        result[c] = categories[c];
      }
    }
    // Build a weighted order: selected first, then others
    const weighted = order.filter(c => selected.has(c)).concat(order.filter(c => !selected.has(c)));
    return { lists: result, order: weighted };
  }

  function cityHeader(city, cityData) {
    const meta = [];
    if (cityData?.local?.transport) meta.push(`Transport: ${cityData.local.transport}`);
    if (cityData?.local?.bestSeason) meta.push(`Best season: ${cityData.local.bestSeason}`);
    return `${city} (${cityData?.country || '—'})${meta.length ? ' — ' + meta.join(' | ') : ''}`;
  }

  function craftDayLine(slot, item) {
    if (!item) return `${slot}: Open exploration / café time`;
    const t = item.time ? `, ${item.time}` : '';
    const area = item.area ? ` — ${item.area}` : '';
    const best = item.best ? ` [Best: ${item.best}]` : '';
    return `${slot}: ${item.name}${area}${t}${best}`;
  }

  function parseNotes(notes) {
    const n = (notes || '').toLowerCase();
    return {
      vegetarian: /veg|vegetarian/.test(n),
      vegan: /vegan/.test(n),
      avoidHike: /avoid hike|no hike|knee|mobility/.test(n),
      preferMuseums: /museum/.test(n),
      earlyStart: /early start|morning person/.test(n),
      lateNight: /night owl|late night/.test(n)
    };
  }

  function adjustSlotsByPreferences(slots, prefs) {
    let out = [...slots];
    if (prefs.earlyStart && !out.includes('Morning')) out.unshift('Morning');
    if (prefs.lateNight && !out.includes('Evening')) out.push('Evening');
    return out.slice(0, 4);
  }

  function planCityDays(cityLabel, cityData, dayCount, dateStart, pace, interests, notesPrefs) {
    const used = new Set();
    const { lists, order } = filterCategories(cityData, interests);
    const baseSlots = slotsByPace(pace);
    const lines = [];
    for (let d = 0; d < dayCount; d++) {
      const dayDate = addDays(dateStart, d);
      const slots = adjustSlotsByPreferences(baseSlots, notesPrefs);
      const dayItems = [];
      let categoryIdx = 0;
      // Aim to alternate categories by interest order
      for (const slot of slots) {
        const cat = order[categoryIdx % order.length];
        const pickFrom = lists[cat] || [];
        let item = pick(pickFrom, used);
        if (!item) {
          // fallback: try next category
          let fallback = null;
          for (const c2 of order) {
            fallback = pick(lists[c2] || [], used);
            if (fallback) break;
          }
          item = fallback || null;
        }
        dayItems.push(craftDayLine(slot, item));
        categoryIdx++;
      }
      // Insert Lunch/Dinner hints
      const eats = cityData?.categories?.food || [];
      const lunch = eats[0]?.name ? eats[0].name : 'local eatery';
      const dinner = eats[1]?.name ? eats[1].name : 'popular restaurant';
      if (slots.includes('Midday') || slots.includes('Afternoon')) {
        dayItems.splice(1, 0, `Lunch: ${lunch}`);
      } else {
        dayItems.push(`Lunch: ${lunch}`);
      }
      dayItems.push(`Dinner: ${dinner}`);

      lines.push({
        date: dayDate,
        city: cityLabel,
        items: dayItems
      });
    }
    return lines;
  }

  function distributeDays(totalDays, cities) {
    if (totalDays <= 0 || cities.length === 0) return [];
    const base = Math.floor(totalDays / cities.length);
    let remainder = totalDays % cities.length;
    const arr = cities.map(() => base);
    for (let i = 0; i < arr.length && remainder > 0; i++, remainder--) arr[i]++;
    return arr;
  }

  function generateItineraryText(name, language, origin, plan, budget, tips) {
    const lines = [];
    lines.push(`Dear ${name},`);
    lines.push('');
    lines.push(`Here is your personalized itinerary. [Offline demo; reply presented in ${language}]`);
    if (origin) lines.push(`Origin: ${origin}`);
    lines.push('');
    const totals = plan.length;
    if (totals > 0) {
      lines.push(`Trip length: ${totals} day(s)`);
    }
    lines.push(`Budget guidance: ${nightlyBudget(budget)}`);
    lines.push('');

    let currentCity = '';
    for (const day of plan) {
      if (day.city !== currentCity) {
        lines.push('');
        lines.push(`— ${day.city} —`);
        currentCity = day.city;
      }
      lines.push(`${formatDate(day.date)}:`);
      for (const item of day.items) {
        lines.push(`• ${item}`);
      }
    }

    if (tips?.length) {
      lines.push('');
      lines.push('Tips:');
      for (const t of tips) lines.push(`- ${t}`);
    }

    lines.push('');
    lines.push('Safe travels and enjoy your trip!');
    return lines.join('\n');
  }

  async function buildItinerary({
    name, language, origin, destinations, startDate, endDate, budget, pace, interests, notes
  }) {
    const db = await loadDB();
    const totalDays = dateDiffDaysInclusive(startDate, endDate);
    if (totalDays <= 0) throw new Error('Invalid dates. End date must be the same or after start date.');
    const dayShares = distributeDays(totalDays, destinations);
    const notesPrefs = parseNotes(notes);

    const plan = [];
    let cursorDate = startDate;
    const allTips = new Set();

    for (let i = 0; i < destinations.length; i++) {
      const city = destinations[i];
      const key = toKey(city);
      const cityData = db.cities[key];

      if (!cityData) {
        // Generic template if city not in DB
        for (let d = 0; d < dayShares[i]; d++) {
          const dayDate = addDays(cursorDate, d);
          const slots = adjustSlotsByPreferences(slotsByPace(pace), notesPrefs);
          plan.push({
            date: dayDate,
            city: city,
            items: [
              craftDayLine(slots[0] || 'Morning', { name: 'City highlights walk', area: 'Old Town', time: '2h' }),
              'Lunch: local eatery',
              craftDayLine(slots[1] || 'Afternoon', { name: 'Museum or park', time: '2h' }),
              craftDayLine((slots[2] || 'Evening'), { name: 'Sunset viewpoint or riverfront' }),
              'Dinner: popular restaurant'
            ]
          });
        }
      } else {
        const cityLines = planCityDays(cityHeader(city, cityData), cityData, dayShares[i], cursorDate, pace, interests, notesPrefs);
        plan.push(...cityLines);
        (cityData.tips || []).forEach(t => allTips.add(t));
      }

      cursorDate = addDays(cursorDate, dayShares[i]);
      // Light transfer note between cities
      if (i < destinations.length - 1) {
        const nextCity = destinations[i + 1];
        plan.push({
          date: cursorDate,
          city: `Transfer: ${destinations[i]} → ${nextCity}`,
          items: [
            'Morning: Check-out and travel to next city',
            'Afternoon: Check-in and rest',
            'Evening: Short neighborhood walk / café'
          ]
        });
        // Move cursor by 0 days (transfer day already the same date); add one if you want transfers to consume a day
        // cursorDate = addDays(cursorDate, 1);
      }
    }

    const text = generateItineraryText(name, language, origin, plan, budget, Array.from(allTips));
    return { text, plan };
  }

  // Submit
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = usernameInput.value.trim();
    const language = languageInput.value.trim();
    const origin = originsInput.value.trim();
    const destinations = parseDestinations(destinationsInput.value);
    const startDate = startDateInput.value;
    const endDate = endDateInput.value;
    const budget = budgetSelect.value;
    const pace = paceSelect.value;
    const interests = Array.from(interestsInputs).filter(i => i.checked).map(i => i.value);
    const notes = (isUsingMicrophone ? spokenText : notesText.value).trim();

    if (!name || !language || destinations.length === 0 || !startDate || !endDate) {
      alert('Please fill all required fields.');
      return;
    }

    showLoading(true);
    try {
      const { text } = await buildItinerary({
        name, language, origin, destinations, startDate, endDate, budget, pace, interests, notes
      });
      responseMessage.textContent = text;
      responseContainer.classList.remove('hidden');
      responseContainer.scrollIntoView({ behavior: 'smooth' });
    } catch (err) {
      console.error(err);
      alert(err.message || 'Failed to build itinerary.');
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
    a.download = 'itinerary.txt';
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  });

  copyBtn.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(responseMessage.textContent || '');
      alert('Itinerary copied to clipboard!');
    } catch {
      alert('Copy failed. Select and copy manually.');
    }
  });
});