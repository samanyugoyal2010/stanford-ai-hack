const deck = document.getElementById('deck');
const track = document.getElementById('track');
const progress = document.getElementById('progress');
const dots = document.getElementById('dots');

const scenes = [
  {
    className: 'hero',
    render: () => `
      <section class="scene">
        <div class="scene-inner">
          <div class="hero-grid">
            <div>
              <div class="eyebrow reveal">Nudge keynote 2026</div>
              <h1 class="reveal delay-1">Help students get unstuck, without taking over the work.</h1>
              <div class="hero-copy reveal delay-2">
                <p>Nudge is an AI learning assistant that notices struggle in real time and gives students the next useful step, not the finished answer. It stays calm, precise, and context-aware so learning keeps moving.</p>
              </div>
              <div class="hero-actions reveal delay-3">
                <a class="button primary" href="#scene-1">See the product</a>
                <a class="button secondary" href="#scene-2">How it works</a>
              </div>
            </div>
            <div class="hero-panel reveal delay-1">
              <div class="hero-panel-top">
                <div class="live-pill">Live guidance, not auto-solve</div>
                <div class="monospace">Scene 01</div>
              </div>
              <div class="visual-stage">
                <div class="orb white"></div>
                <div class="orb blue"></div>
                <div class="beam"></div>
                <div class="callout" style="left: 10%; top: 18%;">
                  <strong>Student stuck</strong>
                  <p>“I know the concept, but this problem keeps breaking my workflow.”</p>
                </div>
                <div class="callout" style="right: 9%; bottom: 18%; max-width: 240px;">
                  <strong>Nudge response</strong>
                  <p>Spot the bottleneck, ask one focused question, then offer a hint that keeps ownership with the student.</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    `
  },
  {
    render: () => `
      <section class="scene">
        <div class="scene-inner">
          <div class="deck-split">
            <div class="scene-copy">
              <div class="eyebrow reveal">Why it matters</div>
              <h2 class="reveal delay-1">The hardest moment in learning is not a lack of answers. It is the moment before the student gives up.</h2>
              <p class="reveal delay-2">Nudge watches for hesitation, repeated errors, and unproductive loops. When it sees a student stall, it intervenes with a small, well-timed prompt that reduces frustration and preserves confidence.</p>
            </div>
            <div class="stat-stack">
              <div class="stat-card reveal">
                <div class="stat-number">01</div>
                <strong>Signal of struggle</strong>
                <p>Repeated incorrect attempts, long pauses, or a sudden drop in momentum.</p>
              </div>
              <div class="stat-card reveal delay-1">
                <div class="stat-number">02</div>
                <strong>Contextual response</strong>
                <p>A hint, question, or example that matches the student’s current step.</p>
              </div>
              <div class="stat-card reveal delay-2">
                <div class="stat-number">03</div>
                <strong>Ownership preserved</strong>
                <p>The assistant never finishes the task for the learner unless that is explicitly requested.</p>
              </div>
              <div class="stat-card reveal delay-3">
                <div class="stat-number">04</div>
                <strong>Progress continues</strong>
                <p>Students stay in flow instead of stalling out or waiting for help.</p>
              </div>
            </div>
          </div>
        </div>
      </section>
    `
  },
  {
    render: () => `
      <section class="scene">
        <div class="scene-inner">
          <div class="eyebrow reveal">Core experience</div>
          <h2 class="reveal delay-1">The interface feels like a calm guide sitting beside the student.</h2>
          <div class="feature-grid" style="margin-top: 26px;">
            <article class="feature-card reveal">
              <strong>Detects friction</strong>
              <p>Built to notice when the student is circling the same mistake, pausing too long, or reaching for help too early.</p>
              <div class="signal"><span style="width: 86%"></span></div>
            </article>
            <article class="feature-card reveal delay-1">
              <strong>Guides step by step</strong>
              <p>Instead of dumping a solution, Nudge narrows attention to the next logical move.</p>
              <div class="signal"><span style="width: 68%"></span></div>
            </article>
            <article class="feature-card reveal delay-2">
              <strong>Adapts to confidence</strong>
              <p>When the student is close, it becomes lighter. When they are lost, it becomes more explicit.</p>
              <div class="signal"><span style="width: 74%"></span></div>
            </article>
            <article class="feature-card reveal delay-3">
              <strong>Stays out of the way</strong>
              <p>Every interaction is meant to feel short, useful, and easy to dismiss once the student is moving again.</p>
              <div class="signal"><span style="width: 58%"></span></div>
            </article>
          </div>
        </div>
      </section>
    `
  },
  {
    render: () => `
      <section class="scene">
        <div class="scene-inner">
          <div class="deck-split">
            <div class="quote-card reveal">
              <div class="eyebrow">Design principle</div>
              <div class="quote">Use a smaller question to unlock a larger insight.</div>
              <p>That is the product philosophy behind Nudge. The assistant is not trying to impress with volume. It is trying to say the right thing at the right time, then get out of the way.</p>
            </div>
            <div class="timeline-grid">
              <div class="timeline-card timeline-step reveal">
                <div class="monospace">Step 1</div>
                <strong>Observe</strong>
                <p>Read the learning context, detect the pattern of confusion, and estimate whether the student is stuck or simply thinking.</p>
              </div>
              <div class="timeline-card timeline-step reveal delay-1">
                <div class="monospace">Step 2</div>
                <strong>Nudge</strong>
                <p>Offer a concise hint, a targeted question, or a small reminder that unlocks the next move without over-explaining.</p>
              </div>
              <div class="timeline-card timeline-step reveal delay-2">
                <div class="monospace">Step 3</div>
                <strong>Reinforce</strong>
                <p>Confirm progress, keep the student oriented, and avoid taking away the opportunity to learn by doing.</p>
              </div>
            </div>
          </div>
        </div>
      </section>
    `
  },
  {
    render: () => `
      <section class="scene">
        <div class="scene-inner">
          <div class="eyebrow reveal">Product system</div>
          <h2 class="reveal delay-1">A clear stack that can live inside classrooms, homework, tutoring, and practice tools.</h2>
          <div class="stack-grid" style="margin-top: 26px;">
            <div class="stack-card reveal">
              <strong>Signal layer</strong>
              <p>Captures pauses, retries, patterns of uncertainty, and the difference between productive struggle and dead-end confusion.</p>
            </div>
            <div class="stack-card reveal delay-1">
              <strong>Policy layer</strong>
              <p>Chooses whether to wait, ask, hint, scaffold, or escalate based on the learner’s state and the task complexity.</p>
            </div>
            <div class="stack-card reveal delay-2">
              <strong>Interaction layer</strong>
              <p>Keeps the UI fast and legible, with short responses that feel more like a calm collaborator than an assistant window.</p>
            </div>
            <div class="stack-card reveal delay-3">
              <strong>Outcome layer</strong>
              <p>Measures whether the student kept going, corrected course, and reached understanding rather than just completion.</p>
            </div>
          </div>
        </div>
      </section>
    `
  },
  {
    render: () => `
      <section class="scene">
        <div class="scene-inner">
          <div class="deck-split">
            <div class="scene-copy">
              <div class="eyebrow reveal">Experience quality</div>
              <h2 class="reveal delay-1">Bright enough to feel premium. Quiet enough to feel trustworthy.</h2>
              <p class="reveal delay-2">The visual system uses light surfaces, crisp type, restrained motion, and carefully paced transitions. The result is less like a startup demo and more like a flagship product introduction.</p>
            </div>
            <div class="grid-card reveal">
              <strong>What changed</strong>
              <ul>
                <li>Replaced continuous scrolling with single-scene navigation.</li>
                <li>Removed the dark, blurry, hackathon-style treatment.</li>
                <li>Introduced a bright keynote layout with disciplined spacing.</li>
                <li>Added a subtle progress indicator and stable motion timing.</li>
              </ul>
            </div>
          </div>
        </div>
      </section>
    `
  },
  {
    render: () => `
      <section class="scene">
        <div class="scene-inner">
          <div class="eyebrow reveal">For students</div>
          <h2 class="reveal delay-1">Feels like support, not surveillance.</h2>
          <div class="feature-grid" style="margin-top: 26px;">
            <article class="feature-card reveal">
              <strong>Gentle timing</strong>
              <p>Nudge waits long enough to respect thinking, then appears before frustration becomes momentum loss.</p>
            </article>
            <article class="feature-card reveal delay-1">
              <strong>Short prompts</strong>
              <p>The assistant speaks in compact steps, so the student never has to parse a wall of text when they are already stuck.</p>
            </article>
            <article class="feature-card reveal delay-2">
              <strong>Confidence boost</strong>
              <p>Students get back to action faster, which lowers the cost of making mistakes.</p>
            </article>
            <article class="feature-card reveal delay-3">
              <strong>Human tone</strong>
              <p>The guidance feels respectful and encouraging rather than robotic or corrective.</p>
            </article>
          </div>
        </div>
      </section>
    `
  },
  {
    render: () => `
      <section class="scene">
        <div class="scene-inner">
          <div class="eyebrow reveal">For educators</div>
          <h2 class="reveal delay-1">Helps more students progress without turning every question into a support ticket.</h2>
          <div class="deck-split" style="margin-top: 26px;">
            <div class="grid-card reveal">
              <strong>Better visibility</strong>
              <p>Educators can see where students stall, which concepts trigger friction, and how often intervention was needed.</p>
            </div>
            <div class="grid-card reveal delay-1">
              <strong>Less interruption</strong>
              <p>The assistant can absorb routine stumbling blocks before they become live questions in the room.</p>
            </div>
          </div>
        </div>
      </section>
    `
  },
  {
    render: () => `
      <section class="scene">
        <div class="scene-inner">
          <div class="eyebrow reveal">Launch moment</div>
          <h2 class="reveal delay-1">The right AI for learning should know when to speak softly.</h2>
          <div class="deck-split" style="margin-top: 30px;">
            <div class="scene-copy reveal">
              <p>Nudge is built around restraint. It recognizes struggle, responds with precision, and keeps the student in control of the answer. That makes it useful in the real world, not just impressive in a demo.</p>
              <div class="hero-actions" style="margin-top: 28px;">
                <a class="button primary" href="#scene-11">End keynote</a>
                <a class="button secondary" href="#scene-0">Replay</a>
              </div>
            </div>
            <div class="diagram-card reveal delay-1">
              <div class="monospace">Principles</div>
              <strong style="margin-top: 10px;">Clear. Calm. Useful.</strong>
              <p>Every scene in this keynote is designed to feel sharp, bright, stable, and professional from the first frame to the last.</p>
            </div>
          </div>
        </div>
      </section>
    `
  },
  {
    render: () => `
      <section class="scene">
        <div class="scene-inner">
          <div class="hero-grid" style="align-items: end;">
            <div>
              <div class="eyebrow reveal">Nudge</div>
              <h1 class="reveal delay-1" style="font-size: clamp(3.6rem, 8vw, 8rem); max-width: 9ch;">A keynote built to feel finished.</h1>
            </div>
            <div class="quote-card reveal delay-2">
              <strong>Final note</strong>
              <p>Use arrow keys, page keys, spacebar, wheel, trackpad, or swipe to move one scene at a time.</p>
            </div>
          </div>
        </div>
      </section>
    `
  }
];

