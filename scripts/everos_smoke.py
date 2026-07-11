#!/usr/bin/env python3
"""Optional EverOS Cloud smoke test (not used by the macOS app).

Usage:
  pip install everos-cloud
  export EVEROS_API_KEY=...
  python scripts/everos_smoke.py
"""

from __future__ import annotations

import os
import sys
import time

try:
    from everos_cloud import EverOS
except ImportError:
    print("Install the SDK first: pip install everos-cloud", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not os.environ.get("EVEROS_API_KEY"):
        print("Set EVEROS_API_KEY first.", file=sys.stderr)
        sys.exit(1)

    client = EverOS()
    memories = client.v1.memories
    user_id = "studyflow_smoke_user"
    session_id = f"smoke_{int(time.time())}"
    now_ms = int(time.time() * 1000)

    print("Adding sample learner message…")
    memories.add(
        user_id=user_id,
        session_id=session_id,
        messages=[
            {
                "role": "user",
                "timestamp": now_ms,
                "content": (
                    "I learn best with Socratic questions. I struggle with word problems "
                    "and prefer short hints over full solutions."
                ),
            }
        ],
    )

    print("Flushing…")
    memories.flush(user_id=user_id, session_id=session_id)

    print("Fetching profile…")
    time.sleep(2)
    profile = memories.get(filters={"user_id": user_id}, memory_type="profile")
    print(profile)


if __name__ == "__main__":
    main()
