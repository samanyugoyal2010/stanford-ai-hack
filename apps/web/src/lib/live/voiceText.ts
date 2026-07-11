// Pure text logic for the voice loop, split out from voiceEngine so it has no
// browser deps and can be unit-tested (see voiceText.test.ts). Covers: dropping
// Whisper silence-hallucinations, spotting a mid-thought pause, cleaning text
// before TTS, and chunking the reply stream into stable-length speakable pieces.

export const MIN_TTS_CHARS = 40; // don't hand Kokoro a tiny fragment — short
                                 // snippets render with an unstable timbre.
export const FIRST_TTS_CHARS = 28; // first chunk still starts early, but stays
                                   // close to MIN so opening/later chunks share
                                   // pace/timbre. Tiny openings (~16) caused
                                   // noticeable rate flips across chunks.

// Whisper hallucinates these on silence/ambient noise — never treat as a turn.
// Kept tight: only true silence artifacts. Real short answers ("okay", "yeah",
// "so", "bye", "no") must register as turns, so they are NOT here.
const HALLUCINATIONS = new Set(["", "you", "thank you", "thank you.", "thanks for watching", "thank you for watching", "thanks for watching!", "please subscribe", "subtitles by the amara.org community"]);

export function isJunk(text: string): boolean {
  const t = text.toLowerCase().replace(/[^a-z0-9\s]/g, "").trim();
  return t.length < 2 || HALLUCINATIONS.has(t);
}

// Words that, at the very end of an utterance, usually mean "I'm not done yet".
const TRAILING = new Set(["to","the","a","an","and","but","so","or","of","for","with","my","your","is","are","it","that","this","on","at","in","because","if","when","then","like","about","into","um","uh"]);
export function endsMidThought(text: string): boolean {
  // Keep digits — "set it to 250" ends on "250", NOT on the filler "to" (stripping
  // numbers first made a complete sentence look unfinished and stalled the turn).
  const w = text.toLowerCase().replace(/[^a-z0-9\s]/g, "").trim().split(/\s+/);
  const last = w[w.length - 1];
  return !!last && TRAILING.has(last);
}

// Strip markdown so the voice never reads out "-", "*", "#", or "[p.18]" symbols,
// and scrub photo-narration ("the image/photo/…") into natural spoken language as
// a backstop to the prompt — with the camera on the agent should talk about
// "what I'm seeing", not "the image".
export function stripMarkdown(s: string): string {
  return s
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")   // links → text
    .replace(/`([^`]*)`/g, "$1")                // inline code
    .replace(/[*_~#>]+/g, "")                   // bold/italic/heading/quote marks
    .replace(/^\s*[-•]\s+/gm, "")               // list bullets
    .replace(/^\s*\d+\.\s+/gm, "")              // numbered lists
    .replace(/\[p\.\s*\d+\]/gi, "")             // citation tokens
    // Strip provider control-token noise (e.g. MiniMax leaks "[e[" fragments into
    // its text stream). Spoken text never has legitimate square brackets — the
    // prompt forbids symbols — so any that remain after links/citations are junk.
    .replace(/[[\]][a-z0-9~!]{0,3}[[\]]/gi, " ")
    .replace(/[[\]]/g, "")
    .replace(/\bin (?:the|this|your) (?:image|photo|picture|frame)\b/gi, "here")
    .replace(/\b(?:the|this|that|your) (?:image|photo|picture|frame)\b/gi, "this")
    .replace(/\s+/g, " ")
    .trim();
}

// Split a growing text stream into speakable chunks (keep decimals/abbrevs).
// Completed sentences shorter than MIN_TTS_CHARS are held and merged with the
// next one before emitting — so Kokoro always gets enough text to keep a single,
// consistent voice instead of re-rendering tiny fragments oddly. EXCEPTION: the
// FIRST chunk of a reply is released early on a clause boundary so speech begins
// as text streams, without mid-sentence word chops that flip rate/timbre.
export class SentenceChunker {
  private buf = "";      // text after the last completed sentence
  private ready = "";    // completed sentences not yet long enough to speak
  private started = false; // has the first speakable chunk of THIS turn gone out?
  push(t: string): string[] {
    this.buf += t;
    const out: string[] = [];
    // Fast start — only when nothing is already held (`ready` empty) so we never
    // speak the opening ahead of an earlier short sentence waiting to merge.
    if (!this.started && !this.ready) {
      const first = this.takeFirst();
      if (first) { out.push(first); this.started = true; }
    }
    const re = /[^.!?]+[.!?]+(?:\s|$)/g;
    let m: RegExpExecArray | null, last = 0;
    while ((m = re.exec(this.buf))) {
      this.ready += m[0];
      last = re.lastIndex;
      // First chunk clears the low bar so even a short single sentence speaks
      // now; every chunk after keeps the stable MIN_TTS_CHARS timbre bar.
      const bar = this.started ? MIN_TTS_CHARS : FIRST_TTS_CHARS;
      if (this.ready.trim().length >= bar) { out.push(this.ready.trim()); this.ready = ""; this.started = true; }
    }
    if (last) this.buf = this.buf.slice(last);
    return out;
  }
  // Release the opening of a reply only on a natural clause boundary (comma,
  // semicolon, em/en dash). Take text from the start through the first such
  // boundary that already clears FIRST_TTS_CHARS — never a mid-sentence word chop.
  private takeFirst(): string | null {
    const s = this.buf;
    if (s.trim().length < FIRST_TTS_CHARS) return null;
    const re = /[,;:—–]\s/g;
    let m: RegExpExecArray | null;
    while ((m = re.exec(s))) {
      const end = m.index + 1; // include the punctuation, exclude trailing space
      const clause = s.slice(0, end).trim();
      if (clause.length >= FIRST_TTS_CHARS) {
        this.buf = s.slice(m.index + m[0].length);
        return clause;
      }
    }
    return null; // wait for a full sentence via the sentence loop
  }
  // flush() ends the turn (called on `done` and on barge-in) — reset `started`
  // so the next reply gets its own fast first chunk.
  flush(): string { const s = (this.ready + this.buf).trim(); this.ready = ""; this.buf = ""; this.started = false; return s; }
}
