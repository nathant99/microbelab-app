# Handoff from Hub — networked room-code MP (MicrobeLab Duel Online) — web → iOS backport

Direction: **hub → app**. The MicrobeLab `/play` web clone shipped **networked room-code multiplayer** in its
ADR-048 expansion pass 2. Per `R-CLONE-BIDIRECTIONAL-BACKPORT`, it is offered back to iOS; 🟡 open until shipped.

## What the web pioneered — "MicrobeLab Duel Online"
A same-questions quiz duel over a short room code (host mints → peer joins → highest first-try score wins),
on the shared V261 Cloudflare Durable-Objects + WebSocket transport. **Safety-by-design (non-waivable):** no
free-text chat / no voice (pre-set emotes) · ephemeral generated names (no PII) · code-gated ephemeral rooms
(no accounts/persistence/discovery). Same-device pass-and-play ("MicrobeLab Duel") is the offline sibling.

## Proposed iOS surface
ForgeKit owns the server room model (`RoomRegistry`/`RoomManager`/`BroadcastService`/`ForgeServerMultiplayer`).
Wire a MicrobeLab room-code quiz over the concept kits, mirroring the web duel. Counsel gate CLEARED (ADR-041).

## Reference impl (web)
`spark-anvil-site/src/lib/play/microbelab/{versus,roomVersus,adventure}.ts` + `_shared/roomMode.ts` (V261 client).

## Not covered
Hub does NOT write Swift — the app session implements + files `HANDOFF_FROM_APP_*_SHIPPED.md`. No new
transport / account / PII (COPPA + safety-by-design).

Cross-refs: `spark-anvil-hub/Docs/web/microbelab/PARITY_WEB_VS_IOS.md` · ADR-048 · ADR-041 · `R-WEB-CLONE-MULTIPLAYER`.
