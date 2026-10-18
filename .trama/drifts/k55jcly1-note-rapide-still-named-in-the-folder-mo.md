---
status: resolved
resolution: proposal
refs:
  - folder
proposal: null
task: null
origin: null
previous: qp881u2b
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T18:28:11.782Z
---
# Note rapide still named in the folder Model

## What happens

Il Model della cartella dice ancora che "Note rapide" è una vista del navigatore delle note. Il codice non ha nessuna voce, nessuno stato e nessun conteggio per questa vista, come già segnalato dalla Drift qp881u2b; la Task 3mi1fnx3, risolta, chiedeva di togliere la vista dal Model, ma il nome è ancora nella descrizione della cartella.

## What should happen

La descrizione della cartella non deve più nominare "Note rapide": la vista non esiste nel codice e la Task 3mi1fnx3 ne prevedeva la rimozione dal Model. Il comportamento dell'app non cambia.

## Fix options

### Togliere la vista dal Model

Si toglie "Note rapide" dalla descrizione della cartella, come prevedeva la Task 3mi1fnx3, con una Proposal sul Model della cartella. Il codice resta com'è: nessuna voce, nessuno stato e nessun conteggio. È la strada più semplice e coerente con ciò che l'app mostra oggi.

### Reintrodurre la vista nel codice

Si implementa davvero la vista "Note rapide" nel codice: una voce nella barra laterale e nella schermata Cartelle, la selezione, il conteggio e la regola di ripiego della nota nuova. È una scelta di prodotto, perché cambia ciò che l'utente vede nel navigatore delle note.

## Where in the code

lib/core/models/folder_model.dart; lib/core/state/notes_provider.dart; lib/ui/sidebar/sidebar_view.dart; lib/ui/mobile/mobile_folders_screen.dart (nessuna vista Note rapide)
