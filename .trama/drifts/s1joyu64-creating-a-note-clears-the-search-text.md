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
created: 2026-10-12T14:33:30.843Z
---
# Creating a note clears the search text

## What happens

Se c'è un testo di ricerca attivo e crei una nota, il testo viene cancellato e l'elenco torna a mostrare tutte le note della vista.

## What should happen

Il Model dice che il testo di ricerca resta attivo quando si cambia vista e restringe ogni vista. Non dice che la creazione di una nota lo cancella, né cosa succede alla nota nuova se la ricerca non la contiene. Serve decidere.

## Fix options

### Cancellare la ricerca alla creazione (consigliata)

Quando crei una nota, il testo di ricerca si svuota, così la nota è visibile nell'elenco e aperta nell'editor. Il comportamento attuale resta invariato. Il developer completa il Model con questa regola. Costo: si perde la ricerca scritta prima di creare la nota.

### Tenere la ricerca e aprire comunque la nuova nota

La ricerca resta attiva. Se la nuova nota non la contiene, non compare nell'elenco ma resta aperta nell'editor. Costo: al primo ricaricamento dell'elenco la selezione passa alla prima nota visibile, quindi il Model va cambiato anche su questo punto.
