---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#export-pdf
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
proposal: null
task: devbtkoe
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:20:50.446Z
---
# Title repeated in the PDF body when it is clipped or styled

## What happens

Quando il titolo della nota viene troncato (più di 60 caratteri) o ha grassetto o corsivo, la prima riga del corpo non viene riconosciuta come titolo e compare di nuovo nel documento, come intestazione a 18 punti, con eventuali simboli di formattazione scritti come testo. Lo stesso accade per una prima riga del testo semplice che inizia con «## ».

## What should happen

Il Requirement dice di saltare la prima riga identica al titolo. Una riga troncata, formattata o con « ## » non è identica al titolo, quindi il Requirement stesso porta alla ripetizione, che il Model non prevede. Il Model non dice se il titolo va stampato una volta sola.

## Fix options

### Saltare la riga da cui nasce il titolo

Il corpo salta la riga o il blocco da cui il titolo è stato ricavato, qualunque sia la sua formattazione o lunghezza, così il titolo compare una sola volta. Costo: piccolo, il PDF deve sapere quale riga ha dato il titolo.

### Confrontare il titolo senza formattazione e senza troncamento

Il confronto ignora grassetto, corsivo, simboli di intestazione e il troncamento a 60 caratteri. Costo: piccolo, ma resta fragile per i casi non previsti.

### Stampare il titolo due volte

Nessuna modifica: il corpo mostra la prima riga come intestazione, come dice il Requirement alla lettera. Costo zero, ma il titolo lungo o formattato appare doppio.
