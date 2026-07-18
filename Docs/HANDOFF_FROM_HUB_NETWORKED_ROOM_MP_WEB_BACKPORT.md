# HANDOFF — Hub → microbelab-app: networked room MP + pass-and-play (web-pioneered → iOS backport)

Direction: **hub → app**. The `/play/microbelab` web clone shipped **networked room-code multiplayer**
+ **same-device pass-and-play** (Microbe Duel); the iOS app is single-player, so this is a
web-pioneered learning-relevant feature owed back to iOS (R-CLONE-BIDIRECTIONAL-BACKPORT). 🟡 open.

## What the web shipped (ADR-048 Wave 2, site PR #905)
- **Pass-and-play** — 2–4 players take turns on ONE device over the same MC-kit questions; highest
  first-try score wins. Serverless, on-device (COPPA-safe). Reference: `_shared/passAndPlay.ts`.
- **Networked room MP** — host mints a short room code → peers join → alternating-turn quiz over the
  **Cloudflare Durable-Objects + WebSocket** SparkRoom transport (V261, ADR-041). Safety BY DESIGN:
  NO free-text chat / NO voice / ephemeral generated names / code-gated ephemeral rooms / no accounts /
  no PII. Reference: `_shared/roomMode.ts` + the live `/api/room/*` Worker.
- Surfaced flag-gated on a `/play/microbelab/versus` route ('Same device' / 'Online room' tabs).

## Proposed iOS surface
- **Pass-and-play** → `ForgePassAndPlay` (the 4-stage privacy-curtain hotseat, ForgeKit) over this app's
  MC kits — 2–4 seats, per-seat first-try score race, anti-shame (private per turn, round always advances).
- **Room MP** → the ForgeKit server-room model (`RoomRegistry`/`RoomManager`/`BroadcastService`/
  `ForgeServerMultiplayer`) — the iOS parity of the web SparkRoom transport. Safety-by-design invariants
  are NON-waivable (no free-text chat/voice; pre-set emotes only; ephemeral names; code-gated rooms).

## What this handoff does NOT cover
The iOS Swift/Xcode implementation — that is this app's own CC session's work. Hub filed this handoff
(the START of the obligation); the ledger 🟡 row closes when iOS ships or waives it.

Cross-refs: `.claude/rules/spark-anvil-website.md` § R-WEB-CLONE-MULTIPLAYER / § R-WEB-CLONE-SOCIAL-MODES ·
ADR-041 · ADR-048 · `.claude/rules/forgekit.md` § ForgePassAndPlay / § Server modules.
