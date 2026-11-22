/* Rondo — intervaltraining als cirkelpartituur. */
(() => {
  'use strict';

  const STRINGS = {
    nl: {
      work: 'Arbeid', rest: 'Rust', perRound: 'Per ronde', rounds: 'Rondes', pause: 'Pauze',
      perRoundNote: 'Hoeveel arbeid-rust-paren er in één ronde zitten.',
      pauseNote: 'Extra rust ná een hele ronde, bovenop de gewone rust.',
      start: 'Starten', pauseAction: 'Pauzeren', settings: 'Instellingen',
      done: 'Klaar', tapStart: 'tik om te starten', tapRestart: 'tik om opnieuw te starten',
      paused: 'gepauzeerd',
      saved: 'Bewaard', save: 'Opslaan', reset: 'Herstel', sound: 'Geluid',
      cancel: 'Annuleren', close: 'Sluiten', less: 'Minder', more: 'Meer', load: 'Laad',
      library: 'Bewaarde trainingen',
      empty: 'Nog niets bewaard. Tik op “Opslaan” om deze training te bewaren.',
      description: 'Intervaltraining als cirkelpartituur.',
      roundCount: (n) => (n === 1 ? '1 ronde' : `${n} rondes`),
      roundsDone: (n) => (n === 1 ? '1 ronde afgerond' : `${n} rondes afgerond`),
      progress: (round, rounds, left) => `Ronde ${round}/${rounds} · nog ${left}`,
      perRoundShort: (n) => `${n} oef.`
    },
    en: {
      work: 'Work', rest: 'Rest', perRound: 'Per round', rounds: 'Rounds', pause: 'Break',
      perRoundNote: 'How many work-rest pairs make up one round.',
      pauseNote: 'Extra rest after a full round, on top of the regular rest.',
      start: 'Start', pauseAction: 'Pause', settings: 'Settings',
      done: 'Done', tapStart: 'tap to start', tapRestart: 'tap to start again',
      paused: 'paused',
      saved: 'Saved', save: 'Save', reset: 'Reset', sound: 'Sound',
      cancel: 'Cancel', close: 'Close', less: 'Less', more: 'More', load: 'Load',
      library: 'Saved workouts',
      empty: 'Nothing saved yet. Tap “Save” to keep this workout.',
      description: 'Interval training as a circular score.',
      roundCount: (n) => (n === 1 ? '1 round' : `${n} rounds`),
      roundsDone: (n) => (n === 1 ? '1 round completed' : `${n} rounds completed`),
      progress: (round, rounds, left) => `Round ${round}/${rounds} · ${left} left`,
      perRoundShort: (n) => `${n} per round`
    }
  };

  const preferred = (navigator.languages && navigator.languages[0]) || navigator.language || 'en';
  const LANG = preferred.toLowerCase().startsWith('nl') ? 'nl' : 'en';
  const LOCALE = LANG === 'nl' ? 'nl-NL' : preferred;
  const T = STRINGS[LANG];

  const DEFAULTS = { work: 60, rest: 90, exercises: 1, rounds: 8, resetRound: 0 };

  const FIELDS = {
    work:       { title: T.work,           time: true,  min: 1, max: 3600, step: 5, presets: [20, 30, 40, 45, 60, 90] },
    rest:       { title: T.rest,           time: true,  min: 0, max: 3600, step: 5, presets: [0, 15, 20, 30, 45, 60] },
    exercises:  { title: T.perRound,       time: false, min: 1, max: 50,   step: 1, presets: [1, 2, 3, 4, 5, 6],
                  note: T.perRoundNote },
    rounds:     { title: T.rounds,         time: false, min: 1, max: 99,   step: 1, presets: [3, 4, 5, 6, 8, 10] },
    resetRound: { title: T.pause,          time: true,  min: 0, max: 1800, step: 5, presets: [0, 30, 60, 90, 120, 180],
                  note: T.pauseNote }
  };

  const PHASES = {
    work:  { label: T.work,  klass: 'is-work', weight: 12 },
    rest:  { label: T.rest,  klass: 'is-rest',  weight: 5 },
    reset: { label: T.pause, klass: 'is-reset', weight: 7 }
  };

  const $ = (id) => document.getElementById(id);
  const el = {
    stage: $('stage'), score: $('score'), ring: $('ring'),
    done: $('arcsDone'), next: $('arcsNext'), now: $('arcsNow'),
    phase: $('phase'), clock: $('clock'), meta: $('meta'), cue: $('cue'),
    chips: $('chips'),
    editWrap: $('editWrap'), editTitle: $('editTitle'), editNote: $('editNote'), editValue: $('editValue'),
    less: $('less'), more: $('more'), presets: $('presets'), editOk: $('editOk'),
    libWrap: $('libWrap'), library: $('library'),
    btnLibrary: $('btnLibrary'), btnSave: $('btnSave'), btnReset: $('btnReset'), btnSound: $('btnSound')
  };

  /* ── Opslag ───────────────────────────────────────────────────── */
  const read = (key, fallback) => {
    try { const raw = localStorage.getItem(key); return raw ? JSON.parse(raw) : fallback; }
    catch { return fallback; }
  };
  const write = (key, value) => { try { localStorage.setItem(key, JSON.stringify(value)); } catch {} };

  const clamp = (raw) => {
    const out = { ...DEFAULTS };
    for (const [key, spec] of Object.entries(FIELDS)) {
      const n = Math.round(Number(raw?.[key]));
      if (Number.isFinite(n)) out[key] = Math.min(spec.max, Math.max(spec.min, n));
    }
    return out;
  };

  let config = clamp(read('rondo.config', DEFAULTS));
  let soundOn = read('rondo.sound', true) !== false;

  /* ── Tijd ─────────────────────────────────────────────────────── */
  const two = (n) => String(n).padStart(2, '0');
  const fmt = (seconds) => {
    const s = Math.max(0, Math.round(seconds));
    const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60;
    return h ? `${h}:${two(m)}:${two(r)}` : `${two(m)}:${two(r)}`;
  };

  /* ── Programma ────────────────────────────────────────────────── */
  // Per ronde krijgt elke oefening arbeid + rust; tussen rondes eventueel een
  // pauze. De laatste rust vervalt: de training eindigt op arbeid.
  const build = (c) => {
    const out = [];
    for (let round = 1; round <= c.rounds; round++) {
      for (let ex = 1; ex <= c.exercises; ex++) {
        out.push({ phase: 'work', duration: c.work, round, exercise: ex });
        if (c.rest > 0) out.push({ phase: 'rest', duration: c.rest, round, exercise: ex });
      }
      if (round < c.rounds && c.resetRound > 0) {
        out.push({ phase: 'reset', duration: c.resetRound, round, exercise: c.exercises });
      }
    }
    while (out.length && out[out.length - 1].phase !== 'work') out.pop();
    return out;
  };

  const totalOf = (segments) => segments.reduce((sum, s) => sum + s.duration, 0);

  const state = {
    segments: build(config), index: 0, remaining: 0, before: 0,
    running: false, finished: false, started: false,
    anchor: 0, anchorLeft: 0, lastBeep: null, raf: 0
  };

  const reset = () => {
    cancelAnimationFrame(state.raf);
    releaseWake();
    endAudioSession();
    state.segments = build(config);
    state.index = 0;
    state.before = 0;
    state.remaining = state.segments[0]?.duration ?? 0;
    state.running = state.finished = state.started = false;
    state.lastBeep = null;
    drawStatic();
    render();
  };

  /* ── De cirkelpartituur ───────────────────────────────────────── */
  const CX = 160, CY = 160, R = 132, GAP = 1.4;

  const point = (deg) => {
    const rad = (deg - 90) * Math.PI / 180;
    return [CX + R * Math.cos(rad), CY + R * Math.sin(rad)];
  };

  const arc = (from, to) => {
    const sweep = to - from;
    if (sweep <= 0.01) return '';
    // Een volle cirkel kan niet in één arc-commando.
    if (sweep >= 359.99) {
      const [ax, ay] = point(0), [bx, by] = point(180);
      return `M${ax} ${ay}A${R} ${R} 0 1 1 ${bx} ${by}A${R} ${R} 0 1 1 ${ax} ${ay}`;
    }
    const [x0, y0] = point(from), [x1, y1] = point(to);
    return `M${x0} ${y0}A${R} ${R} 0 ${sweep > 180 ? 1 : 0} 1 ${x1} ${y1}`;
  };

  // Hoeken per segment, één keer berekend per programma.
  const spans = () => {
    const total = totalOf(state.segments) || 1;
    let at = 0;
    return state.segments.map((seg) => {
      const from = at / total * 360;
      at += seg.duration;
      const to = at / total * 360;
      const pad = Math.min(GAP / 2, (to - from) / 4);
      return { seg, from: from + pad, to: to - pad };
    });
  };

  const path = (d, width, stroke, opacity, dash) => {
    if (!d) return null;
    const node = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    node.setAttribute('d', d);
    node.setAttribute('stroke-width', width);
    node.setAttribute('stroke', stroke);
    node.setAttribute('opacity', opacity);
    if (dash) node.setAttribute('stroke-dasharray', dash);
    return node;
  };

  // Afgelopen en komende bogen veranderen alleen bij een segmentwissel.
  const drawStatic = () => {
    el.done.replaceChildren();
    el.next.replaceChildren();
    spans().forEach(({ seg, from, to }, i) => {
      const w = PHASES[seg.phase].weight;
      const d = arc(from, to);
      if (!d) return;
      if (state.started && i < state.index) {
        // Gelopen: ingetogen streepjes, zodat je ziet wat je gehad hebt.
        el.done.appendChild(path(d, w, 'currentColor', .26, '1.5 5'));
      } else if (i > state.index || !state.started) {
        // Volle dikte, zacht: het ritme van de training is al leesbaar.
        el.next.appendChild(path(d, w, 'currentColor', .15));
      }
    });
  };

  // De lopende boog krimpt mee met de klok.
  const drawNow = () => {
    el.now.replaceChildren();
    if (!state.started || state.finished) return;
    const all = spans();
    const span = all[state.index];
    if (!span) return;
    const { seg, from, to } = span;
    const w = PHASES[seg.phase].weight;
    const track = path(arc(from, to), w, 'var(--accent)', .22);
    if (track) el.now.appendChild(track);
    const done = 1 - Math.min(1, Math.max(0, state.remaining / seg.duration));
    const live = path(arc(from, from + (to - from) * done), w, 'var(--accent)', 1);
    if (live) el.now.appendChild(live);
  };

  /* ── Geluid ───────────────────────────────────────────────────── */
  let audioCtx = null, silent = null;

  // Een korte stille WAV, opgebouwd zonder los bestand.
  const silentWav = () => {
    const samples = 2000;
    const bytes = new Uint8Array(44 + samples).fill(128);
    const view = new DataView(bytes.buffer);
    const ascii = (at, text) => [...text].forEach((c, i) => view.setUint8(at + i, c.charCodeAt(0)));
    ascii(0, 'RIFF'); view.setUint32(4, 36 + samples, true);
    ascii(8, 'WAVEfmt '); view.setUint32(16, 16, true);
    view.setUint16(20, 1, true); view.setUint16(22, 1, true);
    view.setUint32(24, 8000, true); view.setUint32(28, 8000, true);
    view.setUint16(32, 1, true); view.setUint16(34, 8, true);
    ascii(36, 'data'); view.setUint32(40, samples, true);
    let binary = '';
    bytes.forEach((b) => { binary += String.fromCharCode(b); });
    return `data:audio/wav;base64,${btoa(binary)}`;
  };

  // iOS dempt Web Audio in stille stand; een lopend media-element zet de
  // sessie op 'playback' en dan klinkt de timer wel.
  const holdAudioSession = () => {
    try { if (navigator.audioSession) navigator.audioSession.type = 'playback'; } catch {}
    try {
      if (!silent) {
        silent = new Audio(silentWav());
        silent.loop = true;
        silent.setAttribute('playsinline', '');
      }
      silent.play().catch(() => {});
    } catch {}
  };

  const endAudioSession = () => { if (silent) try { silent.pause(); } catch {} };

  const unlockAudio = () => {
    if (!soundOn) return;
    holdAudioSession();
    try {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      if (!Ctx) return;
      if (!audioCtx) audioCtx = new Ctx();
      if (audioCtx.state === 'suspended') audioCtx.resume();
      const src = audioCtx.createBufferSource();
      src.buffer = audioCtx.createBuffer(1, 1, 22050);
      src.connect(audioCtx.destination);
      src.start(0);
    } catch {}
  };

  const whenReady = (play) => {
    if (!audioCtx || audioCtx.state !== 'suspended') { play(); return; }
    audioCtx.resume().then(play, play);
  };

  const beep = (frequency, duration = 0.16, gain = 0.5) => {
    if (!soundOn || !audioCtx) return;
    try {
      const now = audioCtx.currentTime;
      const osc = audioCtx.createOscillator();
      const amp = audioCtx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(frequency, now);
      amp.gain.setValueAtTime(0.0001, now);
      amp.gain.exponentialRampToValueAtTime(gain, now + 0.015);
      amp.gain.exponentialRampToValueAtTime(0.0001, now + duration);
      osc.connect(amp).connect(audioCtx.destination);
      osc.start(now);
      osc.stop(now + duration + 0.02);
    } catch {}
  };

  const buzz = (pattern) => { if (navigator.vibrate) try { navigator.vibrate(pattern); } catch {} };

  const cue = {
    tick:  () => { beep(760, 0.12, 0.4); buzz(30); },
    work:  () => { beep(980, 0.16, 0.55); setTimeout(() => beep(1240, 0.26, 0.5), 150); buzz([60, 40, 60]); },
    rest:  () => { beep(480, 0.34, 0.5); buzz(90); },
    reset: () => { beep(620, 0.3, 0.45); buzz(60); },
    done:  () => { [0, 180, 360].forEach((d, i) => setTimeout(() => beep(880 + i * 220, 0.32, 0.55), d)); buzz([100, 60, 100, 60, 200]); }
  };

  /* ── Scherm wakker ────────────────────────────────────────────── */
  let wakeLock = null;
  const requestWake = async () => {
    if (!('wakeLock' in navigator)) return;
    try {
      wakeLock = await navigator.wakeLock.request('screen');
      wakeLock.addEventListener('release', () => { wakeLock = null; });
    } catch {}
  };
  const releaseWake = () => { if (wakeLock) { try { wakeLock.release(); } catch {} wakeLock = null; } };

  /* ── Weergave ─────────────────────────────────────────────────── */
  const renderChips = () => {
    for (const [key] of Object.entries(FIELDS)) {
      const node = $('v' + key.charAt(0).toUpperCase() + key.slice(1));
      if (!node) continue;
      node.textContent = FIELDS[key].time ? fmt(config[key]) : String(config[key]);
    }
    const pauze = el.chips.querySelector('[data-field="resetRound"]');
    if (pauze) pauze.hidden = config.exercises < 2 && config.resetRound === 0;
  };

  const render = () => {
    const total = totalOf(state.segments);
    const seg = state.segments[state.index];
    const elapsed = state.before + (seg ? seg.duration - state.remaining : 0);

    document.body.classList.remove('is-work', 'is-rest', 'is-reset');
    if (state.started && !state.finished && seg) document.body.classList.add(PHASES[seg.phase].klass);

    el.score.classList.toggle('is-live', state.started);
    el.score.setAttribute('aria-label', state.running ? T.pauseAction : T.start);

    if (state.finished) {
      el.phase.textContent = T.done;
      el.clock.textContent = fmt(total);
      el.meta.textContent = T.roundsDone(config.rounds);
      el.cue.textContent = T.tapRestart;
    } else if (!state.started) {
      el.phase.textContent = 'Rondo';
      el.clock.textContent = fmt(total);
      el.meta.textContent = config.exercises > 1
        ? `${T.roundCount(config.rounds)} × ${config.exercises}`
        : T.roundCount(config.rounds);
      el.cue.textContent = T.tapStart;
    } else {
      el.phase.textContent = PHASES[seg.phase].label;
      el.clock.textContent = fmt(state.remaining);
      el.meta.textContent = T.progress(seg.round, config.rounds, fmt(total - elapsed));
      el.cue.textContent = state.running ? '' : T.paused;
    }

    [...el.chips.children].forEach((chip) => {
      const live = state.running && seg && (
        (seg.phase === 'work' && chip.dataset.field === 'work') ||
        (seg.phase === 'rest' && chip.dataset.field === 'rest') ||
        (seg.phase === 'reset' && chip.dataset.field === 'resetRound'));
      chip.classList.toggle('is-live', Boolean(live));
    });

    drawNow();
    document.title = state.started && !state.finished
      ? `${fmt(state.remaining)} ${PHASES[seg.phase].label} · Rondo`
      : 'Rondo';
  };

  /* ── Klok ─────────────────────────────────────────────────────── */
  const advance = () => {
    const seg = state.segments[state.index];
    state.before += seg.duration;
    state.index += 1;
    state.lastBeep = null;
    const next = state.segments[state.index];

    if (!next) {
      state.running = false;
      state.finished = true;
      state.remaining = 0;
      releaseWake();
      whenReady(cue.done);
      endAudioSession();
      drawStatic();
      render();
      return false;
    }

    state.remaining = next.duration;
    state.anchor = Date.now();
    state.anchorLeft = next.duration;
    whenReady(cue[next.phase]);
    drawStatic();
    return true;
  };

  const tick = () => {
    if (!state.running) return;
    const seg = state.segments[state.index];
    if (!seg) return;

    let left = state.anchorLeft - (Date.now() - state.anchor) / 1000;
    state.remaining = Math.max(0, left);

    const whole = Math.ceil(state.remaining);
    if (whole > 0 && whole <= 3 && state.lastBeep !== whole) {
      state.lastBeep = whole;
      cue.tick();
    }

    if (left <= 0) {
      const over = -left;
      if (!advance()) return;
      state.anchor = Date.now() - over * 1000;
      state.remaining = Math.max(0, state.anchorLeft - over);
    }

    render();
    state.raf = requestAnimationFrame(tick);
  };

  const start = () => {
    if (state.finished) reset();
    if (!state.segments.length) return;
    unlockAudio();
    const seg = state.segments[state.index];
    if (state.remaining <= 0) state.remaining = seg.duration;
    const fresh = !state.started;
    state.running = true;
    state.started = true;
    state.anchor = Date.now();
    state.anchorLeft = state.remaining;
    state.lastBeep = null;
    requestWake();
    if (fresh) { drawStatic(); whenReady(cue[seg.phase]); }
    cancelAnimationFrame(state.raf);
    state.raf = requestAnimationFrame(tick);
    render();
  };

  const pause = () => {
    state.running = false;
    cancelAnimationFrame(state.raf);
    releaseWake();
    endAudioSession();
    render();
  };

  const toggle = () => (state.running ? pause() : start());

  /* ── Bewerken ─────────────────────────────────────────────────── */
  let editing = null, draft = 0;

  const paintEdit = () => {
    const spec = FIELDS[editing];
    el.editValue.textContent = spec.time ? fmt(draft) : String(draft);
    [...el.presets.children].forEach((b) => b.setAttribute('aria-pressed', String(Number(b.dataset.value) === draft)));
  };

  const openEdit = (field) => {
    editing = field;
    draft = config[field];
    const spec = FIELDS[field];
    el.editTitle.textContent = spec.title;
    el.editNote.textContent = spec.note || '';
    el.editNote.hidden = !spec.note;
    el.presets.replaceChildren();
    spec.presets.forEach((value) => {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'preset';
      b.dataset.value = String(value);
      b.textContent = spec.time ? fmt(value) : String(value);
      b.addEventListener('click', () => { draft = value; paintEdit(); });
      el.presets.appendChild(b);
    });
    paintEdit();
    el.editWrap.hidden = false;
  };

  const closeSheets = () => {
    el.editWrap.hidden = true;
    el.libWrap.hidden = true;
    editing = null;
  };

  const nudge = (direction) => {
    const spec = FIELDS[editing];
    draft = Math.min(spec.max, Math.max(spec.min, draft + direction * spec.step));
    paintEdit();
  };

  /* ── Bewaarde trainingen ──────────────────────────────────────── */
  const describe = (c) => `${fmt(c.work)} / ${fmt(c.rest)} · ${T.perRoundShort(c.exercises)} · ${c.rounds}× · ${fmt(totalOf(build(c)))}`;

  const saveCurrent = () => {
    const list = read('rondo.saved', []);
    const stamp = new Date();
    const entry = {
      id: String(stamp.getTime()),
      name: stamp.toLocaleDateString(LOCALE, { day: 'numeric', month: 'short' }) + ' ' +
            stamp.toLocaleTimeString(LOCALE, { hour: '2-digit', minute: '2-digit' }),
      config: { ...config }
    };
    write('rondo.saved', [entry, ...list.filter((i) => describe(i.config) !== describe(entry.config))].slice(0, 12));
    const original = el.btnSave.textContent;
    el.btnSave.textContent = T.saved;
    setTimeout(() => { el.btnSave.textContent = original; }, 1200);
  };

  const openLibrary = () => {
    const list = read('rondo.saved', []);
    el.library.replaceChildren();
    if (!list.length) {
      const p = document.createElement('p');
      p.className = 'empty';
      p.textContent = T.empty;
      el.library.appendChild(p);
    } else {
      list.forEach((item) => {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = 'saved';
        b.innerHTML = `<span><b>${item.name}</b><small>${describe(item.config)}</small></span><span>${T.load}</span>`;
        b.addEventListener('click', () => {
          config = clamp(item.config);
          write('rondo.config', config);
          renderChips();
          reset();
          closeSheets();
        });
        el.library.appendChild(b);
      });
    }
    el.libWrap.hidden = false;
  };

  /* ── Bediening ────────────────────────────────────────────────── */
  el.score.addEventListener('click', toggle);
  el.btnReset.addEventListener('click', reset);
  el.btnSave.addEventListener('click', saveCurrent);
  el.btnLibrary.addEventListener('click', openLibrary);

  el.btnSound.addEventListener('click', () => {
    soundOn = !soundOn;
    write('rondo.sound', soundOn);
    el.btnSound.setAttribute('aria-pressed', String(soundOn));
    if (soundOn) { unlockAudio(); whenReady(() => beep(880, 0.18)); } else { endAudioSession(); }
  });

  [...el.chips.children].forEach((chip) => chip.addEventListener('click', () => openEdit(chip.dataset.field)));

  el.less.addEventListener('click', () => nudge(-1));
  el.more.addEventListener('click', () => nudge(1));
  el.editOk.addEventListener('click', () => {
    if (!editing) return;
    config[editing] = draft;
    write('rondo.config', config);
    closeSheets();
    renderChips();
    reset();
  });

  document.querySelectorAll('[data-close]').forEach((node) => node.addEventListener('click', closeSheets));

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') closeSheets();
    if (event.code === 'Space' && el.editWrap.hidden && el.libWrap.hidden) {
      event.preventDefault();
      toggle();
    }
  });

  // Terug uit de achtergrond: uitrekenen waar de klok hoort te staan.
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState !== 'visible' || !state.running) return;
    if (!wakeLock) requestWake();
    holdAudioSession();
    if (audioCtx?.state === 'suspended') audioCtx.resume();
    let guard = 0;
    while (state.anchorLeft - (Date.now() - state.anchor) / 1000 <= 0 && guard++ < 10000) {
      const over = -(state.anchorLeft - (Date.now() - state.anchor) / 1000);
      if (!advance()) return;
      state.anchor = Date.now() - over * 1000;
    }
    tick();
  });

  window.addEventListener('beforeunload', () => { releaseWake(); endAudioSession(); });

  /* ── Start ────────────────────────────────────────────────────── */
  document.documentElement.lang = LANG;
  document.querySelectorAll('[data-i18n]').forEach((node) => { node.textContent = T[node.dataset.i18n]; });
  document.querySelectorAll('[data-i18n-aria]').forEach((node) => { node.setAttribute('aria-label', T[node.dataset.i18nAria]); });
  document.querySelector('meta[name="description"]')?.setAttribute('content', T.description);

  el.btnSound.setAttribute('aria-pressed', String(soundOn));
  renderChips();
  reset();

  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
  }
})();