let currentScene = 0;
let isTransitioning = false;
let wheelAccum = 0;
let wheelTimer = null;
let touchStart = null;
let touchMoved = false;

function buildDeck() {
  track.innerHTML = scenes.map((scene, index) => `
    <article class="scene-wrap" id="scene-${index}" aria-label="Scene ${index + 1}">
      ${scene.render()}
    </article>
  `).join('');

  dots.innerHTML = scenes.map((_, index) => `<button type="button" aria-label="Go to scene ${index + 1}" data-index="${index}"></button>`).join('');
  dots.querySelectorAll('button').forEach((button) => {
    button.addEventListener('click', () => goToScene(Number(button.dataset.index)));
  });

  requestAnimationFrame(() => {
    updateScene(true);
  });
}

function updateScene(immediate = false) {
  track.style.transitionDuration = immediate ? '0ms' : '720ms';
  track.style.transform = `translate3d(${-currentScene * 100}vw, 0, 0)`;
  progress.textContent = `${String(currentScene + 1).padStart(2, '0')} / ${String(scenes.length).padStart(2, '0')}`;
  dots.querySelectorAll('button').forEach((button, index) => {
    button.classList.toggle('active', index === currentScene);
  });
  document.documentElement.style.scrollBehavior = 'auto';
}

function goToScene(nextScene) {
  if (isTransitioning || nextScene === currentScene) return;
  currentScene = Math.max(0, Math.min(scenes.length - 1, nextScene));
  isTransitioning = true;
  updateScene();
  window.clearTimeout(wheelTimer);
  wheelTimer = window.setTimeout(() => {
    isTransitioning = false;
  }, 760);
}

