// Camera / screen → JPEG frames, Gemini-Live style. While a visual source is on
// we sample it at ~1fps into a small rolling buffer, so the "current view" is
// ALWAYS a real, recent frame. Each turn attaches the latest buffered frame; the
// `look` tool grabs a fresh HIGHER-res frame on demand. Works for the webcam
// (getUserMedia) or a shared screen/window (getDisplayMedia).
export class CameraCapture {
  private stream?: MediaStream;
  private video: HTMLVideoElement;
  private canvas: HTMLCanvasElement;
  private buffer: ArrayBuffer[] = []; // rolling ~1fps frames, newest last
  private timer: ReturnType<typeof setInterval> | null = null;
  private sampleSize = 640; // camera default; screen bumps this so text stays legible
  private sampleQuality = 0.55;
  private static BUFFER = 6; // keep ~6s of recent frames

  constructor() {
    this.video = document.createElement("video");
    this.video.muted = true;
    this.video.playsInline = true;
    this.canvas = document.createElement("canvas");
  }

  async start(deviceId?: string, facingMode: "user" | "environment" = "environment") {
    const video: MediaTrackConstraints = { width: { ideal: 1280 }, height: { ideal: 720 } };
    if (deviceId) video.deviceId = { exact: deviceId };
    else video.facingMode = facingMode; // phones: default to the rear camera
    this.sampleSize = 640;
    this.sampleQuality = 0.55;
    this.stream = await navigator.mediaDevices.getUserMedia({ video });
    this.video.srcObject = this.stream;
    await this.video.play();
    this.startSampling();
  }

  /** Share a screen / window / tab. `onEnded` fires if the user stops sharing
   *  from the OS/browser chrome (the "Stop sharing" bar). */
  async startScreen(onEnded?: () => void) {
    this.sampleSize = 900; // denser text for VL without full hi-res every tick
    this.sampleQuality = 0.65;
    this.stream = await navigator.mediaDevices.getDisplayMedia({ video: { frameRate: { ideal: 3 } }, audio: false });
    this.video.srcObject = this.stream;
    await this.video.play();
    this.stream.getVideoTracks()[0]?.addEventListener("ended", () => onEnded?.());
    this.startSampling();
  }

  private startSampling() {
    if (this.timer) return;
    this.timer = setInterval(() => { void this.sample(); }, 1000);
    void this.sample(); // seed one immediately
  }
  private async sample() {
    const buf = await this.grab(this.sampleSize, this.sampleQuality);
    if (!buf) return;
    this.buffer.push(buf);
    if (this.buffer.length > CameraCapture.BUFFER) this.buffer.shift();
  }

  /** The latest sampled frame (attached to each turn). */
  async captureFreshest(): Promise<ArrayBuffer | null> {
    return this.buffer[this.buffer.length - 1] ?? this.grab(this.sampleSize, this.sampleQuality);
  }
  recent(n = 2): ArrayBuffer[] {
    return this.buffer.slice(-Math.max(1, n));
  }
  /** A fresh, higher-res grab for the `look` tool (read small labels/text). */
  async captureHiRes(size = 1600, q = 0.92): Promise<ArrayBuffer | null> {
    // Screen/camera tracks can briefly report 0×0 right after share — retry once.
    let buf = await this.grab(size, q);
    if (!buf) {
      await new Promise((r) => setTimeout(r, 120));
      buf = await this.grab(size, q);
    }
    return buf;
  }

  private async grab(size: number, q: number): Promise<ArrayBuffer | null> {
    const v = this.video;
    if (!v.videoWidth || !v.videoHeight) return null;
    // Cap the long edge but never upscale past native (blurry garbage for VL).
    const long = Math.max(v.videoWidth, v.videoHeight);
    const scale = Math.min(1, size / long);
    const w = Math.max(1, Math.round(v.videoWidth * scale));
    const h = Math.max(1, Math.round(v.videoHeight * scale));
    this.canvas.width = w;
    this.canvas.height = h;
    const ctx = this.canvas.getContext("2d");
    if (!ctx) return null;
    ctx.drawImage(v, 0, 0, w, h);
    return new Promise((res) => this.canvas.toBlob((b) => (b ? b.arrayBuffer().then(res) : res(null)), "image/jpeg", q));
  }

  getStream() { return this.stream; }
  stop() {
    if (this.timer) { clearInterval(this.timer); this.timer = null; }
    this.buffer = [];
    this.stream?.getTracks().forEach((t) => t.stop());
    this.stream = undefined;
    this.video.srcObject = null;
  }
}
