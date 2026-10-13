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
created: 2026-10-12T14:33:30.261Z
---
# Tag filter matches whole tags, the Model says fragments

## What happens

Il filtro per tag mostra le note che hanno esattamente quel tag tra i loro tag. Filtrando per «lav» non compaiono le note con «lavoro».

## What should happen

Il Requirement dice che una nota corrisponde a un tag quando il suo testo contiene «#tag» come sottostringa: così filtrare per «lav» troverebbe anche le note con «lavoro». Il Model non dice quale delle due regole vale, e la sottostringa farebbe comparire tag diversi da quello scelto. Serve decidere.

## Fix options

### Corrispondenza per tag intero (consigliata)

Una nota compare sotto un tag solo se quel tag è tra i suoi tag, cioè come parola intera. Il comportamento attuale resta invariato. Il developer aggiorna il Requirement per dire «tag intero». Costo: nessun cambio di codice; il filtro non trova tag più lunghi di quello scelto.

### Sottostringa, come scritto nel Requirement

Filtrando per «#lav» compaiono anche le note con «#lavoro» o «#lavori». Il codice va cambiato per cercare nel testo di ogni nota, non solo nei tag salvati. Costo: più note nei risultati, e la correzione già fatta sui tag più lunghi va annullata.