function stepScene(direction) {
  goToScene(currentScene + direction);
}

function onWheel(event) {
  event.preventDefault();
  if (isTransitioning) return;
  wheelAccum += Math.abs(event.deltaY) > Math.abs(event.deltaX) ? event.deltaY : event.deltaX;
  window.clearTimeout(wheelTimer);
  wheelTimer = window.setTimeout(() => {
    wheelAccum = 0;
  }, 120);
  const threshold = 60;
  if (Math.abs(wheelAccum) >= threshold) {
    const direction = wheelAccum > 0 ? 1 : -1;
    wheelAccum = 0;
    stepScene(direction);
  }
}

function onKeydown(event) {
  const keys = ['ArrowDown', 'PageDown', ' ', 'Spacebar'];
  const backwards = ['ArrowUp', 'PageUp'];
  if (!keys.includes(event.key) && !backwards.includes(event.key)) return;
  event.preventDefault();
  if (isTransitioning) return;
  if (keys.includes(event.key)) stepScene(1);
  else stepScene(-1);
}

function onPointerDown(event) {
  if (event.pointerType === 'mouse' && event.button !== 0) return;
  touchStart = { x: event.clientX, y: event.clientY, time: performance.now() };
  touchMoved = false;
}

function onPointerMove(event) {
  if (!touchStart) return;
  if (Math.abs(event.clientX - touchStart.x) > 8 || Math.abs(event.clientY - touchStart.y) > 8) touchMoved = true;
}

