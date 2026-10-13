---
column: done
technical: false
refs:
  - requirements/rules#note-content-save
  - note-content-save/Waiting
drift: null
proposal: null
agent: false
created: 2026-10-12T16:49:39.158Z
finished: 2026-10-12T17:11:20.877Z
---
# Fix code to match the Requirements: Content save overwrites changes made while its write runs

## What happens

Il salvataggio legge la versione memorizzata della nota, scrive il file del vault e poi riscrive la nota con i campi del contenuto. Se fissaggio, protezione, cartella o cestino cambiano mentre il file viene scritto, la riscrittura riporta la versione letta prima e quel cambiamento si perde. Inoltre, se l'editor consegna una nuova modifica durante la scrittura, l'elenco torna alla versione appena scritta finché la modifica più recente non viene salvata.

## What should happen

La scrittura riporta sulla nota memorizzata nel momento in cui viene scritta solo contenuto, titolo, tag, anteprima e data di modifica; fissaggio, protezione, cartella e cestino cambiati durante la scrittura restano. L'elenco mostra sempre la versione più recente consegnata dall'editor, anche mentre una scrittura è in corso.
