---
status: resolved
resolution: proposal
refs:
  - note-browser/Browsing
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: r3ka8qvl
created: 2026-10-18T20:16:28.015Z
---
# Tag list refresh: lock and unlock are not in the Model

## What happens

Quando una nota viene protetta, o quando si sblocca o si riblocca una nota protetta, l'elenco dei tag e i loro conteggi si aggiornano subito. Il Model non elenca questi momenti tra quelli che aggiornano l'elenco dei tag.

## What should happen

Il Model dice che l'elenco dei tag si aggiorna solo all'avvio, alla creazione, duplicazione o salvataggio di una nota, quando una nota va nel cestino, ne viene ripristinata o spostata, al termine di una sincronizzazione e ai cambiamenti ricevuti dal cloud. Blocco e sblocco non sono elencati, ma senza aggiornamento i tag di una nota protetta restano visibili o nascosti fuori tempo.

## Fix options

### Aggiungere blocco e sblocco al Model (consigliata)

Il Model elenca anche blocco, sblocco e riblocco tra gli eventi che aggiornano l'elenco dei tag. Il comportamento del codice resta com'è e la regola sui tag delle note protette nascoste resta valida. Costo: una modifica al Model, nessun cambio di codice.

### Aggiornare i tag solo ai momenti elencati

Il codice smette di aggiornare l'elenco dei tag quando una nota viene protetta o sbloccata. I tag di una nota protetta restano nell'elenco o ne scompaiono solo al momento successivo previsto dal Model. Costo: i tag mostrati non corrispondono allo stato di protezione finché non c'è un nuovo aggiornamento.

## Where in the code

lib/core/state/notes_provider.dart toggleLock e _onSecurityChanged