function onPointerUp(event) {
  if (!touchStart) return;
  const dx = event.clientX - touchStart.x;
  const dy = event.clientY - touchStart.y;
  const elapsed = performance.now() - touchStart.time;
  touchStart = null;
  if (isTransitioning || !touchMoved || elapsed > 900) return;
  if (Math.abs(dx) > Math.abs(dy) && Math.abs(dx) > 48) stepScene(dx < 0 ? 1 : -1);
  else if (Math.abs(dy) > 48) stepScene(dy < 0 ? 1 : -1);
}

buildDeck();

deck.addEventListener('click', (event) => {
  const link = event.target.closest('a.button[href^="#scene-"]');
  if (!link) return;
  event.preventDefault();
  const index = Number(link.getAttribute('href').replace('#scene-', ''));
  if (Number.isFinite(index)) goToScene(index);
});

window.addEventListener('wheel', onWheel, { passive: false });
window.addEventListener('keydown', onKeydown);
window.addEventListener('pointerdown', onPointerDown, { passive: true });
window.addEventListener('pointermove', onPointerMove, { passive: true });
window.addEventListener('pointerup', onPointerUp, { passive: true });
window.addEventListener('pointercancel', () => { touchStart = null; touchMoved = false; }, { passive: true });
window.addEventListener('resize', () => updateScene(true));
window.addEventListener('load', () => updateScene(true));
