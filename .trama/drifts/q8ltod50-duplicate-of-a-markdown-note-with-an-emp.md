---
status: resolved
resolution: fix-code
refs:
  - note/Not yet created/user.DUPLICATE_NOTE
  - requirements/rules#note
proposal: null
task: l6pnb72k
origin: null
critical: false
option: 1
note: null
resolvedBy: tqf85in9
created: 2026-10-17T17:22:13.612Z
---
# Duplicate of a Markdown note with an empty heading loses its first text line

## What happens

Quando si duplica una nota in testo Markdown la cui prima riga è un'intestazione vuota (solo « # » seguito da spazi), il nuovo titolo sostituisce quella riga, ma viene cancellata anche la riga di testo che la segue. La copia perde così il primo rigo di testo dell'originale, senza alcun avviso; l'originale resta intatto.

## What should happen

Il Requisito di duplicazione dice che, nel testo Markdown che comincia con un'intestazione « # », la prima intestazione viene sostituita con « # » e il nuovo titolo. Deve cambiare solo la riga dell'intestazione: tutto il testo dell'originale resta nella copia.

## Fix options

### Replace only the heading line

La sostituzione riguarda solo la riga dell'intestazione: il nuovo titolo prende il suo posto e tutte le righe successive restano come sono, anche quando l'intestazione è vuota. Costo: una modifica piccola al solo ramo di duplicazione del testo Markdown, senza effetti sulle altre note.

### Leave a bare heading out of the replacement

Un'intestazione senza testo non viene sostituita: il nuovo titolo diventa la prima riga della copia, sopra l'intestazione vuota, che resta com'è, e tutto il testo dell'originale rimane. Costo: la copia contiene un'intestazione vuota sotto il titolo; il Requisito va letto come riferito alle sole intestazioni con testo.

## Where in the code

lib/core/state/notes_provider.dart, duplicateNote, ramo del testo Markdown (espressione regolare sulla prima riga)
