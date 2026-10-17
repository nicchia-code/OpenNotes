---
status: resolved
resolution: proposal
refs:
  - requirements/tech#General
proposal: null
task: null
origin: l4oyu94h
critical: false
option: null
note: null
resolvedBy: tqf85in9
created: 2026-10-17T17:11:11.879Z
---
# Full-bleed icon cannot be 1024 px

## What happens

Il file OpenNotes.png ha un riquadro arrotondato largo circa 1024 px e alto circa 995 px, con margini trasparenti e ombra intorno. Il quadrato pieno più grande che sta dentro il riquadro, senza angoli, misura circa 876 px: non esiste un quadrato di 1024 px ricavabile dall'interno.

## What should happen

Il requisito chiede l'icona a tutta superficie come quadrato 1024×1024 ritagliato dall'interno del riquadro, senza angoli, bordo, ombra né trasparenza. Con questo sorgente il quadrato non entra nel riquadro, quindi il requisito non si può seguire così com'è.

## Where in the code

OpenNotes.png alla radice del repository (sorgente dell'icona); i file di icona da generare in android/, ios/, macos/, windows/, web/ e linux/.
