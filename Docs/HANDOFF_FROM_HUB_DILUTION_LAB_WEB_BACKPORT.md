---
kind: HANDOFF
status: OPEN
date: 2026-08-04
title: "Web-pioneered → iOS backport — Dilution Lab (serial dilution → CFU/mL)"
---

# Dilution Lab — web-pioneered forward-port → iOS backport

**Direction: hub → microbelab app session.** The `/play/microbelab` web clone shipped a NEW surface
the iOS app lacks — **Dilution Lab** (serial dilution → back-calculate CFU/mL). Site PR
nathant99/spark-anvil-site#1665. Recorded for the `R-CLONE-BIDIRECTIONAL-BACKPORT` ledger; iOS build
is the app session's Swift work (hub never writes Swift).

## What shipped on web (spec to mirror)
Pure engine `src/lib/play/microbelab/dilution.ts`:
- `originalCFU(colonies, platedMl, dilutionExp)` = colonies ÷ (platedMl × 10^dilutionExp) — the
  back-calculation from a plated, diluted tube to the original concentration.
- `isCountable(colonies)` = 30–300 (the trustworthy plate-count range).
- Engine-verified challenge bank: every plate in the countable range; three deterministic misconception
  distractors (forgot the plated VOLUME · forgot the DILUTION factor · off-by-one power), each distinct
  and ≠ the true answer; reveal shows the worked-back calculation + the countable-range note.

## iOS build notes
- Port the pure `originalCFU`/`isCountable`/`distractors`/`answer` value functions + the bank verbatim
  as a Swift model + test (ForgeMath / the app's science engine home).
- Surface as the CRA Applications rung above the growth-curve surface (predict-count → back-calculate).
- Honest-yield: standard plate-count lab skill; teaches the calculation + misconceptions, not an outcome claim.

## DoD
Engine-verified bank test green + reachable from a nav destination. File a SHIPPED handoff back when it lands.
