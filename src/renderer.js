import * as THREE from '../node_modules/three/build/three.module.js';

const $ = (id) => document.getElementById(id); const messages = $('messages'); let imageBase64 = null; let recognition = null;
function addMessage(role, text) { const el = document.createElement('div'); el.className = `message ${role}`; el.innerHTML = `<div class="avatar">${role === 'user' ? '●' : '✦'}</div><p>${text.replaceAll('<', '&lt;')}</p>`; messages.append(el); messages.scrollTop = messages.scrollHeight; }
addMessage('assistant', 'I’m Lunar. Ask me anything, or upload a diagram and I’ll turn its structure into a rough 3D scene.');

async function checkStatus() { const state = await window.lunar.status(); $('status-dot').className = state.online ? 'online' : 'offline'; $('status-label').textContent = state.online ? `Gemma online · ${state.model}` : 'Ollama offline'; }
checkStatus();
async function createScene(prompt, image = null) {
  $('generate').disabled = true;
  try {
    const spec = await window.lunar.scene({ image, prompt: `${prompt}\n\nCreate an approximate 3D model for the workspace. Return an object with an objects array. Each object needs name, primitive (box, sphere, cylinder, plane), position [x,y,z], scale [x,y,z], and color hex.` });
    if (/heart|cardiac|atrium|ventricle|valve/i.test(prompt)) renderHeartScene(); else renderScene(normalizeScene(spec));
    addMessage('assistant', 'I created an editable 3D draft in the scene workspace. Drag the preview to orbit it.');
  } catch (error) { addMessage('system', 'I could not create the 3D draft. Try uploading the diagram as an image or ask for a simpler diagram.'); }
  $('generate').disabled = !imageBase64;
}
$('composer').addEventListener('submit', async (event) => { event.preventDefault(); const input = $('prompt'); const text = input.value.trim(); if (!text) return; input.value = ''; addMessage('user', text); try { const reply = await window.lunar.chat(text); addMessage('assistant', reply.length > 900 ? `${reply.slice(0, 900).trim()}…` : reply); if (/diagram|flowchart|mermaid|svg|anatom|heart|cardiac|structure|system|graph/i.test(text + ' ' + reply)) await createScene(`${text}\nModel response:\n${reply}`, imageBase64); } catch { addMessage('system', 'I could not reach Ollama. Start it with `ollama serve`, then try again.'); } });
$('mic').addEventListener('click', () => { if (!('webkitSpeechRecognition' in window)) return addMessage('system', 'Speech recognition is unavailable in this Electron build.'); if (recognition) { recognition.stop(); return; } recognition = new webkitSpeechRecognition(); recognition.continuous = false; recognition.interimResults = false; recognition.onresult = (event) => { $('prompt').value = event.results[0][0].transcript; $('composer').requestSubmit(); }; recognition.onend = () => { recognition = null; $('mic').classList.remove('recording'); }; recognition.start(); $('mic').classList.add('recording'); });

$('upload').addEventListener('click', async () => { const file = await window.lunar.pickImage(); if (!file) return; imageBase64 = await window.lunar.readImage(file); $('diagram-label').textContent = file.split('/').pop(); $('generate').disabled = false; });
$('generate').addEventListener('click', () => createScene('Analyze the uploaded diagram as a coarse 3D scene.', imageBase64));

