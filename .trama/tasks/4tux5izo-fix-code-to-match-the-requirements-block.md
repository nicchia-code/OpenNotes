---
column: done
technical: false
refs:
  - requirements/rules#note-content-save
  - note-content-save/Waiting
drift: null
proposal: null
agent: false
created: 2026-10-12T16:49:38.844Z
finished: 2026-10-12T17:09:31.949Z
---
# Fix code to match the Requirements: Block whose only text is a hash gives an empty title

## What happens

In un documento a blocchi, il primo blocco con testo fatto solo di «#» dà alla nota un titolo vuoto, invece di passare al blocco successivo o di usare «Nuova nota». Un testo semplice con la stessa riga salta quella riga e usa la successiva: i due casi si comportano in modo diverso.

## What should happen

Il titolo non è mai vuoto. Un blocco che, senza i «#» iniziali, non ha più testo non dà il titolo, come già avviene per le righe di testo semplice; se non resta alcun titolo vale «Nuova nota».
