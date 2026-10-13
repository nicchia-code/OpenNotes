---
status: resolved
resolution: fix-code
refs:
  - note/Not yet created/user.DUPLICATE_NOTE
  - note-browser/Browsing
  - requirements/rules#note-browser
proposal: null
task: nq6ewm51
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:26:21.688Z
---
# Duplicate clears the search text, the Model says only creation does

## What happens

Duplicando una nota, il testo di ricerca viene svuotato, così la copia compare nell'elenco. La copia diventa la nota selezionata anche quando la ricerca in corso la nasconderebbe.

## What should happen

Il Model della vista elenco dice che il testo di ricerca resta attivo in ogni cambio di vista e che solo la creazione di una nota lo svuota. La duplicazione, nel Model della nota, non lo svuota e rende la copia la nota selezionata.

## Fix options

### Clear the search on duplicate too

La duplicazione svuota la ricerca come la creazione, così la copia è sempre visibile e selezionata. Va aggiornata la regola dell'elenco e il Requirement, che oggi dicono che solo la creazione svuota la ricerca. Costo: dopo ogni duplicazione l'utente perde il filtro di ricerca che stava usando.

### Keep the search and select the copy even when hidden

La ricerca resta attiva e la copia viene selezionata anche se non compare nell'elenco, come dice il Model. Costo: l'editor mostra una nota che non è nell'elenco; su mobile la schermata si chiude subito perché la nota è fuori dalla vista, sul desktop la copia resta invisibile finché l'utente non cambia la ricerca.

### Keep the search and leave the copy unselected

La ricerca resta attiva e la copia non viene selezionata: l'utente la ritrova cancellando la ricerca. Va cambiata la parte del Model che dice che la copia diventa la nota selezionata. Costo: nessuna apertura automatica della copia, e una nota creata può restare nascosta dietro la ricerca.

## Where in the code

lib/core/state/notes_provider.dart (duplicateNote, con l'azzeramento della ricerca)
