---
status: resolved
resolution: proposal
refs:
  - note-content-save
proposal: null
task: null
origin: null
previous: vpim0xgg
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T17:35:07.821Z
---
# Waiting save of another note is written at once, the Model says it is replaced

## What happens

Quando un'altra nota viene modificata mentre una versione è ancora in attesa, la versione in attesa dell'altra nota viene scritta subito, senza attesa, e la nuova versione attende il tempo normale. Nessuna modifica viene scartata.

## What should happen

La versione in attesa viene sostituita anche quando apparteneva a un'altra nota: quella nota non viene più scritta (Model, stato Waiting, transizione CONTENT_CHANGED → Waiting). Il Requirement parla di un solo timer condiviso da tutte le note e descrive la perdita solo quando una scrittura fallisce.

## Fix options

### Update the Model: the other note's waiting version is written at once

Il codice scrive la versione dell'altra nota subito, come deciso per la Task ojsj17eo e per la Drift vpim0xgg, che hanno già tolto la perdita. Il Model va aggiornato: la versione dell'altra nota viene scritta subito, non scartata. Il Requirement resta valido.

### Make the code drop the other note's waiting version, as the Model says

Il codice scarta la versione in attesa dell'altra nota quando un'altra nota viene modificata. La modifica va persa, cosa che il Requirement descrive solo con un fallimento di scrittura: vale solo se si accetta la perdita dei dati.

### Keep one waiting version per note, each written after its own wait

Ogni nota ha la sua versione in attesa e la sua scrittura dopo la propria attesa. Cambia il timer condiviso previsto dal Requirement e il Model: richiede una decisione sulla regola.

## Where in the code

lib/core/state/notes_provider.dart: updateNoteContent (flush of the other note's version before replacing the pending one)
