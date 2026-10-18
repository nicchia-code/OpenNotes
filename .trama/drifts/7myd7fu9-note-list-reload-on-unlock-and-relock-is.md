---
status: resolved
resolution: proposal
refs:
  - note-browser/Browsing
  - requirements/rules#note-browser
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: r3ka8qvl
created: 2026-10-18T20:22:44.502Z
---
# Note list reload on unlock and relock is not in the Model

## What happens

Quando una nota protetta viene sbloccata o riportata nascosta nella sessione, l'elenco delle note viene ricaricato con i conteggi e il risultato della ricerca cambia: una nota il cui contenuto corrisponde alla ricerca compare dopo lo sblocco. L'evento che ricarica l'elenco non è tra quelli elencati dal Model. Il Model non dice se lo sblocco o il riblocco emettono LIST_RELOADED, quindi chi lo ascolta (la selezione della nota) non sa reagire.

## What should happen

Il Model dice che l'elenco viene ricaricato a ogni cambio di vista, di tag o di ricerca, dopo ogni modifica di una nota o di una cartella, al termine di una sincronizzazione e a ogni cambiamento ricevuto dal cloud. Il Requirement dice che, dopo lo sblocco, il contenuto di una nota protetta conta di nuovo nella ricerca: senza un ricaricamento il risultato non cambia. Sblocco e riblocco non sono elencati.

## Fix options

### Aggiungere sblocco e riblocco al Model (consigliata)

Il Model elenca sblocco e riblocco tra i momenti che ricaricano l'elenco e emettono LIST_RELOADED. Il comportamento del codice resta com'è e la ricerca tiene conto dello sblocco come dice il Requirement. Costo: una modifica al Model, nessun cambio di codice.

### Ricaricare l'elenco solo nei momenti elencati

Il codice smette di ricaricare l'elenco quando una nota viene sbloccata o riportata nascosta. Dopo lo sblocco il risultato della ricerca non include la nota finché non c'è un altro ricaricamento, contro il Requirement sul contenuto dopo lo sblocco. Costo: ricerca non aggiornata allo stato di protezione fino al prossimo cambio.

## Where in the code

lib/core/state/notes_provider.dart _onSecurityChanged; lib/core/services/security_service.dart unlockNote, relockNote
