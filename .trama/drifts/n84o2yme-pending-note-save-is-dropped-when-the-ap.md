---
status: resolved
resolution: fix-code
refs:
  - note-content-save/Waiting
  - requirements/rules#note-content-save
proposal: null
task: bc1wqpzp
origin: null
critical: false
option: 1
note: Quando l'app va in secondo piano o si chiude (anche chiudendo la finestra desktop) l'editor consegna subito le modifiche in attesa e la scrittura su disco parte subito.
resolvedBy: ccg944lf
created: 2026-10-12T12:03:05.289Z
---
# Pending note save is dropped when the app closes or goes to background

## What happens

Se l'app si chiude o va in background mentre una modifica aspetta la scrittura, quella modifica resta solo in memoria: non viene scritta né nel database locale né nel file Markdown, e alla riapertura la nota ha la versione precedente. Il gestore delle note annulla l'attesa quando viene chiuso e non forza la scrittura al passaggio in background, quindi le ultime modifiche degli ultimi 400 ms possono andare perse.

## What should happen

La scrittura su disco deve partire 400 ms dopo l'ultima modifica consegnata, quindi una modifica consegnata non dovrebbe restare solo in memoria. Il Model non dice nulla su cosa succede alla scrittura in attesa quando l'app si chiude o va in background: manca un caso che il codice gestisce in modo implicito e lossy.

## Fix options

### Scrivere la modifica in attesa all'uscita dall'app

Quando l'app va in background o si chiude, la scrittura in attesa parte subito, senza aspettare i 400 ms. Il Model guadagna una transizione di Waiting verso Idle legata all'uscita dall'app. Costo: un salvataggio extra in quei momenti, e su mobile il sistema può sospendere l'app prima che la scrittura finisca.

### Tenere il comportamento attuale e documentarlo

Nessuna scrittura forzata: le modifiche degli ultimi 400 ms restano in memoria e possono andare perse se l'app si chiude in quell'intervallo. Il Model viene aggiornato per dichiarare questo limite. Costo: nessun lavoro nel codice, ma il rischio di perdere le ultime modifiche resta.

## Where in the code

lib/core/state/notes_provider.dart (updateNoteContent e dispose)
