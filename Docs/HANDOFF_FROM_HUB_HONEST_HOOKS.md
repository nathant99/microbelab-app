# Implementation Handoff — Honest Hooks for microbelab (from Hub)

> **Status:** ACTIVE · **Date:** 2026-10-14 · **Program:** #231 Keep the Question (ADR-326, Y3 Honest Hooks)
> **From:** spark-anvil-hub (S3) · **To:** microbelab Claude Code session · **Hub never writes Swift.**

A fun fact is the first thing a child reads, so it must be true as stated. Hub checked all 15 of this app's fun
facts against a source, gave each a mark (✓ True · ↔ Stretched — true in spirit, the text says how · ◌ Nobody
knows), corrected 15 of them, and gave each one *next why* — a question the fact has just made possible.
The web clone shows the mark, the source and the next why (site PR #4580). The checked text is the source of truth:
spark-anvil-hub `Resources/HonestHooks/microbelab.json`.

## What to do on iOS

1. Use the corrected text below wherever the app shows these fun facts.
2. Optional, recommended: show the mark (icon + word, never the icon alone) and the next why after the fact. A
   "keep this question" action should let the child keep or change the question; nothing is sent anywhere.
3. A new fun fact goes in only after it has been checked against a source (the web guard `check-honest-hooks.mjs`
   fails an unmarked fact in this app).

## The checked facts

| id | mark | fact (as the child reads it) | checked against | next why |
|---|---|---|---|---|
| funFact-1 | True | Did you know? Antibodies are Y-shaped proteins. The tips of the Y fit one particular marker on a germ, called an antigen, a bit like a key fits one lock. Each kind of antibody is made for its own marker. | Wikipedia — Antibody | How does your body make an antibody for a germ it has never met before? |
| funFact-2 | True | Did you know? Most microbes are harmless or helpful. Trillions of them live on and inside you right now. Together they are called your microbiome, and the ones in your gut help you digest food. | Wikipedia — Human microbiome | How did all those microbes get inside you in the first place? |
| funFact-3 | True | Did you know? Antibiotics fight bacteria but do nothing against viruses. That is why they cannot cure a cold or the flu, and why taking them when you don't need them helps bacteria learn to resist them. | Wikipedia — Antibiotic | Why can't a medicine that kills bacteria kill a virus too? |
| funFact-4 | True | Did you know? A vaccine shows your immune system a harmless piece, or a weakened or killed form, of a germ. Your body practises on it and keeps memory cells, so it is ready faster if the real germ ever comes. | Wikipedia — Vaccine | How long do memory cells remember a germ? |
| funFact-5 | True | Did you know? Your immune system has two teams. Innate immunity is fast and general: skin, mucus and cells that eat invaders. Adaptive immunity is slower but aims at one germ, and it remembers it next time. | Wikipedia — Immune system | Why is the team that remembers germs so much slower the first time? |
| funFact-6 | True | Did you know? Scientists argue about whether viruses are alive. A virus cannot copy itself on its own; it has to use a living cell. Some biologists say that means it is not alive, and others say it is alive in its own way. | Wikipedia — Virus | What would you need to see to decide that something is alive? |
| funFact-7 | True | Did you know? Most people catch chickenpox only once. After the body beats the virus, memory cells stay ready, so a second attack is usually stopped fast. The virus can hide in nerves, though, and come back years later as shingles. | Wikipedia — Chickenpox | How can a virus hide in your body for years without making you ill? |
| funFact-8 | Stretched | Did you know? A teaspoon of good farm soil usually holds between 100 million and 1 billion bacteria. You have heard people say it holds more microbes than there are people on Earth (about 8 billion); the soil scientists' own count is smaller. | Ohio State University Extension — Role of Soil Bacteria | How would you count bacteria you cannot even see? |
| funFact-9 | True | Did you know? Your skin is a wall that keeps most germs out. Behind it are more guards: sticky mucus, tears that wash germs away, and strong acid in your stomach. Many invaders are stopped before immune cells are needed. | Wikipedia — Innate immune system | Why doesn't your stomach acid burn your stomach? |
| funFact-10 | True | Did you know? A fever is often the body helping itself. A slightly higher temperature can slow some germs down and help immune cells work, which is why a fever usually means your body is fighting back. | Wikipedia — Fever | How does your brain decide to turn your temperature up? |
| funFact-11 | True | Did you know? Washing your hands with soap is one of the best ways to stop germs spreading. Soap and rubbing lift germs off your skin and the water rinses them away. | Wikipedia — Hand washing | How does soap get germs off, when water alone doesn't? |
| funFact-12 | True | Did you know? Antibiotic resistance happens when bacteria change so that a drug no longer kills them. Using antibiotics when they are not needed speeds this up, so doctors try to prescribe them only when they will help. | Wikipedia — Antimicrobial resistance | If a few bacteria survive a medicine, why do they matter so much? |
| funFact-13 | True | Did you know? Your immune system has to tell your own cells from invaders. Your cells carry ID markers on their surface, and immune cells check them before they attack. | Wikipedia — Major histocompatibility complex | What happens when the immune system makes a mistake and attacks your own body? |
| funFact-14 | True | Did you know? Penicillin, one of the first antibiotics, was found in a mould in 1928. Microbes also make yoghurt, cheese and bread: yeast, a microbe, is what makes bread rise. | Wikipedia — Penicillin | How did a mould end up making a medicine? |
| funFact-15 | True | Did you know? Your immune system works all the time, even when you feel well. Feeling fine often means your defences are quietly stopping germs you never noticed. | Wikipedia — Immune system | How many germs might your body stop in a single day? |

## Verify

Every fact above matches the hub JSON; the web bank for this app is generated from it
(`scripts/port_humor_seeds_to_web.py --app microbelab`).
