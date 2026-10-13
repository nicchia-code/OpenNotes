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
resolvedBy: xiy2hxml
created: 2026-10-12T14:33:30.521Z
---
# Tag list refresh: trash, restore and move are not in the Model

## What happens

Quando sposti una nota nel cestino, la ripristini, la sposti in un'altra cartella o ne duplichi una, l'elenco dei tag si aggiorna subito.

## What should happen

Il Model dice che l'elenco dei tag si aggiorna solo all'avvio, alla creazione o al salvataggio di una nota, al termine di una sincronizzazione e ai cambiamenti ricevuti dal cloud. Cestino, ripristino, spostamento e duplicazione non sono elencati. L'elenco però conta solo le note fuori dal cestino: senza aggiornamento i tag di una nota cestinata resterebbero visibili.

## Fix options

### Aggiungere le azioni al Model (consigliata)

Il Model elenca anche cestino, ripristino, spostamento e duplicazione tra gli eventi che aggiornano l'elenco dei tag. Il comportamento resta com'è. Costo: una modifica al Model, nessun cambio di codice.

### Aggiornare i tag solo ai momenti elencati

Un tag di una nota cestinata resta nell'elenco fino al prossimo salvataggio o sincronizzazione, anche se non ha più note visibili. Costo: l'elenco mostra tag senza note e i conteggi non tornano con le note fuori dal cestino finché non si aggiorna.
