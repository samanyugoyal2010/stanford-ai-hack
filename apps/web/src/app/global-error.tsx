"use client";

// Catches render errors anywhere in the tree so a crash shows a recovery screen
// instead of a blank window. global-error replaces the root layout, so it ships
// its own <html>/<body>.
export default function GlobalError({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <html>
      <body style={{ margin: 0, background: "#0b0b0c", color: "#e5e5e5", fontFamily: "system-ui, sans-serif",
        display: "grid", placeItems: "center", height: "100vh" }}>
        <div style={{ textAlign: "center", maxWidth: 420, padding: 24 }}>
          <h2 style={{ fontWeight: 600, marginBottom: 8 }}>Something went wrong</h2>
          <p style={{ color: "#a1a1aa", fontSize: 14, marginBottom: 20 }}>
            OpenLive hit an unexpected error. You can reload without losing your saved settings or chats.
          </p>
          <button onClick={() => reset()} style={{ background: "#6366f1", color: "#fff", border: 0,
            borderRadius: 10, padding: "10px 18px", fontSize: 14, cursor: "pointer" }}>
            Reload
          </button>
          {error?.message && <pre style={{ marginTop: 20, fontSize: 11, color: "#71717a",
            whiteSpace: "pre-wrap", wordBreak: "break-word" }}>{error.message}</pre>}
        </div>
      </body>
    </html>
  );
}
