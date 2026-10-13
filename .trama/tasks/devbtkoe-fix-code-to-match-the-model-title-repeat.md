---
column: done
technical: false
refs:
  - requirements/rules#export-pdf
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
drift: 1wrjlxwa
proposal: null
agent: false
created: 2026-10-12T11:27:34.826Z
finished: 2026-10-12T11:33:31.295Z
---
# Fix code to match the Model: Title repeated in the PDF body when it is clipped or styled

## What happens

Quando il titolo della nota viene troncato (più di 60 caratteri) o ha grassetto o corsivo, la prima riga del corpo non viene riconosciuta come titolo e compare di nuovo nel documento, come intestazione a 18 punti, con eventuali simboli di formattazione scritti come testo. Lo stesso accade per una prima riga del testo semplice che inizia con «## ».

## What should happen

Il Requirement dice di saltare la prima riga identica al titolo. Una riga troncata, formattata o con « ## » non è identica al titolo, quindi il Requirement stesso porta alla ripetizione, che il Model non prevede. Il Model non dice se il titolo va stampato una volta sola.

## Chosen option

**Saltare la riga da cui nasce il titolo**

Il corpo salta la riga o il blocco da cui il titolo è stato ricavato, qualunque sia la sua formattazione o lunghezza, così il titolo compare una sola volta. Costo: piccolo, il PDF deve sapere quale riga ha dato il titolo.