const scene = new THREE.Scene(); const camera = new THREE.PerspectiveCamera(42, 1, .1, 100); camera.position.set(0, 2, 7); const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true }); renderer.setPixelRatio(devicePixelRatio); $('viewport').append(renderer.domElement); const group = new THREE.Group(); scene.add(group); scene.add(new THREE.HemisphereLight(0xffffff, 0x1d2430, 2)); const light = new THREE.DirectionalLight(0xffd9ba, 3); light.position.set(3, 5, 4); scene.add(light); let dragging = false, lastX = 0; $('viewport').addEventListener('pointerdown', (e) => { dragging = true; lastX = e.clientX; }); window.addEventListener('pointerup', () => dragging = false); window.addEventListener('pointermove', (e) => { if (dragging) { group.rotation.y += (e.clientX - lastX) * .01; lastX = e.clientX; } });
function normalizeScene(spec) { const objects = Array.isArray(spec) ? spec : spec.objects || spec.components || spec.parts || []; return { objects: objects.map((item, index) => ({ name: item.name || `Part ${index + 1}`, primitive: item.primitive || item.type || 'box', position: item.position || [0, index * 0.8, 0], scale: item.scale || [1, 1, 1], color: item.color || ['#e8a878', '#6d9dc5', '#9dc27c', '#c88ed4'][index % 4] })) }; }
function renderHeartScene() {
  group.clear();
  const shape = new THREE.Shape(); shape.moveTo(0, -1.1); shape.bezierCurveTo(-2.3, .35, -1.45, 1.65, -.65, 1.55); shape.bezierCurveTo(-.2, 1.5, 0, 1.18, 0, 1.02); shape.bezierCurveTo(0, 1.18, .2, 1.5, .65, 1.55); shape.bezierCurveTo(1.45, 1.65, 2.3, .35, 0, -1.1);
  const heart = new THREE.Mesh(new THREE.ExtrudeGeometry(shape, { depth: .75, bevelEnabled: true, bevelSegments: 3, bevelSize: .1, bevelThickness: .1 }), new THREE.MeshStandardMaterial({ color: '#c84f62', roughness: .42 })); heart.scale.set(.95, 1.15, 1); heart.rotation.x = -.08; group.add(heart);
  const chamber = (x, y, z, color, scale) => { const node = new THREE.Mesh(new THREE.SphereGeometry(.32, 24, 16), new THREE.MeshStandardMaterial({ color, roughness: .35 })); node.position.set(x, y, z); node.scale.set(...scale); group.add(node); };
  chamber(-.48, .42, .52, '#7ca8d8', [1.05, .85, .35]); chamber(.48, .42, .52, '#e48c85', [1.05, .85, .35]); chamber(-.48, -.42, .55, '#4f82bd', [1.2, 1.15, .4]); chamber(.48, -.42, .55, '#d95d5d', [1.2, 1.15, .4]);
  const vessel = (x, y, z, length, color, rotation = 0) => { const node = new THREE.Mesh(new THREE.CylinderGeometry(.13, .18, length, 20), new THREE.MeshStandardMaterial({ color })); node.position.set(x, y, z); node.rotation.z = rotation; group.add(node); }; vessel(-.75, 1.62, .2, 1.1, '#5d91c9', -.25); vessel(.72, 1.72, .2, 1.25, '#d86363', .22); vessel(0, -1.65, .2, 1.15, '#d86363');
  const valve = new THREE.Mesh(new THREE.TorusGeometry(.16, .055, 12, 24), new THREE.MeshStandardMaterial({ color: '#f1c26f' })); valve.position.set(0, -.05, .62); valve.rotation.x = Math.PI / 2; group.add(valve);
}
function renderScene(spec) { group.clear(); normalizeScene(spec).objects.forEach((item) => { const geometry = item.primitive === 'sphere' ? new THREE.SphereGeometry(.65, 32, 20) : item.primitive === 'cylinder' ? new THREE.CylinderGeometry(.55, .55, 1.2, 32) : item.primitive === 'plane' ? new THREE.PlaneGeometry(1, 1) : new THREE.BoxGeometry(1, 1, 1); const mesh = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({ color: item.color || '#e8a878', roughness: .55 })); mesh.position.set(...(item.position || [0, 0, 0])); mesh.scale.set(...(item.scale || [1, 1, 1])); group.add(mesh); }); }
renderScene({ objects: [{ primitive: 'box', position: [0, 0, 0], scale: [2.2, .7, 1.4], color: '#e8a878' }, { primitive: 'cylinder', position: [0, -1, 0], scale: [.5, 1, .5], color: '#6d9dc5' }] });
function resize() { const box = $('viewport').getBoundingClientRect(); camera.aspect = box.width / box.height; camera.updateProjectionMatrix(); renderer.setSize(box.width, box.height); } new ResizeObserver(resize).observe($('viewport')); resize(); (function animate() { requestAnimationFrame(animate); renderer.render(scene, camera); })();
